import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:famzlog_flutter/models/empty_jerrycan.dart';
import 'package:famzlog_flutter/services/auth_service.dart';

class EmptyJerrycanService {
  static const String _baseUrl = 'http://10.51.66.152:8000/api';

  static Map<String, String> _headers() {
    final token = AuthService.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static String _extractError(http.Response response, String defaultMessage) {
    try {
      final data = json.decode(response.body);
      if (data['message'] != null) {
        return data['message'];
      }
      if (data['error'] != null) {
        return data['error'];
      }
    } catch (e) {
      // Ignore JSON parsing errors
    }
    return defaultMessage;
  }

  /// Get list of empty jerrycan records with optional filters
  static Future<List<EmptyJerrycan>> getEmptyJerrycans({
    String? tanggal,
    String? nopol,
    int? warehouseId,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (tanggal != null) queryParams['tanggal'] = tanggal;
      if (nopol != null && nopol.isNotEmpty) queryParams['nopol'] = nopol;
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId.toString();

      final uri = Uri.parse('$_baseUrl/empty-jerrycans').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> recordsJson = data['data'];
          return recordsJson.map((json) => EmptyJerrycan.fromJson(json)).toList();
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception(_extractError(response, 'Gagal mengambil data jerigen kosong'));
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get statistics for empty jerrycan records
  static Future<EmptyJerrycanStatistics> getStatistics({
    String? tanggal,
    int? warehouseId,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (tanggal != null) queryParams['tanggal'] = tanggal;
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId.toString();

      final uri = Uri.parse('$_baseUrl/empty-jerrycans/statistics').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return EmptyJerrycanStatistics.fromJson(data['data']);
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception(_extractError(response, 'Gagal mengambil statistik'));
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get single empty jerrycan record by ID
  static Future<EmptyJerrycan> getEmptyJerrycan(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/empty-jerrycans/$id');
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return EmptyJerrycan.fromJson(data['data']);
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception(_extractError(response, 'Gagal mengambil data jerigen kosong'));
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Create new empty jerrycan record
  static Future<EmptyJerrycan> createEmptyJerrycan(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$_baseUrl/empty-jerrycans');
      final response = await http.post(
        uri,
        headers: _headers(),
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return EmptyJerrycan.fromJson(responseData['data']);
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception(_extractError(response, 'Gagal membuat data jerigen kosong'));
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Update existing empty jerrycan record
  static Future<EmptyJerrycan> updateEmptyJerrycan(int id, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$_baseUrl/empty-jerrycans/$id');
      final response = await http.put(
        uri,
        headers: _headers(),
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return EmptyJerrycan.fromJson(responseData['data']);
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception(_extractError(response, 'Gagal mengupdate data jerigen kosong'));
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Delete empty jerrycan record
  static Future<void> deleteEmptyJerrycan(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/empty-jerrycans/$id');
      final response = await http.delete(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception(_extractError(response, 'Gagal menghapus data jerigen kosong'));
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
