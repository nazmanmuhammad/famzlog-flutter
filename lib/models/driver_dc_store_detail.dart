class DriverDcStoreDetail {
  final int id;
  final String storeName;
  final int sequence;
  final int? visitOrder;
  final String status;
  final String? plannedStatus;
  final String? unloadingStartTime;
  final String? unloadingFinishTime;
  final String? overloadTime;
  final String? estimatedArrivalTime;
  final int? estimatedTravelMinutes;
  final int? estimatedUnloadingMinutes;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;

  DriverDcStoreDetail({
    required this.id,
    required this.storeName,
    required this.sequence,
    this.visitOrder,
    required this.status,
    this.plannedStatus,
    this.unloadingStartTime,
    this.unloadingFinishTime,
    this.overloadTime,
    this.estimatedArrivalTime,
    this.estimatedTravelMinutes,
    this.estimatedUnloadingMinutes,
    this.distanceKm,
    this.latitude,
    this.longitude,
  });

  factory DriverDcStoreDetail.fromJson(Map<String, dynamic> json) {
    return DriverDcStoreDetail(
      id: json['id'] as int,
      storeName: json['store_name'] as String,
      sequence: json['sequence'] as int,
      visitOrder: json['visit_order'] as int?,
      status: json['status'] as String? ?? 'not_visited',
      plannedStatus: json['planned_status'] as String?,
      unloadingStartTime: json['unloading_start_time'] as String?,
      unloadingFinishTime: json['unloading_finish_time'] as String?,
      overloadTime: json['overload_time'] as String?,
      estimatedArrivalTime: json['estimated_arrival_time'] as String?,
      estimatedTravelMinutes: json['estimated_travel_minutes'] as int?,
      estimatedUnloadingMinutes: json['estimated_unloading_minutes'] as int?,
      distanceKm: json['distance_km'] != null
          ? double.tryParse(json['distance_km'].toString())
          : null,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }

  bool get isFinished =>
      unloadingFinishTime != null || overloadTime != null;

  bool get hasEta => estimatedArrivalTime != null;

  String get statusDisplay {
    if (unloadingFinishTime != null) return 'Selesai';
    if (overloadTime != null) return 'Overload';
    if (unloadingStartTime != null) return 'Unloading';
    if (status == 'process') return 'Menuju Toko';
    return 'Belum Dikunjungi';
  }

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
