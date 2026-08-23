import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:famzlog_flutter/services/auth_service.dart';

class MaterialService {
  static const String _baseUrl = 'http://10.97.120.57:9000/api';

  static Map<String, String> _headers() {
    final token = AuthService.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get list of materials
  static Future<List<MaterialModel>> getMaterials({String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$_baseUrl/materials').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> materialsJson = data['data'];
          return materialsJson.map((json) => MaterialModel.fromJson(json)).toList();
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception('Gagal mengambil data material');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

class MaterialModel {
  final int id;
  final String nama;
  final String? uom;
  final String? createdAt;
  final String? updatedAt;

  MaterialModel({
    required this.id,
    required this.nama,
    this.uom,
    this.createdAt,
    this.updatedAt,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] as int,
      nama: json['nama'] as String,
      uom: json['uom'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
