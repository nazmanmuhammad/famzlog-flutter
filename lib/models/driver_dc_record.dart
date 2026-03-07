class DriverDcRecord {
  final int id;
  final int driverId;
  final String? driverName;
  final String licensePlate;
  final String routeCode;
  final String? transporterName;
  final String? scanInTime;
  final String? scanOutTime;
  final String? loadingStartTime;
  final String? loadingFinishTime;
  final String? warehouseScanOutTime;
  final bool dropOff;
  final int? ritase;
  final String? status;

  DriverDcRecord({
    required this.id,
    required this.driverId,
    this.driverName,
    required this.licensePlate,
    required this.routeCode,
    this.transporterName,
    this.scanInTime,
    this.scanOutTime,
    this.loadingStartTime,
    this.loadingFinishTime,
    this.warehouseScanOutTime,
    this.dropOff = false,
    this.ritase,
    this.status,
  });

  factory DriverDcRecord.fromJson(Map<String, dynamic> json) {
    return DriverDcRecord(
      id: json['id'] as int,
      driverId:
          json['driver_id'] as int? ??
          0, // Fallback to 0 if null, though backend should send it
      driverName: json['driver_name'] as String?,
      licensePlate: json['license_plate'] as String,
      routeCode: json['route'] as String? ?? '-',
      transporterName: json['transporter_name'] as String?,
      scanInTime: json['scan_in_time'] as String?,
      scanOutTime: json['scan_out_time'] as String?,
      loadingStartTime: json['loading_start_time'] as String?,
      loadingFinishTime: json['loading_finish_time'] as String?,
      warehouseScanOutTime: json['warehouse_scan_out_time'] as String?,
      dropOff: json['drop_off'] as bool? ?? false,
      ritase: json['ritase'] as int?,
      status: json['status'] as String?,
    );
  }
}

class RouteOption {
  final int id;
  final String code;
  final String name;

  RouteOption({required this.id, required this.code, required this.name});

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
  final String? driverName;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final String? capturedAt;

  VehicleOption({
    required this.id,
    required this.licensePlate,
    this.driverName,
    this.latitude,
    this.longitude,
    this.speed,
    this.capturedAt,
  });

  factory VehicleOption.fromJson(Map<String, dynamic> json) {
    return VehicleOption(
      id: json['id'] as int,
      licensePlate: json['license_plate'] as String,
      driverName: json['driver_name'] as String?,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      speed: json['speed'] != null
          ? double.tryParse(json['speed'].toString())
          : null,
      capturedAt: json['captured_at'] as String?,
    );
  }
}
