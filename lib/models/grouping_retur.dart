class GroupingRetur {
  final int id;
  final int warehouseId;
  final String operatorName;
  final int supplierCount;
  final int qtyItems;
  final int qtyPallet;
  final String date;
  final String? createdAt;
  final String? updatedAt;
  
  final ReturWarehouse? warehouse;

  GroupingRetur({
    required this.id,
    required this.warehouseId,
    required this.operatorName,
    required this.supplierCount,
    required this.qtyItems,
    required this.qtyPallet,
    required this.date,
    this.createdAt,
    this.updatedAt,
    this.warehouse,
  });

  factory GroupingRetur.fromJson(Map<String, dynamic> json) {
    return GroupingRetur(
      id: json['id'] as int,
      warehouseId: json['warehouse_id'] as int,
      operatorName: json['operator_name'] as String,
      supplierCount: int.tryParse(json['supplier_count'].toString()) ?? 0,
      qtyItems: int.tryParse(json['qty_items'].toString()) ?? 0,
      qtyPallet: int.tryParse(json['qty_pallet']?.toString() ?? '0') ?? 0,
      date: json['date'] as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      warehouse: json['warehouse'] != null 
          ? ReturWarehouse.fromJson(json['warehouse']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouse_id': warehouseId,
      'operator_name': operatorName,
      'supplier_count': supplierCount,
      'qty_items': qtyItems,
      'qty_pallet': qtyPallet,
      'date': date,
    };
  }
}

class ReturWarehouse {
  final int id;
  final String name;
  final String? code;

  ReturWarehouse({
    required this.id,
    required this.name,
    this.code,
  });

  factory ReturWarehouse.fromJson(Map<String, dynamic> json) {
    return ReturWarehouse(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
    );
  }
}

class GroupingReturStatistics {
  final int totalSuppliers;
  final int totalQty;
  final int totalPallets;
  final int totalRecords;

  GroupingReturStatistics({
    required this.totalSuppliers,
    required this.totalQty,
    required this.totalPallets,
    required this.totalRecords,
  });

  factory GroupingReturStatistics.fromJson(Map<String, dynamic> json) {
    return GroupingReturStatistics(
      totalSuppliers: int.tryParse(json['total_suppliers']?.toString() ?? '0') ?? 0,
      totalQty: int.tryParse(json['total_qty']?.toString() ?? '0') ?? 0,
      totalPallets: int.tryParse(json['total_pallets']?.toString() ?? '0') ?? 0,
      totalRecords: int.tryParse(json['total_records']?.toString() ?? '0') ?? 0,
    );
  }
}
