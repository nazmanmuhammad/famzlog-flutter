import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:famzlog_flutter/services/warehouse_service.dart';
import 'package:flutter/foundation.dart';

import 'package:famzlog_flutter/models/driver_dc_record.dart';
import 'package:famzlog_flutter/models/driver_dc_shipment.dart';
import 'package:famzlog_flutter/models/store.dart';

import 'auth_service.dart';
import 'driver_location_service.dart';

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
  final String? qtyStatus;
  final String? overloadTime;
  final String? driverNotes;
  final String? estimatedArrivalTime;
  final int? estimatedTravelMinutes;
  final int? estimatedUnloadingMinutes;
  final double? distanceKm;

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
    this.qtyStatus,
    this.overloadTime,
    this.driverNotes,
    this.estimatedArrivalTime,
    this.estimatedTravelMinutes,
    this.estimatedUnloadingMinutes,
    this.distanceKm,
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
      qtyStatus: json['qty_status'] as String?,
      overloadTime: json['overload_time'] as String?,
      driverNotes: json['driver_notes'] as String?,
      estimatedArrivalTime: json['estimated_arrival_time'] as String?,
      estimatedTravelMinutes: json['estimated_travel_minutes'] as int?,
      estimatedUnloadingMinutes: json['estimated_unloading_minutes'] as int?,
      distanceKm: json['distance_km'] != null
          ? double.tryParse(json['distance_km'].toString())
          : null,
    );
  }

  bool get hasEta => estimatedArrivalTime != null;

  String get etaDisplay {
    if (estimatedArrivalTime == null) return '-';
    return 'ETA: $estimatedArrivalTime';
  }

  String get distanceDisplay {
    if (distanceKm == null) return '-';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  String get travelTimeDisplay {
    if (estimatedTravelMinutes == null) return '-';
    final hours = estimatedTravelMinutes! ~/ 60;
    final minutes = estimatedTravelMinutes! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class DriverLocationModel {
  final double latitude;
  final double longitude;
  final String capturedAt;
  final double? speed;
  final double? heading;

  DriverLocationModel({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.speed,
    this.heading,
  });

  factory DriverLocationModel.fromJson(Map<String, dynamic> json) {
    return DriverLocationModel(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      capturedAt: json['captured_at'] as String,
      speed: json['speed'] != null
          ? double.parse(json['speed'].toString())
          : null,
      heading: json['heading'] != null
          ? double.parse(json['heading'].toString())
          : null,
    );
  }
}

class DriverDcDetail {
  final DriverDcRecord record;
  final List<Store> stores;
  final List<DriverLocationModel> locations;

  DriverDcDetail({
    required this.record,
    required this.stores,
    required this.locations,
  });

  factory DriverDcDetail.fromJson(Map<String, dynamic> json) {
    return DriverDcDetail(
      record: DriverDcRecord.fromJson(json['record'] as Map<String, dynamic>),
      stores: (json['stores'] as List<dynamic>)
          .map((e) => Store.fromJson(e as Map<String, dynamic>))
          .toList(),
      locations:
          (json['locations'] as List<dynamic>?)
              ?.map(
                (e) => DriverLocationModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class DriverReportItem {
  final int id;
  final String date;
  final String route;
  final String checkoutDc;
  final String dcTo1stDp;
  final String lastDpToDc;
  final String idleTime;
  final String travelTimeTotal;
  final String status;
  final DriverStoreStats storeStats;

  DriverReportItem({
    required this.id,
    required this.date,
    required this.route,
    required this.checkoutDc,
    required this.dcTo1stDp,
    required this.lastDpToDc,
    required this.idleTime,
    required this.travelTimeTotal,
    required this.status,
    required this.storeStats,
  });

  factory DriverReportItem.fromJson(Map<String, dynamic> json) {
    return DriverReportItem(
      id: json['id'],
      date: json['date'],
      route: json['route'] ?? '-',
      checkoutDc: json['checkout_dc'] ?? '-',
      dcTo1stDp: json['dc_to_1st_dp'] ?? '-',
      lastDpToDc: json['last_dp_to_dc'] ?? '-',
      idleTime: json['idle_time'] ?? '-',
      travelTimeTotal: json['travel_time_total'] ?? '-',
      status: json['status'] ?? '-',
      storeStats: DriverStoreStats.fromJson(json['store_stats'] ?? {}),
    );
  }
}

class DriverStoreStats {
  final int completed;
  final int processing;
  final int pending;

  DriverStoreStats({
    required this.completed,
    required this.processing,
    required this.pending,
  });

  factory DriverStoreStats.fromJson(Map<String, dynamic> json) {
    return DriverStoreStats(
      completed: json['completed'] ?? 0,
      processing: json['processing'] ?? 0,
      pending: json['pending'] ?? 0,
    );
  }
}

class DriverReportSummary {
  final int completed;
  final int ongoing;

  DriverReportSummary({required this.completed, required this.ongoing});

  factory DriverReportSummary.fromJson(Map<String, dynamic> json) {
    return DriverReportSummary(
      completed: json['completed'] ?? 0,
      ongoing: json['ongoing'] ?? 0,
    );
  }
}

class DriverReportResponse {
  final DriverReportSummary summary;
  final List<DriverReportItem> data;

  DriverReportResponse({required this.summary, required this.data});
}

class DriverDcService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://10.97.120.57:9000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.97.120.57:9000/api';
    }
    return 'http://10.97.120.57:9000/api';
  }

  static Map<String, String> _headers([String? token]) {
    final actualToken = token ?? AuthService.token;
    if (actualToken == null || actualToken.isEmpty) {
      throw AuthException('Belum login');
    }
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $actualToken',
    };
  }

  static Future<List<DriverDcRecord>> fetchRecords({
    String? token,
    int? limit,
    DateTime? date,
    String? status,
  }) async {
    // Get warehouse_id from local storage selection
    int? warehouseId = await WarehouseService.getSelectedWarehouseId();

    var queryParams = <String, String>{};
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }
    if (warehouseId != null) {
      queryParams['warehouse_id'] = warehouseId.toString();
    }
    if (date != null) {
      String dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      queryParams['date'] = dateStr;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    var uri = Uri.parse(
      '$_baseUrl/driver-dc-records',
    ).replace(queryParameters: queryParams);

    debugPrint('fetchRecords: URI = $uri');

    final response = await http.get(uri, headers: _headers(token));
    
    debugPrint('fetchRecords: Status = ${response.statusCode}');
    
    if (response.statusCode != 200) {
      throw ApiException(
        _extractError(response, 'Gagal memuat data Driver DC'),
      );
    }
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    
    debugPrint('fetchRecords: Received ${list.length} records from API');
    
    return list
        .map((e) => DriverDcRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, int>> fetchSummary({String? token}) async {
    // Get warehouse_id from local storage selection
    int? warehouseId = await WarehouseService.getSelectedWarehouseId();

    var queryParams = <String, String>{};
    if (warehouseId != null) {
      queryParams['warehouse_id'] = warehouseId.toString();
    }
    final uri = Uri.parse(
      '$_baseUrl/driver-dc-records/summary',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal memuat summary'));
    }
    final Map<String, dynamic> body =
        json.decode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return {
      'ongoing': data['ongoing'] as int,
      'completed': data['completed'] as int,
    };
  }

  static Future<List<RouteOption>> fetchRoutes() async {
    // Get selected warehouse_id from SharedPreferences
    final warehouseId = await WarehouseService.getSelectedWarehouseId();
    
    var queryParams = <String, String>{};
    if (warehouseId != null) {
      queryParams['warehouse_id'] = warehouseId.toString();
    }
    
    final uri = Uri.parse('$_baseUrl/routes')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    
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

  static Future<List<StoreOption>> fetchStores({String? search}) async {
    var queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse('$_baseUrl/stores')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());
    
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal memuat data store'));
    }
    
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    
    return list
        .map((e) => StoreOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<VehicleOption>> fetchVehicles() async {
    final uri = Uri.parse('$_baseUrl/vehicles');
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(
        _extractError(response, 'Gagal memuat data kendaraan'),
      );
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
    // Get warehouse_id from local storage selection
    int? warehouseId = await WarehouseService.getSelectedWarehouseId();

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

  static Future<DriverDcRecord> createRecordWithCustomRoute({
    required String licensePlate,
    required String customRouteName,
    required List<int> storeIds,
  }) async {
    int? warehouseId = await WarehouseService.getSelectedWarehouseId();

    if (warehouseId == null) {
      throw ApiException('Pilih warehouse terlebih dahulu');
    }

    final uri = Uri.parse('$_baseUrl/driver-dc-records');
    final headers = _headers();
    headers['Content-Type'] = 'application/json';

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({
        'warehouse_id': warehouseId,
        'license_plate': licensePlate,
        'is_custom_route': true,
        'custom_route_name': customRouteName,
        'store_ids': storeIds,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException(
          _extractError(response, 'Gagal membuat custom route'));
    }

    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    return DriverDcRecord.fromJson(data['data'] as Map<String, dynamic>);
  }

  static Future<DriverReportResponse> fetchReport({
    int? month,
    int? year,
  }) async {
    // Get warehouse_id from local storage selection
    int? warehouseId = await WarehouseService.getSelectedWarehouseId();

    var queryParams = <String, String>{};
    if (warehouseId != null) {
      queryParams['warehouse_id'] = warehouseId.toString();
    }

    if (month != null && year != null) {
      // Calculate start and end date for the month
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      // Simple formatting yyyy-MM-dd manually to avoid intl dependency issues in service if not present
      String formatDate(DateTime d) {
        return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      }

      queryParams['start_date'] = formatDate(startDate);
      queryParams['end_date'] = formatDate(endDate);
    }

    final uri = Uri.parse(
      '$_baseUrl/driver-dc-records/report',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          json.decode(response.body) as Map<String, dynamic>;
      final summary = DriverReportSummary.fromJson(body['summary'] ?? {});
      final list = (body['data'] as List)
          .map((e) => DriverReportItem.fromJson(e))
          .toList();
      return DriverReportResponse(summary: summary, data: list);
    } else {
      throw Exception('Failed to load report');
    }
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
      body: {'license_plate': licensePlate, 'route': routeCode},
    );
    if (response.statusCode != 200) {
      throw ApiException(
        _extractError(response, 'Gagal memperbarui Driver DC'),
      );
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
      throw ApiException(
        _extractError(response, 'Gagal memuat detail drop off'),
      );
    }
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    return DriverDcDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  static Future<DriverDcShipment> fetchShipment(int id) async {
    final uri = Uri.parse('$_baseUrl/driver-dc-records/$id/shipment');
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal memuat data shipment'));
    }
    final Map<String, dynamic> body =
        json.decode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return DriverDcShipment.fromJson(data);
  }

  static Future<void> updateShipment(
    int id,
    List<Map<String, dynamic>> stores,
  ) async {
    final uri = Uri.parse('$_baseUrl/driver-dc-records/$id/shipment');
    final headers = _headers();
    headers['Content-Type'] = 'application/json';

    final response = await http.put(
      uri,
      headers: headers,
      body: json.encode({'stores': stores}),
    );
    if (response.statusCode != 200) {
      throw ApiException(
        _extractError(response, 'Gagal menyimpan data shipment'),
      );
    }
  }

  static Future<void> startDropOff(int recordId, int storeId) async {
    final uri = Uri.parse(
      '$_baseUrl/driver-dc-records/$recordId/stores/$storeId/start',
    );
    final response = await http.post(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal memulai drop off'));
    }
  }

  static Future<void> finishDropOff(int recordId, int storeId) async {
    final uri = Uri.parse(
      '$_baseUrl/driver-dc-records/$recordId/stores/$storeId/finish',
    );
    final response = await http.post(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(
        _extractError(response, 'Gagal menyelesaikan drop off'),
      );
    }
  }

  static Future<void> ignoreDropOff(
    int recordId,
    int storeId, {
    String action = 'overload',
    String? reason,
    String? notes,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/driver-dc-records/$recordId/stores/$storeId/ignore',
    );
    final headers = _headers();
    headers['Content-Type'] = 'application/json';
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({
        'action': action,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal mengabaikan drop off'));
    }
  }

  static Future<void> processDropOff(int recordId, int storeId) async {
    final uri = Uri.parse(
      '$_baseUrl/driver-dc-records/$recordId/stores/$storeId/process',
    );
    final response = await http.post(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(
        _extractError(response, 'Gagal mengubah status menjadi process'),
      );
    }
  }

  static Future<Map<String, dynamic>> scanOut(int recordId) async {
    final uri = Uri.parse('$_baseUrl/driver-dc-records/$recordId/scan-out');
    final response = await http.post(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal scan out'));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  static Future<void> scanOutWarehouse(int recordId) async {
    final uri = Uri.parse(
      '$_baseUrl/driver-dc-records/$recordId/scan-out-warehouse',
    );
    final response = await http.post(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal scan out warehouse'));
    }
  }

  /// Get the active driver DC record (where scanOutTime is null).
  /// Returns null if no active record is found.
  static Future<DriverDcRecord?> getActiveRecord({String? token}) async {
    try {
      debugPrint('getActiveRecord: Fetching records...');
      final records = await fetchRecords(token: token);
      debugPrint('getActiveRecord: Received ${records.length} records');
      
      // Find the first record where scanOutTime is null
      for (final record in records) {
        debugPrint('getActiveRecord: Checking record #${record.id}, scanOutTime: ${record.scanOutTime}');
        if (record.scanOutTime == null) {
          debugPrint('getActiveRecord: ✅ Found active trip #${record.id}');
          return record;
        }
      }
      debugPrint('getActiveRecord: ❌ No active trip found (all trips have scanOutTime)');
    } catch (e) {
      debugPrint('getActiveRecord: ❌ Error - $e');
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

  /// Calculate ETA for all stores in a trip
  static Future<DriverDcDetail> calculateEta(int recordId) async {
    final uri = Uri.parse('$_baseUrl/driver-dc-records/$recordId/calculate-eta');
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw ApiException(_extractError(response, 'Gagal menghitung ETA'));
    }
    final Map<String, dynamic> body =
        json.decode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return DriverDcDetail.fromJson(data);
  }
}
