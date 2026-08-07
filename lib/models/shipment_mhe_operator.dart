class ShipmentMheOperator {
  final int id;
  final int warehouseId;
  final String operatorName;
  final String mheType;
  final int palletCount;
  final String date;
  final String? createdAt;
  final String? updatedAt;
  
  final ShipmentWarehouse? warehouse;

  ShipmentMheOperator({
    required this.id,
    required this.warehouseId,
    required this.operatorName,
    required this.mheType,
    required this.palletCount,
    required this.date,
    this.createdAt,
    this.updatedAt,
    this.warehouse,
  });

  factory ShipmentMheOperator.fromJson(Map<String, dynamic> json) {
    return ShipmentMheOperator(
      id: json['id'] as int,
      warehouseId: json['warehouse_id'] as int,
      operatorName: json['operator_name'] as String,
      mheType: json['mhe_type'] as String,
      palletCount: int.tryParse(json['pallet_count'].toString()) ?? 0,
      date: json['date'] as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      warehouse: json['warehouse'] != null 
          ? ShipmentWarehouse.fromJson(json['warehouse']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouse_id': warehouseId,
      'operator_name': operatorName,
      'mhe_type': mheType,
      'pallet_count': palletCount,
      'date': date,
    };
  }
}

class ShipmentWarehouse {
  final int id;
  final String name;
  final String? code;

  ShipmentWarehouse({
    required this.id,
    required this.name,
    this.code,
  });

  factory ShipmentWarehouse.fromJson(Map<String, dynamic> json) {
    return ShipmentWarehouse(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
    );
  }
}

class ShipmentMheOperatorStatistics {
  final int totalPallets;
  final int totalRecords;

  ShipmentMheOperatorStatistics({
    required this.totalPallets,
    required this.totalRecords,
  });

  factory ShipmentMheOperatorStatistics.fromJson(Map<String, dynamic> json) {
    return ShipmentMheOperatorStatistics(
      totalPallets: int.tryParse(json['total_pallets']?.toString() ?? '0') ?? 0,
      totalRecords: int.tryParse(json['total_records']?.toString() ?? '0') ?? 0,
    );
  }
}
