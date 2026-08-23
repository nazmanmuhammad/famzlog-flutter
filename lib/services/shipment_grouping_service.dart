import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:famzlog_flutter/models/shipment_grouping.dart';

class ShipmentGroupingService {
  static const String baseUrl = 'https://fm.fam-zlog.web.id/api';

  static Future<List<ShipmentGrouping>> fetchRecords({
    String? search,
    String? date,
  }) async {
    try {
      final token = AuthService.token;
      if (token == null) throw Exception('Token not found');

      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['operator_name'] = search;
      }
      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }

      final uri = Uri.parse('$baseUrl/shipment-groupings')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> recordsJson = data['data'];
        return recordsJson
            .map((json) => ShipmentGrouping.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load records: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching records: $e');
    }
  }

  static Future<ShipmentGroupingStatistics> fetchStatistics({
    String? date,
  }) async {
    try {
      final token = AuthService.token;
      if (token == null) throw Exception('Token not found');

      final queryParams = <String, String>{};
      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }

      final uri = Uri.parse('$baseUrl/shipment-groupings/statistics')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ShipmentGroupingStatistics.fromJson(data['data']);
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching statistics: $e');
    }
  }

  static Future<void> createRecord(Map<String, dynamic> data) async {
    try {
      final token = AuthService.token;
      if (token == null) throw Exception('Token not found');

      final response = await http.post(
        Uri.parse('$baseUrl/shipment-groupings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create record');
      }
    } catch (e) {
      throw Exception('Error creating record: $e');
    }
  }

  static Future<void> updateRecord(int id, Map<String, dynamic> data) async {
    try {
      final token = AuthService.token;
      if (token == null) throw Exception('Token not found');

      final response = await http.put(
        Uri.parse('$baseUrl/shipment-groupings/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update record');
      }
    } catch (e) {
      throw Exception('Error updating record: $e');
    }
  }

  static Future<void> deleteRecord(int id) async {
    try {
      final token = AuthService.token;
      if (token == null) throw Exception('Token not found');

      final response = await http.delete(
        Uri.parse('$baseUrl/shipment-groupings/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete record');
      }
    } catch (e) {
      throw Exception('Error deleting record: $e');
    }
  }
}
