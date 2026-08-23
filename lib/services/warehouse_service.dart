import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class Warehouse {
  final int id;
  final String code;
  final String name;
  final String address;
  final String city;
  final String province;
  final String statusLabel;
  final double? latitude;
  final double? longitude;

  Warehouse({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    required this.city,
    required this.province,
    required this.statusLabel,
    this.latitude,
    this.longitude,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      province: json['province'] as String,
      statusLabel: json['status_label'] as String? ?? 'Aktif',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}

class WarehouseService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://10.97.120.57:9000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.97.120.57:9000/api';
    }
    return 'http://10.97.120.57:9000/api';
  }

  static const String _warehouseKey = 'selected_warehouse_id';
  static const String _warehouseNameKey =
      'selected_warehouse_name'; // Optional, for display

  static Future<List<Warehouse>> fetchWarehouses() async {
    final token = AuthService.token;
    if (token == null) throw Exception('Belum login');

    final uri = Uri.parse('$_baseUrl/warehouses');
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data warehouse');
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final List<dynamic> list = data['data'] ?? [];
    return list.map((e) => Warehouse.fromJson(e)).toList();
  }

  static Future<void> saveSelectedWarehouse(Warehouse warehouse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_warehouseKey, warehouse.id);
    await prefs.setString(_warehouseNameKey, warehouse.name);
    if (warehouse.latitude != null) {
      await prefs.setDouble('selected_warehouse_latitude', warehouse.latitude!);
    }
    if (warehouse.longitude != null) {
      await prefs.setDouble('selected_warehouse_longitude', warehouse.longitude!);
    }
  }

  static Future<int?> getSelectedWarehouseId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_warehouseKey);
  }

  static Future<String?> getSelectedWarehouseName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_warehouseNameKey);
  }

  static Future<double?> getSelectedWarehouseLatitude() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('selected_warehouse_latitude');
  }

  static Future<double?> getSelectedWarehouseLongitude() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('selected_warehouse_longitude');
  }

  static Future<void> clearSelectedWarehouse() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_warehouseKey);
    await prefs.remove(_warehouseNameKey);
    await prefs.remove('selected_warehouse_latitude');
    await prefs.remove('selected_warehouse_longitude');
  }
}
