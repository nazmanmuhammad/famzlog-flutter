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
