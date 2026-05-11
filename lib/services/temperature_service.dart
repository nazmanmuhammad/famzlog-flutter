import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/temperature_record.dart';
import 'auth_service.dart';

class TemperatureService {
  static const String baseUrl = 'http://192.168.1.52:8000/api';

  // Get all temperature records with filters
  static Future<List<TemperatureRecord>> fetchRecords({
    int? roomId,
    String? date,
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    final token = AuthService.token;
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{};
    if (roomId != null) queryParams['room_id'] = roomId.toString();
    if (date != null) queryParams['date'] = date;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (limit != null) queryParams['limit'] = limit.toString();

    final uri = Uri.parse('$baseUrl/temperature-records')
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
      if (data['success'] == true) {
        final List<dynamic> recordsJson = data['data'];
        return recordsJson.map((json) => TemperatureRecord.fromJson(json)).toList();
      }
      throw Exception(data['message'] ?? 'Failed to fetch records');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to fetch records: ${response.statusCode}');
    }
  }

  // Get single temperature record
  static Future<TemperatureRecord> fetchRecord(int id) async {
    final token = AuthService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/temperature-records/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return TemperatureRecord.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to fetch record');
    } else if (response.statusCode == 404) {
      throw Exception('Record not found');
    } else {
      throw Exception('Failed to fetch record: ${response.statusCode}');
    }
  }

  // Create new temperature record
  static Future<TemperatureRecord> createRecord({
    required int roomId,
    required double temperature,
    String? notes,
    DateTime? recordedAt,
  }) async {
    final token = AuthService.token;
    if (token == null) throw Exception('Not authenticated');

    final body = {
      'room_id': roomId,
      'temperature': temperature,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (recordedAt != null) 'recorded_at': recordedAt.toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/temperature-records'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return TemperatureRecord.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to create record');
    } else if (response.statusCode == 422) {
      final data = json.decode(response.body);
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null) {
        final errorMessages = errors.values.map((e) => (e as List).join(', ')).join('\n');
        throw Exception(errorMessages);
      }
      throw Exception(data['message'] ?? 'Validation failed');
    } else {
      throw Exception('Failed to create record: ${response.statusCode}');
    }
  }

  // Update temperature record
  static Future<TemperatureRecord> updateRecord({
    required int id,
    int? roomId,
    double? temperature,
    String? notes,
    DateTime? recordedAt,
  }) async {
    final token = AuthService.token;
    if (token == null) throw Exception('Not authenticated');

    final body = <String, dynamic>{};
    if (roomId != null) body['room_id'] = roomId;
    if (temperature != null) body['temperature'] = temperature;
    if (notes != null) body['notes'] = notes;
    if (recordedAt != null) body['recorded_at'] = recordedAt.toIso8601String();

    final response = await http.put(
      Uri.parse('$baseUrl/temperature-records/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return TemperatureRecord.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to update record');
    } else if (response.statusCode == 404) {
      throw Exception('Record not found');
    } else if (response.statusCode == 422) {
      final data = json.decode(response.body);
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null) {
        final errorMessages = errors.values.map((e) => (e as List).join(', ')).join('\n');
        throw Exception(errorMessages);
      }
      throw Exception(data['message'] ?? 'Validation failed');
    } else {
      throw Exception('Failed to update record: ${response.statusCode}');
    }
  }

  // Delete temperature record
  static Future<void> deleteRecord(int id) async {
    final token = AuthService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('$baseUrl/temperature-records/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return;
      }
      throw Exception(data['message'] ?? 'Failed to delete record');
    } else if (response.statusCode == 404) {
      throw Exception('Record not found');
    } else {
      throw Exception('Failed to delete record: ${response.statusCode}');
    }
  }

  // Get temperature statistics
  static Future<TemperatureStatistics> fetchStatistics({
    int? roomId,
    String? startDate,
    String? endDate,
  }) async {
    final token = AuthService.token;
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{};
    if (roomId != null) queryParams['room_id'] = roomId.toString();
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/temperature-records/statistics')
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
      if (data['success'] == true) {
        return TemperatureStatistics.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to fetch statistics');
    } else {
      throw Exception('Failed to fetch statistics: ${response.statusCode}');
    }
  }

  // Get list of rooms
  static Future<List<Room>> fetchRooms() async {
    final token = AuthService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/temperature-records/rooms'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final List<dynamic> roomsJson = data['data'];
        return roomsJson.map((json) => Room.fromJson(json)).toList();
      }
      throw Exception(data['message'] ?? 'Failed to fetch rooms');
    } else {
      throw Exception('Failed to fetch rooms: ${response.statusCode}');
    }
  }
}
