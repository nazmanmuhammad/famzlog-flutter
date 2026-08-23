import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/mhe_checklist.dart';
import 'auth_service.dart';

class MheChecklistService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://10.97.120.57:9000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.97.120.57:9000/api';
    }
    return 'http://10.97.120.57:9000/api';
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

  Future<List<MheChecklistTable>> getChecklists(
    String equipmentType,
    int month,
    int year,
    {int? warehouseId}
  ) async {
    try {
      final headers = _headers();
      var url = '$baseUrl/mhe/$equipmentType/checklists?month=$month&year=$year';

      if (warehouseId != null) {
        url += '&warehouse_id=$warehouseId';
      }

      print('Fetching checklists from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Checklists response status: ${response.statusCode}');
      print('Checklists response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          try {
            final checklistsData = data['data']['checklists'] as List;
            return checklistsData
                .map((item) => MheChecklistTable.fromJson(item))
                .toList();
          } catch (parseError) {
            print('Error parsing checklists data: $parseError');
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
      print('Error in getChecklists: $e');
      rethrow;
    }
  }

  Future<MheChecklistTable> createChecklist({
    required String equipmentType,
    required String equipmentName,
    required int month,
    required int year,
    required int warehouseId,
  }) async {
    try {
      final headers = _headers();
      final response = await http.post(
        Uri.parse('$baseUrl/mhe/checklists'),
        headers: headers,
        body: json.encode({
          'equipment_type': equipmentType,
          'equipment_name': equipmentName,
          'month': month,
          'year': year,
          'warehouse_id': warehouseId,
        }),
      );

      print('Create checklist response: ${response.statusCode}');
      print('Create checklist body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return MheChecklistTable.fromJson(data['data']);
        }
      }

      if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Gagal membuat checklist');
      }

      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('Error in createChecklist: $e');
      rethrow;
    }
  }

  Future<bool> updateChecklist(int checklistId, int warehouseId, List<MheChecklistTask> tasks) async {
    try {
      final headers = _headers();
      final response = await http.put(
        Uri.parse('$baseUrl/mhe/checklists/$checklistId'),
        headers: headers,
        body: json.encode({
          'warehouse_id': warehouseId,
          'checklist_data': tasks.map((task) => task.toJson()).toList(),
        }),
      );

      print('Update checklist response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error in updateChecklist: $e');
      rethrow;
    }
  }

  Future<bool> deleteChecklist(int checklistId) async {
    try {
      final headers = _headers();
      final response = await http.delete(
        Uri.parse('$baseUrl/mhe/checklists/$checklistId'),
        headers: headers,
      );

      print('Delete checklist response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error in deleteChecklist: $e');
      rethrow;
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
