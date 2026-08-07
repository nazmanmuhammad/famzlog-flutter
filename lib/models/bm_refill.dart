class BmRefill {
  final int id;
  final int warehouseId;
  final String operatorName;
  final int binCount;
  final int qtyItems;
  final String date;
  final String? createdAt;
  final String? updatedAt;
  
  final BmWarehouse? warehouse;

  BmRefill({
    required this.id,
    required this.warehouseId,
    required this.operatorName,
    required this.binCount,
    required this.qtyItems,
    required this.date,
    this.createdAt,
    this.updatedAt,
    this.warehouse,
  });

  factory BmRefill.fromJson(Map<String, dynamic> json) {
    return BmRefill(
      id: json['id'] as int,
      warehouseId: json['warehouse_id'] as int,
      operatorName: json['operator_name'] as String,
      binCount: int.tryParse(json['bin_count'].toString()) ?? 0,
      qtyItems: int.tryParse(json['qty_items'].toString()) ?? 0,
      date: json['date'] as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      warehouse: json['warehouse'] != null 
          ? BmWarehouse.fromJson(json['warehouse']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouse_id': warehouseId,
      'operator_name': operatorName,
      'bin_count': binCount,
      'qty_items': qtyItems,
      'date': date,
    };
  }
}

class BmWarehouse {
  final int id;
  final String name;
  final String? code;

  BmWarehouse({
    required this.id,
    required this.name,
    this.code,
  });

  factory BmWarehouse.fromJson(Map<String, dynamic> json) {
    return BmWarehouse(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
    );
  }
}

class BmRefillStatistics {
  final int totalBins;
  final int totalQty;
  final int totalRecords;

  BmRefillStatistics({
    required this.totalBins,
    required this.totalQty,
    required this.totalRecords,
  });

  factory BmRefillStatistics.fromJson(Map<String, dynamic> json) {
    return BmRefillStatistics(
      totalBins: int.tryParse(json['total_bins']?.toString() ?? '0') ?? 0,
      totalQty: int.tryParse(json['total_qty']?.toString() ?? '0') ?? 0,
      totalRecords: int.tryParse(json['total_records']?.toString() ?? '0') ?? 0,
    );
  }
}
