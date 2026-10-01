import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ── Default constants (hardcode fallback) ─────────────────────────────────────
const bool   kAutoDropOffUseCustomSettings  = false;
const double kAutoDropOffStoreRadius        = 500.0;
const double kAutoDropOffWarehouseRadius    = 500.0;
const int    kAutoDropOffWaitMinutes        = 5;   // radius store → auto process/start
const int    kAutoDropOffFinishDelayMinutes = 10;  // keluar radius → auto finish store
const int    kAutoWarehouseScanOutMinutes   = 3;   // keluar radius DC → auto scan out WH
const int    kAutoWarehouseScanInMinutes    = 3;   // masuk radius DC (all done) → auto scan finish trip

// ── SharedPreferences keys ────────────────────────────────────────────────────
const String _kUseCustom   = 'auto_dropoff_use_custom';
const String _kWaitMin     = 'auto_dropoff_minutes';
const String _kFinishMin   = 'auto_dropoff_unload_minutes';
const String _kWhOutMin    = 'auto_dropoff_wh_out_minutes';
const String _kWhInMin     = 'auto_dropoff_wh_in_minutes';
const String _kEntryKey    = 'auto_dropoff_entry_times';
const String _kExitKey     = 'auto_dropoff_exit_times';

const String _baseUrl = 'https://famzlog.familymartindonesia.com/api';

// ── Config record type ────────────────────────────────────────────────────────
typedef AutoConfig = ({
  bool useCustomSettings,
  int waitMinutes,
  int unloadMinutes,
  int warehouseOutMinutes,
  int warehouseInMinutes,
});

class AutoDropOffService {

  // ── Save / Load config ──────────────────────────────────────────────────────

  static Future<void> saveConfig({
    required bool useCustomSettings,
    required int waitMinutes,
    required int unloadMinutes,
    required int warehouseOutMinutes,
    required int warehouseInMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseCustom, useCustomSettings);
    await prefs.setInt(_kWaitMin,   waitMinutes);
    await prefs.setInt(_kFinishMin, unloadMinutes);
    await prefs.setInt(_kWhOutMin,  warehouseOutMinutes);
    await prefs.setInt(_kWhInMin,   warehouseInMinutes);
    debugPrint('AutoDropOff: saved custom=$useCustomSettings '
        'wait=${waitMinutes}m finish=${unloadMinutes}m '
        'whOut=${warehouseOutMinutes}m whIn=${warehouseInMinutes}m');
  }

