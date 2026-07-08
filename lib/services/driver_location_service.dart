import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class DriverLocationService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'https://fm.fam-zlog.web.id/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://fm.fam-zlog.web.id/api';
    }
    return 'https://fm.fam-zlog.web.id/api';
  }

  static Map<String, String> _headers([String? token]) {
    final actualToken = token ?? AuthService.token;
    if (actualToken == null || actualToken.isEmpty) {
      throw AuthException('Belum login');
    }
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $actualToken',
    };
  }

  /// Store a location point to the backend.
  /// Returns the created location id on success.
  /// Throws [ApiException] with the backend message on error.
  static Future<Map<String, dynamic>> store({
    int? driverId,
    int? tripId,
    required double latitude,
    required double longitude,
    double? speed,
    double? accuracy,
    DateTime? capturedAt,
    String? token,
  }) async {
    final uri = Uri.parse('$_baseUrl/driver-locations');
    final body = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };

    // Use provided driverId or fallback to current logged-in user's ID
    final actualDriverId = driverId ?? AuthService.currentUser?.id;

    if (actualDriverId == null) {
      throw ApiException(
        'Driver ID tidak ditemukan. Pastikan Anda sudah login.',
      );
    }

    body['driver_id'] = actualDriverId.toString();

    if (tripId != null) {
      body['trip_id'] = tripId.toString();
      debugPrint('DriverLocationService: Sending with trip_id=$tripId');
    } else {
      debugPrint('DriverLocationService: Sending WITHOUT trip_id (backend will try to find active trip)');
    }
    
    if (speed != null) body['speed'] = speed.toString();
    if (accuracy != null) body['accuracy'] = accuracy.toString();
    if (capturedAt != null) body['captured_at'] = capturedAt.toIso8601String();

    debugPrint('--- [DriverLocationService] POST driver-locations ---');
    debugPrint('URI: $uri');
    debugPrint('Body (Speed: ${body['speed']}, Trip: ${body['trip_id'] ?? "NULL"}): $body');

    final response = await http.post(uri, headers: _headers(token), body: body);

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('---------------------------------------------------');

    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201 && response.statusCode != 200) {
      final message = data['message'] as String? ?? 'Gagal menyimpan lokasi';
      throw ApiException(message);
    }

    final locationData = data['data'] as Map<String, dynamic>;
    
    // Return both location_id and trip_id from response
    return {
      'id': locationData['id'] as int,
      'trip_id': locationData['trip_id'] as int?,
    };
  }

  /// Fetch location history from the backend.
  static Future<List<Map<String, dynamic>>> fetch({
    int? driverId,
    int? tripId,
    int limit = 100,
  }) async {
    final params = <String, String>{};
    if (driverId != null) params['driver_id'] = driverId.toString();
    if (tripId != null) params['trip_id'] = tripId.toString();
    params['limit'] = limit.toString();

    // Fix query parameter encoding
    final baseUri = Uri.parse('$_baseUrl/driver-locations');
    final uri = baseUri.replace(queryParameters: params);

    debugPrint('--- [DriverLocationService] GET driver-locations ---');
    debugPrint('URI: $uri');

    final response = await http.get(uri, headers: _headers());

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('---------------------------------------------------');

    if (response.statusCode != 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final message = data['message'] as String? ?? 'Gagal memuat lokasi';
      throw ApiException(message);
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final list = data['data'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// Fetch the latest location for a driver/trip
  static Future<Map<String, dynamic>?> fetchLatest({int? driverId}) async {
    try {
      final list = await fetch(driverId: driverId, limit: 1);
      if (list.isNotEmpty) {
        return list.first;
      }
    } catch (_) {}
    return null;
  }
}

/// Generic API exception that carries the backend error message.
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
