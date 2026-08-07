class ShipmentGrouping {
  final int id;
  final int warehouseId;
  final String operatorName;
  final int containerCount;
  final int koliCount;
  final String date;
  final String? createdAt;
  final String? updatedAt;
  
  final GroupingWarehouse? warehouse;

  ShipmentGrouping({
    required this.id,
    required this.warehouseId,
    required this.operatorName,
    required this.containerCount,
    required this.koliCount,
    required this.date,
    this.createdAt,
    this.updatedAt,
    this.warehouse,
  });

  factory ShipmentGrouping.fromJson(Map<String, dynamic> json) {
    return ShipmentGrouping(
      id: json['id'] as int,
      warehouseId: json['warehouse_id'] as int,
      operatorName: json['operator_name'] as String,
      containerCount: int.tryParse(json['container_count'].toString()) ?? 0,
      koliCount: int.tryParse(json['koli_count'].toString()) ?? 0,
      date: json['date'] as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      warehouse: json['warehouse'] != null 
          ? GroupingWarehouse.fromJson(json['warehouse']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouse_id': warehouseId,
      'operator_name': operatorName,
      'container_count': containerCount,
      'koli_count': koliCount,
      'date': date,
    };
  }
}

class GroupingWarehouse {
  final int id;
  final String name;
  final String? code;

  GroupingWarehouse({
    required this.id,
    required this.name,
    this.code,
  });

  factory GroupingWarehouse.fromJson(Map<String, dynamic> json) {
    return GroupingWarehouse(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
    );
  }
}

class ShipmentGroupingStatistics {
  final int totalContainers;
  final int totalKoli;
  final int totalRecords;

  ShipmentGroupingStatistics({
    required this.totalContainers,
    required this.totalKoli,
    required this.totalRecords,
  });

  factory ShipmentGroupingStatistics.fromJson(Map<String, dynamic> json) {
    return ShipmentGroupingStatistics(
      totalContainers: int.tryParse(json['total_containers']?.toString() ?? '0') ?? 0,
      totalKoli: int.tryParse(json['total_koli']?.toString() ?? '0') ?? 0,
      totalRecords: int.tryParse(json['total_records']?.toString() ?? '0') ?? 0,
    );
  }
}
