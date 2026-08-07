import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:famzlog_flutter/models/used_oil.dart';
import 'package:famzlog_flutter/services/auth_service.dart';

class UsedOilService {
  static const String baseUrl = 'https://famzlog.softwarenusantara.com/api';

  static Map<String, String> _headers() {
    final token = AuthService.token;
    if (token == null || token.isEmpty) {
      throw Exception('Belum login');
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all used oil records
  static Future<List<UsedOil>> getUsedOils({
    int? warehouseId,
    String? tanggal,
    String? startDate,
    String? endDate,
    String? nopol,
    String? namaDriver,
    String? kodeToko,
    int page = 1,
    int perPage = 15,
  }) async {
    var queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (warehouseId != null) queryParams['warehouse_id'] = warehouseId.toString();
    if (tanggal != null) queryParams['tanggal'] = tanggal;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (nopol != null && nopol.isNotEmpty) queryParams['nopol'] = nopol;
    if (namaDriver != null && namaDriver.isNotEmpty) queryParams['nama_driver'] = namaDriver;
    if (kodeToko != null && kodeToko.isNotEmpty) queryParams['kode_toko'] = kodeToko;

    final uri = Uri.parse('$baseUrl/used-oils').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> records = data['data'] as List<dynamic>;
      return records.map((json) => UsedOil.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat data used oil');
    }
  }

  // Get statistics
  static Future<UsedOilStatistics> getStatistics({
    int? warehouseId,
    String? tanggal,
    String? startDate,
    String? endDate,
  }) async {
    var queryParams = <String, String>{};

    if (warehouseId != null) queryParams['warehouse_id'] = warehouseId.toString();
    if (tanggal != null) queryParams['tanggal'] = tanggal;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/used-oils/statistics').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UsedOilStatistics.fromJson(data['data']);
    } else {
      throw Exception('Gagal memuat statistik');
    }
  }

  // Get single record
  static Future<UsedOil> getUsedOil(int id) async {
    final uri = Uri.parse('$baseUrl/used-oils/$id');
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UsedOil.fromJson(data['data']);
    } else {
      throw Exception('Gagal memuat detail used oil');
    }
  }

  // Create new record
  static Future<UsedOil> createUsedOil(UsedOil usedOil) async {
    final uri = Uri.parse('$baseUrl/used-oils');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: json.encode(usedOil.toJson()),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return UsedOil.fromJson(data['data']);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Gagal menyimpan data');
    }
  }

  // Update record
  static Future<UsedOil> updateUsedOil(int id, UsedOil usedOil) async {
    final uri = Uri.parse('$baseUrl/used-oils/$id');
    final response = await http.put(
      uri,
      headers: _headers(),
      body: json.encode(usedOil.toJson()),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UsedOil.fromJson(data['data']);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Gagal update data');
    }
  }

  // Delete record
  static Future<void> deleteUsedOil(int id) async {
    final uri = Uri.parse('$baseUrl/used-oils/$id');
    final response = await http.delete(uri, headers: _headers());

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Gagal menghapus data');
    }
  }
}
