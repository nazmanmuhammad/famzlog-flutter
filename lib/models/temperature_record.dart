class Room {
  final int id;
  final String roomName;
  final String picName;

  Room({
    required this.id,
    required this.roomName,
    required this.picName,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      roomName: json['room_name'] as String,
      picName: json['pic_name'] as String,
    );
  }
}

class TemperatureRecord {
  final int id;
  final int warehouseId;
  final String? warehouseName;
  final int roomId;
  final String roomName;
  final int picId;
  final String picName;
  final double temperature;
  final String? notes;
  final DateTime recordedAt;
  final DateTime createdAt;

  TemperatureRecord({
    required this.id,
    required this.warehouseId,
    this.warehouseName,
    required this.roomId,
    required this.roomName,
    required this.picId,
    required this.picName,
    required this.temperature,
    this.notes,
    required this.recordedAt,
    required this.createdAt,
  });

  factory TemperatureRecord.fromJson(Map<String, dynamic> json) {
    return TemperatureRecord(
      id: json['id'] as int,
      warehouseId: json['warehouse_id'] as int,
      warehouseName: json['warehouse_name'] as String?,
      roomId: json['room_id'] as int,
      roomName: json['room_name'] as String,
      picId: json['pic_id'] as int,
      picName: json['pic_name'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      notes: json['notes'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TemperatureStatistics {
  final int totalRecords;
  final double averageTemperature;
  final double minTemperature;
  final double maxTemperature;

  TemperatureStatistics({
    required this.totalRecords,
    required this.averageTemperature,
    required this.minTemperature,
    required this.maxTemperature,
  });

  factory TemperatureStatistics.fromJson(Map<String, dynamic> json) {
    return TemperatureStatistics(
      totalRecords: json['total_records'] as int,
      averageTemperature: (json['average_temperature'] as num).toDouble(),
      minTemperature: (json['min_temperature'] as num).toDouble(),
      maxTemperature: (json['max_temperature'] as num).toDouble(),
    );
  }
}
