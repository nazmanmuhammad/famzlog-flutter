import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// AUTO DROP OFF CONFIGURATION
// Edit nilai di bawah ini untuk mengubah perilaku otomatisasi.
// Rebuild app setelah perubahan.
// ============================================================

/// Aktifkan/nonaktifkan fitur auto drop off secara default.
/// true  = aktif saat install pertama kali
/// false = driver harus aktifkan manual dari settings
const bool kAutoDropOffDefaultEnabled = false;

/// Radius dari toko (meter) — sama dengan drop_off_page.dart (500m)
const double kAutoDropOffStoreRadius = 500.0;

/// Durasi driver harus berada di radius sebelum auto Process (OK) & Start (menit)
/// Contoh: 5 = driver harus diam 5 menit di radius toko sebelum auto start
const int kAutoDropOffWaitMinutes = 5;

/// Durasi setelah Start sebelum auto Finish (menit)
/// Contoh: 10 = setelah start, 10 menit kemudian otomatis finish
const int kAutoDropOffUnloadMinutes = 10;

// ============================================================

/// Keys untuk SharedPreferences (override dari settings UI)
const String _kAutoEnabled = 'auto_dropoff_enabled';
const String _kAutoMinutes = 'auto_dropoff_minutes';
const String _kAutoUnloadMinutes = 'auto_dropoff_unload_minutes';

const String _baseUrl = 'https://famzlog.familymartindonesia.com/api';

/// State tracking per store
/// Key: storeId, Value: DateTime pertama kali masuk radius
final Map<int, DateTime> _storeEntryTimes = {};

/// Auto DropOff Service — dijalankan dari background service timer
class AutoDropOffService {
  /// Simpan config ke SharedPreferences
  static Future<void> saveConfig({
    required bool enabled,
    required int waitMinutes,
    required int unloadMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoEnabled, enabled);
    await prefs.setInt(_kAutoMinutes, waitMinutes);
    await prefs.setInt(_kAutoUnloadMinutes, unloadMinutes);
    debugPrint('AutoDropOff: Config saved enabled=$enabled wait=${waitMinutes}m unload=${unloadMinutes}m');
  }

  /// Baca config dari SharedPreferences (fallback ke konstanta default)
  static Future<({bool enabled, int waitMinutes, int unloadMinutes})> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      enabled: prefs.getBool(_kAutoEnabled) ?? kAutoDropOffDefaultEnabled,
      waitMinutes: prefs.getInt(_kAutoMinutes) ?? kAutoDropOffWaitMinutes,
      unloadMinutes: prefs.getInt(_kAutoUnloadMinutes) ?? kAutoDropOffUnloadMinutes,
    );
  }

  /// Entry point — dipanggil dari periodic timer background service
  static Future<void> tick(Position currentPosition) async {
    try {
      final config = await loadConfig();
      if (!config.enabled) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      // Ambil active trip
      final activeRecord = await _getActiveRecord(token);
      if (activeRecord == null) return;

      final int recordId = activeRecord['id'] as int;
      final List<dynamic> stores = activeRecord['stores'] as List<dynamic>? ?? [];

      for (final storeRaw in stores) {
        final store = storeRaw as Map<String, dynamic>;
        final int storeId = store['id'] as int;
        final String status = store['status'] as String? ?? '';
        final String? overloadTime = store['overload_time'] as String?;

        // Skip jika sudah selesai atau overload
        if (status == 'finished' || overloadTime != null) {
          _storeEntryTimes.remove(storeId);
          continue;
        }

        final double? storeLat = store['latitude'] != null
            ? double.tryParse(store['latitude'].toString())
            : null;
        final double? storeLng = store['longitude'] != null
            ? double.tryParse(store['longitude'].toString())
            : null;

        // Jika store tidak punya koordinat, skip radius check
        if (storeLat == null || storeLng == null) continue;

        final double distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          storeLat,
          storeLng,
        );

        final bool inRadius = distance <= kAutoDropOffStoreRadius;

        if (!inRadius) {
          // Keluar radius — reset timer
          _storeEntryTimes.remove(storeId);
          continue;
        }

        // Di dalam radius
        final now = DateTime.now();

        if (status == 'not_visited' || status == 'pending') {
          // Tahap 1: Auto process (OK)
          _storeEntryTimes[storeId] ??= now;
          final elapsed = now.difference(_storeEntryTimes[storeId]!);

          if (elapsed.inMinutes >= config.waitMinutes) {
            debugPrint('AutoDropOff: ⚡ Auto Process store $storeId after ${elapsed.inMinutes}m');
            final ok = await _apiCall(token, 'POST',
                '$_baseUrl/driver-dc-records/$recordId/stores/$storeId/process');
            if (ok) {
              _storeEntryTimes.remove(storeId);
              debugPrint('AutoDropOff: ✅ Process success store $storeId');
            }
          }
        } else if (status == 'process') {
          // Tahap 2: Auto start (unloading)
          _storeEntryTimes[storeId] ??= now;
          final elapsed = now.difference(_storeEntryTimes[storeId]!);

          if (elapsed.inMinutes >= config.waitMinutes) {
            debugPrint('AutoDropOff: ⚡ Auto Start store $storeId after ${elapsed.inMinutes}m');
            final ok = await _apiCall(token, 'POST',
                '$_baseUrl/driver-dc-records/$recordId/stores/$storeId/start');
            if (ok) {
              _storeEntryTimes.remove(storeId);
              debugPrint('AutoDropOff: ✅ Start success store $storeId');
            }
          }
        } else if (status == 'unloading') {
          // Tahap 3: Auto finish
          _storeEntryTimes[storeId] ??= now;
          final elapsed = now.difference(_storeEntryTimes[storeId]!);

          if (elapsed.inMinutes >= config.unloadMinutes) {
            debugPrint('AutoDropOff: ⚡ Auto Finish store $storeId after ${elapsed.inMinutes}m');
            final ok = await _apiCall(token, 'POST',
                '$_baseUrl/driver-dc-records/$recordId/stores/$storeId/finish');
            if (ok) {
              _storeEntryTimes.remove(storeId);
              debugPrint('AutoDropOff: ✅ Finish success store $storeId');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('AutoDropOff: Error in tick: $e');
    }
  }

  /// Ambil active record beserta stores-nya dari API
  static Future<Map<String, dynamic>?> _getActiveRecord(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/driver-dc-records/active'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final body = json.decode(response.body) as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('AutoDropOff: Failed to get active record: $e');
      return null;
    }
  }

  /// Generic API call helper
  static Future<bool> _apiCall(String token, String method, String url) async {
    try {
      final uri = Uri.parse(url);
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      http.Response response;
      if (method == 'POST') {
        response = await http.post(uri, headers: headers)
            .timeout(const Duration(seconds: 10));
      } else {
        response = await http.get(uri, headers: headers)
            .timeout(const Duration(seconds: 10));
      }

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('AutoDropOff: API call failed $url - $e');
      return false;
    }
  }
}