  static Future<AutoConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getBool(_kUseCustom) ?? kAutoDropOffUseCustomSettings;
    return (
      useCustomSettings:  custom,
      waitMinutes:        custom ? (prefs.getInt(_kWaitMin)    ?? kAutoDropOffWaitMinutes)        : kAutoDropOffWaitMinutes,
      unloadMinutes:      custom ? (prefs.getInt(_kFinishMin)  ?? kAutoDropOffFinishDelayMinutes) : kAutoDropOffFinishDelayMinutes,
      warehouseOutMinutes:custom ? (prefs.getInt(_kWhOutMin)   ?? kAutoWarehouseScanOutMinutes)   : kAutoWarehouseScanOutMinutes,
      warehouseInMinutes: custom ? (prefs.getInt(_kWhInMin)    ?? kAutoWarehouseScanInMinutes)    : kAutoWarehouseScanInMinutes,
    );
  }

  // ── Persisted timers ────────────────────────────────────────────────────────

  static Future<Map<String, String>> _loadTimes(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return {};
    try { return Map<String, String>.from(json.decode(raw) as Map); }
    catch (_) { return {}; }
  }

  static Future<void> _saveTimes(String key, Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(map));
  }

  // ── Main tick ───────────────────────────────────────────────────────────────

  static Future<void> tick(Position pos) async {
    try {
      final config = await loadConfig();
      final prefs  = await SharedPreferences.getInstance();
      final token  = prefs.getString('auth_token');
      if (token == null) return;

      final whLat = prefs.getDouble('selected_warehouse_latitude');
      final whLng = prefs.getDouble('selected_warehouse_longitude');

      await _checkWarehouse(token, pos, whLat, whLng, config);
      await _checkStores(token, pos, config);
    } catch (e) {
      debugPrint('AutoDropOff tick error: $e');
    }
  }

  // ── Warehouse scan out / scan finish trip ───────────────────────────────────

  static Future<void> _checkWarehouse(
    String token, Position pos,
    double? whLat, double? whLng,
    AutoConfig config,
  ) async {
    if (whLat == null || whLng == null) return;

    final activeRecord = await _getActiveRecord(token);
    if (activeRecord == null) return;

    final int    recordId     = activeRecord['id'] as int;
    final bool   hasScanOut   = activeRecord['scan_out_time'] != null;
    final bool   hasWhOut     = activeRecord['warehouse_scan_out_time'] != null;
    final List   stores       = (activeRecord['stores'] as List?) ?? [];
    final bool   allDone      = stores.isNotEmpty &&
        stores.every((s) {
          final st = (s as Map<String, dynamic>)['status'] as String? ?? '';
          final ov = s['overload_time'];
          return st == 'finished' || ov != null;
        });

    final double distWH = Geolocator.distanceBetween(
      pos.latitude, pos.longitude, whLat, whLng,
    );
    final bool inWH = distWH <= kAutoDropOffWarehouseRadius;

    debugPrint('AutoDropOff WH: dist=${distWH.toStringAsFixed(0)}m '
        'inWH=$inWH hasWhOut=$hasWhOut allDone=$allDone hasScanOut=$hasScanOut');

    // ── 1. Auto Scan OUT Warehouse (driver keluar DC setelah scan in) ──────
    if (!hasWhOut && !inWH) {
      final exitTimes = await _loadTimes('auto_wh_exit_times');
      final key = recordId.toString();
      if (!exitTimes.containsKey(key)) {
        exitTimes[key] = DateTime.now().toIso8601String();
        await _saveTimes('auto_wh_exit_times', exitTimes);
        debugPrint('AutoDropOff WH: exit timer started record=$recordId');
      } else {
        final elapsed = DateTime.now().difference(DateTime.parse(exitTimes[key]!));
        debugPrint('AutoDropOff WH: exit elapsed ${elapsed.inSeconds}s / ${config.warehouseOutMinutes * 60}s');
        if (elapsed.inMinutes >= config.warehouseOutMinutes) {
          final ok = await _apiCall(token, '$_baseUrl/driver-dc-records/$recordId/scan-out-warehouse');
          if (ok) {
            exitTimes.remove(key);
            await _saveTimes('auto_wh_exit_times', exitTimes);
            debugPrint('AutoDropOff WH: ✅ Auto Scan OUT Warehouse record=$recordId');
          }
        }
      }
    } else if (inWH) {
      // Reset exit timer jika kembali ke dalam radius
      final exitTimes = await _loadTimes('auto_wh_exit_times');
      if (exitTimes.containsKey(recordId.toString())) {
        exitTimes.remove(recordId.toString());
        await _saveTimes('auto_wh_exit_times', exitTimes);
      }
    }

    // ── 2. Auto Scan Finish Trip (semua selesai + driver kembali ke DC) ────
    if (hasWhOut && allDone && !hasScanOut && inWH) {
      final entryTimes = await _loadTimes('auto_wh_entry_times');
      final key = recordId.toString();
      if (!entryTimes.containsKey(key)) {
        entryTimes[key] = DateTime.now().toIso8601String();
        await _saveTimes('auto_wh_entry_times', entryTimes);
        debugPrint('AutoDropOff WH: scan-finish timer started record=$recordId');
      } else {
        final elapsed = DateTime.now().difference(DateTime.parse(entryTimes[key]!));
        debugPrint('AutoDropOff WH: scan-finish elapsed ${elapsed.inSeconds}s / ${config.warehouseInMinutes * 60}s');
        if (elapsed.inMinutes >= config.warehouseInMinutes) {
          final ok = await _apiCall(token, '$_baseUrl/driver-dc-records/$recordId/scan-out');
          if (ok) {
            entryTimes.remove(key);
            await _saveTimes('auto_wh_entry_times', entryTimes);
            debugPrint('AutoDropOff WH: ✅ Auto Scan Finish Trip record=$recordId');
          }
        }
      }
    } else if (!inWH || !allDone) {
      // Reset scan-finish timer jika keluar radius atau belum semua done
      final entryTimes = await _loadTimes('auto_wh_entry_times');
      if (entryTimes.containsKey(recordId.toString())) {
        entryTimes.remove(recordId.toString());
        await _saveTimes('auto_wh_entry_times', entryTimes);
      }
    }
  }

  // ── Store auto process / start / finish ────────────────────────────────────

  static Future<void> _checkStores(
    String token, Position pos, AutoConfig config,
  ) async {
    final activeRecord = await _getActiveRecord(token);
    if (activeRecord == null) return;

    final int recordId = activeRecord['id'] as int;
    if (activeRecord['warehouse_scan_out_time'] == null) return;

    final detail = await _getDropOffDetail(token, recordId);
    if (detail == null) return;

    final List<dynamic> stores = detail['stores'] as List<dynamic>? ?? [];
    final entryTimes = await _loadTimes(_kEntryKey);
    final exitTimes  = await _loadTimes(_kExitKey);
    bool changed = false;

    for (final storeRaw in stores) {
      final store   = storeRaw as Map<String, dynamic>;
      final int sid = store['id'] as int;
      final String status = store['status'] as String? ?? '';
      final String key    = sid.toString();

      if (status == 'finished' || store['overload_time'] != null) {
        entryTimes.remove(key); exitTimes.remove(key); changed = true;
        continue;
      }

      final double? sLat = store['latitude']  != null ? double.tryParse(store['latitude'].toString())  : null;
      final double? sLng = store['longitude'] != null ? double.tryParse(store['longitude'].toString()) : null;
      if (sLat == null || sLng == null) continue;

      final double dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, sLat, sLng);
      final bool inR    = dist <= kAutoDropOffStoreRadius;

      debugPrint('AutoDropOff Store $sid: dist=${dist.toStringAsFixed(0)}m inR=$inR status=$status');

      if (inR) {
        // Clear exit timer
        if (exitTimes.containsKey(key)) { exitTimes.remove(key); changed = true; }

        final now = DateTime.now();

        if (status == 'not_visited' || status == 'pending') {
          entryTimes[key] ??= now.toIso8601String(); changed = true;
          final elapsed = now.difference(DateTime.parse(entryTimes[key]!));
          debugPrint('AutoDropOff: Store $sid entry elapsed ${elapsed.inSeconds}s/${config.waitMinutes * 60}s');
          if (elapsed.inMinutes >= config.waitMinutes) {
            final ok = await _apiCall(token, '$_baseUrl/driver-dc-records/$recordId/stores/$sid/process');
            if (ok) { entryTimes.remove(key); changed = true; debugPrint('AutoDropOff: ✅ Auto Process $sid'); }
          }
        } else if (status == 'process') {
          entryTimes[key] ??= now.toIso8601String(); changed = true;
          final elapsed = now.difference(DateTime.parse(entryTimes[key]!));
          debugPrint('AutoDropOff: Store $sid (process) elapsed ${elapsed.inSeconds}s/${config.waitMinutes * 60}s');
          if (elapsed.inMinutes >= config.waitMinutes) {
            final ok = await _apiCall(token, '$_baseUrl/driver-dc-records/$recordId/stores/$sid/start');
            if (ok) { entryTimes.remove(key); changed = true; debugPrint('AutoDropOff: ✅ Auto Start $sid'); }
          }
        }

      } else {
        entryTimes.remove(key); changed = true;

        if (status == 'unloading') {
          exitTimes[key] ??= DateTime.now().toIso8601String(); changed = true;
          final elapsed = DateTime.now().difference(DateTime.parse(exitTimes[key]!));
          debugPrint('AutoDropOff: Store $sid exit elapsed ${elapsed.inSeconds}s/${config.unloadMinutes * 60}s');
          if (elapsed.inMinutes >= config.unloadMinutes) {
            final ok = await _apiCall(token, '$_baseUrl/driver-dc-records/$recordId/stores/$sid/finish');
            if (ok) { exitTimes.remove(key); changed = true; debugPrint('AutoDropOff: ✅ Auto Finish $sid'); }
          }
        } else {
          exitTimes.remove(key); changed = true;
        }
      }
    }

    if (changed) {
      await _saveTimes(_kEntryKey, entryTimes);
      await _saveTimes(_kExitKey,  exitTimes);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> _getActiveRecord(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/driver-dc-records'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body) as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>? ?? [];
      for (final item in list) {
        final r = item as Map<String, dynamic>;
        if (r['scan_out_time'] == null) return r;
      }
      return null;
    } catch (e) {
      debugPrint('AutoDropOff: getActiveRecord error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _getDropOffDetail(String token, int id) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/driver-dc-records/$id/detail'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body) as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('AutoDropOff: getDropOffDetail error: $e');
      return null;
    }
  }

  static Future<bool> _apiCall(String token, String url) async {
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('AutoDropOff: apiCall error $url: $e');
      return false;
    }
  }
}
