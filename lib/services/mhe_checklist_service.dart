import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/mhe_checklist.dart';
import 'auth_service.dart';

class MheChecklistService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://192.168.1.44:8000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.1.44:8000/api';
    }
    return 'http://192.168.1.44:8000/api';
  }

  static Map<String, String> _headers() {
    final token = AuthService.token;
    if (token == null || token.isEmpty) {
      throw Exception('Belum login');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<List<EquipmentType>> getEquipmentTypes() async {
    try {
      final headers = _headers();
      final url = '$baseUrl/mhe/equipment-types';
      
      print('Fetching equipment types from: $url');
      print('Token: ${AuthService.token?.substring(0, 20)}...');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => EquipmentType.fromJson(item))
              .toList();
        }
      }
      
      if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token tidak valid atau expired');
      }
      
      if (response.statusCode == 404) {
        throw Exception('Endpoint tidak ditemukan. Pastikan API sudah di-deploy.');
      }
      
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('Error in getEquipmentTypes: $e');
      rethrow;
    }
  }

  Future<List<String>> getTasks(String equipmentType) async {
    try {
      final headers = _headers();
      final response = await http.get(
        Uri.parse('$baseUrl/mhe/$equipmentType/tasks'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['data']['tasks']);
        }
      }
      throw Exception('Failed to load tasks');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<MheChecklistData> getChecklist(
    String equipmentType,
    int month,
    int year,
  ) async {
    try {
      final headers = _headers();
      final url = '$baseUrl/mhe/$equipmentType/checklist?month=$month&year=$year';
      
      print('Fetching checklist from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Checklist response status: ${response.statusCode}');
      print('Checklist response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          try {
            return MheChecklistData.fromJson(data['data']);
          } catch (parseError) {
            print('Error parsing checklist data: $parseError');
            print('Data structure: ${data['data']}');
            throw Exception('Gagal parsing data: $parseError');
          }
        }
      }
      
      if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau expired');
      }
      
      if (response.statusCode == 404) {
        throw Exception('Endpoint tidak ditemukan');
      }
      
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('Error in getChecklist: $e');
      rethrow;
    }
  }

  Future<bool> saveChecklist(MheChecklistData checklistData) async {
    try {
      final headers = _headers();
      final response = await http.post(
        Uri.parse('$baseUrl/mhe/checklist/save'),
        headers: headers,
        body: json.encode(checklistData.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getSummary(int month, int year) async {
    try {
      final headers = _headers();
      final response = await http.get(
        Uri.parse('$baseUrl/mhe/summary?month=$month&year=$year'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      throw Exception('Failed to load summary');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
