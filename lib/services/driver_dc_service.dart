import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:famzlog_flutter/services/warehouse_service.dart';

import 'auth_service.dart';
import 'driver_location_service.dart';

class DriverDcRecord {
  final int id;
  final String licensePlate;
  final String routeCode;
  final String? transporterName;
  final String? scanInTime;
  final String? scanOutTime;
  final int? ritase;

  DriverDcRecord({
    required this.id,
    required this.licensePlate,
    required this.routeCode,
    this.transporterName,
    this.scanInTime,
    this.scanOutTime,
    this.ritase,
  });

  factory DriverDcRecord.fromJson(Map<String, dynamic> json) {
    return DriverDcRecord(
      id: json['id'] as int,
      licensePlate: json['license_plate'] as String,
      routeCode: json['route'] as String,
      transporterName: json['transporter_name'] as String?,
      scanInTime: json['scan_in_time'] as String?,
      scanOutTime: json['scan_out_time'] as String?,
      ritase: json['ritase'] as int?,
    );
  }
}

class RouteOption {
  final int id;
  final String code;
  final String name;

  RouteOption({
    required this.id,
    required this.code,
    required this.name,
  });

  factory RouteOption.fromJson(Map<String, dynamic> json) {
    return RouteOption(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }
}

class VehicleOption {
  final int id;
  final String licensePlate;

  VehicleOption({
    required this.id,
    required this.licensePlate,
  });

  factory VehicleOption.fromJson(Map<String, dynamic> json) {
    return VehicleOption(
      id: json['id'] as int,
      licensePlate: json['license_plate'] as String,
    );
  }
}

class Store {
  final int id;
  final String storeName;
  final int sequence;
  final String status; // 'not_visited', 'unloading', 'finished'
  final String? unloadingStartTime;
  final String? unloadingFinishTime;
  final double? latitude;
  final double? longitude;
  final String? plannedStatus;

  Store({
    required this.id,
    required this.storeName,
    required this.sequence,
    required this.status,
    this.unloadingStartTime,
    this.unloadingFinishTime,
    this.latitude,
    this.longitude,
    this.plannedStatus,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as int,
      storeName: json['store_name'] as String,
      sequence: json['sequence'] as int,
      status: json['status'] as String,
      unloadingStartTime: json['unloading_start_time'] as String?,
      unloadingFinishTime: json['unloading_finish_time'] as String?,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      plannedStatus: json['planned_status'] as String?,
    );
  }
}

class DriverDcDetail {
  final DriverDcRecord record;
  final List<Store> stores;

  DriverDcDetail({required this.record, required this.stores});

  factory DriverDcDetail.fromJson(Map<String, dynamic> json) {
    return DriverDcDetail(
      record: DriverDcRecord.fromJson(json['record'] as Map<String, dynamic>),
      stores: (json['stores'] as List<dynamic>)
          .map((e) => Store.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DriverDcService {
  static const String _baseUrl = 'http://10.20.200.166:90/api';

  static Map<String, String> _headers() {
    final token = AuthService.token;
    if (token == null || token.isEmpty) {
      throw AuthException('Belum login');
    }
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<DriverDcRecord>> fetchRecords() async {
    final uri = Uri.parse('$_baseUrl/driver-dc-records');
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal memuat data Driver DC'));
    }
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => DriverDcRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<RouteOption>> fetchRoutes() async {
    final uri = Uri.parse('$_baseUrl/routes');
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal memuat data route'));
    }
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => RouteOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<VehicleOption>> fetchVehicles() async {
    final uri = Uri.parse('$_baseUrl/vehicles');
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal memuat data kendaraan'));
    }
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VehicleOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<DriverDcRecord> createRecord({
    required String licensePlate,
    required String routeCode,
  }) async {
    final warehouseId = await WarehouseService.getSelectedWarehouseId();
    if (warehouseId == null) {
      throw ApiException('Pilih warehouse terlebih dahulu');
    }

    final uri = Uri.parse('$_baseUrl/driver-dc-records');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: {
        'license_plate': licensePlate,
        'route': routeCode,
        'warehouse_id': warehouseId.toString(),
      },
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal menambah Driver DC'));
    }
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    return DriverDcRecord.fromJson(data['data'] as Map<String, dynamic>);
  }

  static Future<DriverDcRecord> updateRecord({
    required int id,
    required String licensePlate,
    required String routeCode,
  }) async {
    final uri = Uri.parse('$_baseUrl/driver-dc-records/$id');
    final response = await http.put(
      uri,
      headers: _headers(),
      body: {
        'license_plate': licensePlate,
        'route': routeCode,
      },
    );
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal memperbarui Driver DC'));
    }
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    return DriverDcRecord.fromJson(data['data'] as Map<String, dynamic>);
  }

  static Future<void> deleteRecord(int id) async {
    final uri = Uri.parse('$_baseUrl/driver-dc-records/$id');
    final response = await http.delete(uri, headers: _headers());
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(_extractError(response, 'Gagal menghapus Driver DC'));
    }
  }

  static Future<DriverDcDetail> getDropOffDetail(int id) async {
    final uri = Uri.parse('$_baseUrl/driver-dc-records/$id/detail');
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal memuat detail drop off'));
    }
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    return DriverDcDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  static Future<void> startDropOff(int recordId, int storeId) async {
    final uri = Uri.parse(
        '$_baseUrl/driver-dc-records/$recordId/stores/$storeId/start');
    final response = await http.post(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal memulai drop off'));
    }
  }

  static Future<void> finishDropOff(int recordId, int storeId) async {
    final uri = Uri.parse(
        '$_baseUrl/driver-dc-records/$recordId/stores/$storeId/finish');
    final response = await http.post(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(
          _extractError(response, 'Gagal menyelesaikan drop off'));
    }
  }

  static Future<void> processDropOff(int recordId, int storeId) async {
    final uri = Uri.parse(
        '$_baseUrl/driver-dc-records/$recordId/stores/$storeId/process');
    final response = await http.post(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(
          _extractError(response, 'Gagal mengubah status menjadi process'));
    }
  }

  static Future<void> scanOut(int recordId) async {
    final uri = Uri.parse('$_baseUrl/driver-dc-records/$recordId/scan-out');
    final response = await http.post(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal scan out'));
    }
  }

  /// Get the active driver DC record (where scanOutTime is null).
  /// Returns null if no active record is found.
  static Future<DriverDcRecord?> getActiveRecord() async {
    try {
      final records = await fetchRecords();
      // Find the first record where scanOutTime is null
      // Assuming the API returns records sorted by creation date descending,
      // or we just pick the first one that is "active".
      for (final record in records) {
        if (record.scanOutTime == null) {
          return record;
        }
      }
    } catch (_) {
      // Ignore errors, just return null
    }
    return null;
  }

  /// Extract error message from Laravel JSON response.
  /// Falls back to [fallback] if parsing fails.
  static String _extractError(http.Response response, String fallback) {
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body.containsKey('message') && body['message'] is String) {
        return body['message'] as String;
      }
      // Handle validation errors: {"message":"...","errors":{"field":["msg"]}}
      if (body.containsKey('errors') && body['errors'] is Map) {
        final errors = body['errors'] as Map<String, dynamic>;
        final firstMessages = errors.values
            .whereType<List>()
            .expand((list) => list)
            .toList();
        if (firstMessages.isNotEmpty) {
          return firstMessages.first.toString();
        }
      }
    } catch (_) {}
    return fallback;
  }
}

