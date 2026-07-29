import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:famzlog_flutter/models/wwtp.dart';
import 'package:famzlog_flutter/services/auth_service.dart';

class WwtpService {
  static const String _baseUrl = 'https://famzlog.softwarenusantara.com/api';

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

  /// Get list of WWTP records with optional filters
  static Future<List<Wwtp>> getWwtps({
    String? date,
    String? pickerName,
    int? warehouseId,
    int? materialId,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (date != null) queryParams['date'] = date;
      if (pickerName != null && pickerName.isNotEmpty) queryParams['picker_name'] = pickerName;
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId.toString();
      if (materialId != null) queryParams['material_id'] = materialId.toString();

      final uri = Uri.parse('$_baseUrl/wwtps').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> recordsJson = data['data'];
          return recordsJson.map((json) => Wwtp.fromJson(json)).toList();
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception(_extractError(response, 'Gagal mengambil data WWTP'));
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get statistics for WWTP records
  static Future<WwtpStatistics> getStatistics({
    String? date,
    int? warehouseId,
    int? materialId,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (date != null) queryParams['date'] = date;
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId.toString();
      if (materialId != null) queryParams['material_id'] = materialId.toString();

      final uri = Uri.parse('$_baseUrl/wwtps/statistics').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return WwtpStatistics.fromJson(data['data']);
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception(_extractError(response, 'Gagal mengambil statistik'));
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get single WWTP record by ID
  static Future<Wwtp> getWwtp(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/wwtps/$id');
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Wwtp.fromJson(data['data']);
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception(_extractError(response, 'Gagal mengambil data WWTP'));
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Create new WWTP record
  static Future<Wwtp> createWwtp(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$_baseUrl/wwtps');
      final response = await http.post(
        uri,
        headers: _headers(),
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Wwtp.fromJson(responseData['data']);
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception(_extractError(response, 'Gagal membuat data WWTP'));
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Update existing WWTP record
  static Future<Wwtp> updateWwtp(int id, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$_baseUrl/wwtps/$id');
      final response = await http.put(
        uri,
        headers: _headers(),
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Wwtp.fromJson(responseData['data']);
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception(_extractError(response, 'Gagal mengupdate data WWTP'));
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Delete WWTP record
  static Future<void> deleteWwtp(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/wwtps/$id');
      final response = await http.delete(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception(_extractError(response, 'Gagal menghapus data WWTP'));
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
