import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'driver_location_service.dart';

/// Offline queue for GPS locations
/// Stores failed/pending locations locally and syncs when network is available
class OfflineLocationQueue {
  static Database? _database;
  static Timer? _syncTimer;
  static bool _isSyncing = false;

  static const String _tableName = 'location_queue';
  static const int _maxRetries = 3;
  static const int _syncIntervalSeconds = 30;

  /// Initialize database
  static Future<Database> get database async {
    if (_database != null) return _database!;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'location_queue.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            driver_id INTEGER NOT NULL,
            trip_id INTEGER,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            speed REAL,
            accuracy REAL,
            captured_at TEXT NOT NULL,
            created_at TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0,
            last_error TEXT
          )
        ''');

        // Index for faster queries
        await db.execute(
          'CREATE INDEX idx_created_at ON $_tableName(created_at)',
        );
      },
    );

    return _database!;
  }

  /// Add location to offline queue
  static Future<void> enqueue({
    required int driverId,
    int? tripId,
    required double latitude,
    required double longitude,
    double? speed,
    double? accuracy,
    required DateTime capturedAt,
  }) async {
    try {
      final db = await database;
      
      await db.insert(_tableName, {
        'driver_id': driverId,
        'trip_id': tripId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'accuracy': accuracy,
        'captured_at': capturedAt.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });

      debugPrint('OfflineQueue: Enqueued location at ${capturedAt.toIso8601String()}');
    } catch (e) {
      debugPrint('OfflineQueue: Failed to enqueue: $e');
    }
  }

  /// Start automatic sync timer
  static void startAutoSync() {
    _syncTimer?.cancel();
    
    _syncTimer = Timer.periodic(
      Duration(seconds: _syncIntervalSeconds),
      (_) => syncPendingLocations(),
    );

    debugPrint('OfflineQueue: Auto-sync started');
  }

  /// Stop automatic sync timer
  static void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('OfflineQueue: Auto-sync stopped');
  }

  /// Sync all pending locations to server
  static Future<void> syncPendingLocations() async {
    if (_isSyncing) {
      debugPrint('OfflineQueue: Sync already in progress, skipping');
      return;
    }

    _isSyncing = true;

    try {
      // Check network connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        debugPrint('OfflineQueue: No network, skipping sync');
        return;
      }

      final db = await database;
      
      // Get pending locations (oldest first, limit 50 per batch)
      final pending = await db.query(
        _tableName,
        where: 'retry_count < ?',
        whereArgs: [_maxRetries],
        orderBy: 'created_at ASC',
        limit: 50,
      );

      if (pending.isEmpty) {
        return;
      }

      debugPrint('OfflineQueue: Syncing ${pending.length} pending locations');

      int successCount = 0;
      int failCount = 0;

      for (final item in pending) {
        try {
          // Send to server
          await DriverLocationService.store(
            driverId: item['driver_id'] as int,
            tripId: item['trip_id'] as int?,
            latitude: item['latitude'] as double,
            longitude: item['longitude'] as double,
            speed: item['speed'] as double?,
            accuracy: item['accuracy'] as double?,
            capturedAt: DateTime.parse(item['captured_at'] as String),
          );

          // Delete from queue on success
          await db.delete(
            _tableName,
            where: 'id = ?',
            whereArgs: [item['id']],
          );

          successCount++;
          debugPrint('OfflineQueue: Synced location ${item['id']}');
        } catch (e, stackTrace) {
          // Increment retry count on failure
          await db.update(
            _tableName,
            {
              'retry_count': (item['retry_count'] as int) + 1,
              'last_error': e.toString(),
            },
            where: 'id = ?',
            whereArgs: [item['id']],
          );

          failCount++;
          debugPrint('OfflineQueue: ❌ Failed to sync location ${item['id']}');
          debugPrint('  Error: $e');
          debugPrint('  Stack: ${stackTrace.toString().split('\n').take(2).join('\n')}');
          debugPrint('  Retry count: ${(item['retry_count'] as int) + 1}/$_maxRetries');
        }

        // Small delay between requests to avoid overwhelming server
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('OfflineQueue: Sync complete - Success: $successCount, Failed: $failCount');

      // Clean up old failed items (> max retries and > 7 days old)
      await _cleanupOldFailedItems();
    } catch (e) {
      debugPrint('OfflineQueue: Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Clean up old failed items to prevent database bloat
  static Future<void> _cleanupOldFailedItems() async {
    try {
      final db = await database;
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

      final deleted = await db.delete(
        _tableName,
        where: 'retry_count >= ? AND created_at < ?',
        whereArgs: [_maxRetries, cutoffDate.toIso8601String()],
      );

      if (deleted > 0) {
        debugPrint('OfflineQueue: Cleaned up $deleted old failed items');
      }
    } catch (e) {
      debugPrint('OfflineQueue: Cleanup error: $e');
    }
  }

  /// Get queue statistics
  static Future<Map<String, int>> getStats() async {
    try {
      final db = await database;
      
      final total = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_tableName'),
      ) ?? 0;

      final pending = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $_tableName WHERE retry_count < ?',
          [_maxRetries],
        ),
      ) ?? 0;

      final failed = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $_tableName WHERE retry_count >= ?',
          [_maxRetries],
        ),
      ) ?? 0;

      return {
        'total': total,
        'pending': pending,
        'failed': failed,
      };
    } catch (e) {
      debugPrint('OfflineQueue: Stats error: $e');
      return {'total': 0, 'pending': 0, 'failed': 0};
    }
  }

  /// Clear all queue items (use with caution)
  static Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      debugPrint('OfflineQueue: All items cleared');
    } catch (e) {
      debugPrint('OfflineQueue: Clear error: $e');
    }
  }

  /// Close database
  static Future<void> close() async {
    await _database?.close();
    _database = null;
    stopAutoSync();
  }
}
