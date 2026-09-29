import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:famzlog_flutter/models/check_random_container.dart';

class CheckRandomContainerService {
  static const String baseUrl = 'https://famzlog.familymartindonesia.com/api';

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer ${AuthService.token}',
        'Accept': 'application/json',
      };

  static Future<List<CheckRandomContainer>> fetchRecords({
    String? search,
    String? date,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['operator_name'] = search;
    if (date != null && date.isNotEmpty) queryParams['date'] = date;

    final uri = Uri.parse('$baseUrl/check-random-containers')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data (${response.statusCode})');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    
    // Handle both paginated and non-paginated responses
    final rawData = body['data'];
    List<dynamic> list;
    
    if (rawData is Map && rawData.containsKey('data')) {
      // Paginated: { data: { data: [...], ... } }
      list = rawData['data'] as List<dynamic>;
    } else if (rawData is List) {
      // Direct array: { data: [...] }
      list = rawData;
    } else {
      list = [];
    }
    
    return list
        .map((e) => CheckRandomContainer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<CheckRandomContainerStatistics> fetchStatistics({
    String? date,
  }) async {
    final queryParams = <String, String>{};
    if (date != null && date.isNotEmpty) queryParams['date'] = date;

    final uri = Uri.parse('$baseUrl/check-random-containers/statistics')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Gagal memuat statistik');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    return CheckRandomContainerStatistics.fromJson(
        body['data'] as Map<String, dynamic>);
  }

  static Future<void> createRecord(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/check-random-containers'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode != 201) {
      final err = json.decode(response.body);
      throw Exception(err['message'] ?? 'Gagal menyimpan data');
    }
  }

  static Future<void> updateRecord(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/check-random-containers/$id'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      final err = json.decode(response.body);
      throw Exception(err['message'] ?? 'Gagal mengupdate data');
    }
  }

  static Future<void> deleteRecord(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/check-random-containers/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus data');
    }
  }
}
