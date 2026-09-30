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

/// Aktifkan/nonaktifkan penggunaan settingan custom dari slider.
/// true  = pakai nilai dari SharedPreferences (slider di UI)
/// false = pakai hardcode constants di bawah ini (DEFAULT)
const bool kAutoDropOffUseCustomSettings = false;

/// Radius dari toko (meter) — sama dengan drop_off_page.dart (500m)
const double kAutoDropOffStoreRadius = 500.0;

/// Durasi driver harus berada di radius sebelum auto Process (OK) & Start (menit)
const int kAutoDropOffWaitMinutes = 5;

/// Durasi setelah Start sebelum auto Finish (menit)
const int kAutoDropOffUnloadMinutes = 10;

// ============================================================

/// Keys untuk SharedPreferences
const String _kUseCustomSettings = 'auto_dropoff_use_custom';
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
    required bool useCustomSettings,
    required int waitMinutes,
    required int unloadMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseCustomSettings, useCustomSettings);
    await prefs.setInt(_kAutoMinutes, waitMinutes);
    await prefs.setInt(_kAutoUnloadMinutes, unloadMinutes);
    debugPrint('AutoDropOff: Config saved useCustom=$useCustomSettings wait=${waitMinutes}m unload=${unloadMinutes}m');
  }

  /// Baca config dari SharedPreferences
  /// Jika useCustomSettings=false → pakai hardcode constants
  /// Jika useCustomSettings=true  → pakai nilai dari SharedPreferences
  static Future<({bool useCustomSettings, int waitMinutes, int unloadMinutes})> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final useCustom = prefs.getBool(_kUseCustomSettings) ?? kAutoDropOffUseCustomSettings;
    return (
      useCustomSettings: useCustom,
      waitMinutes: useCustom
          ? (prefs.getInt(_kAutoMinutes) ?? kAutoDropOffWaitMinutes)
          : kAutoDropOffWaitMinutes,
      unloadMinutes: useCustom
          ? (prefs.getInt(_kAutoUnloadMinutes) ?? kAutoDropOffUnloadMinutes)
          : kAutoDropOffUnloadMinutes,
    );
  }

  /// Entry point — dipanggil dari periodic timer background service
  /// Auto drop off SELALU aktif. useCustomSettings menentukan sumber nilai waktu.
  static Future<void> tick(Position currentPosition) async {
    try {
      final config = await loadConfig();
      // Auto drop off selalu berjalan — tidak ada kondisi mati

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      // Ambil active trip — fetch list dulu, cari yang scan_out_time null
      final activeRecord = await _getActiveRecord(token);
      if (activeRecord == null) return;

      final int recordId = activeRecord['id'] as int;

      // Fetch detail untuk dapat stores dengan koordinat
      final detail = await _getDropOffDetail(token, recordId);
      if (detail == null) return;

      final List<dynamic> stores = detail['stores'] as List<dynamic>? ?? [];

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

          debugPrint('AutoDropOff: Store $storeId in radius ${distance.toStringAsFixed(0)}m, elapsed ${elapsed.inSeconds}s / ${config.waitMinutes * 60}s');

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

          debugPrint('AutoDropOff: Store $storeId (process) in radius, elapsed ${elapsed.inSeconds}s / ${config.waitMinutes * 60}s');

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
          // Tahap 3: Auto finish — timer mulai dari kapan pun unloading dimulai
          _storeEntryTimes[storeId] ??= now;
          final elapsed = now.difference(_storeEntryTimes[storeId]!);

          debugPrint('AutoDropOff: Store $storeId (unloading), elapsed ${elapsed.inSeconds}s / ${config.unloadMinutes * 60}s');

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

  /// Ambil active record — fetch semua records, cari yang scan_out_time null
  static Future<Map<String, dynamic>?> _getActiveRecord(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/driver-dc-records'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final body = json.decode(response.body) as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>? ?? [];

      // Cari record yang belum scan out
      for (final item in list) {
        final record = item as Map<String, dynamic>;
        if (record['scan_out_time'] == null) {
          return record;
        }
      }
      return null;
    } catch (e) {
      debugPrint('AutoDropOff: Failed to get active record: $e');
      return null;
    }
  }

  /// Ambil detail drop off (stores + koordinat) dari endpoint detail
  static Future<Map<String, dynamic>?> _getDropOffDetail(String token, int recordId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/driver-dc-records/$recordId/detail'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final body = json.decode(response.body) as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('AutoDropOff: Failed to get drop off detail: $e');
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
