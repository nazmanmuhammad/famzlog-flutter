class Wwtp {
  final int id;
  final int warehouseId;
  final int materialId;
  final String pickerName;
  final double wwtpIn;
  final double wwtpOut;
  final String date;
  final String? createdAt;
  final String? updatedAt;
  
  // Relations
  final WwtpWarehouse? warehouse;
  final WwtpMaterial? material;

  Wwtp({
    required this.id,
    required this.warehouseId,
    required this.materialId,
    required this.pickerName,
    required this.wwtpIn,
    required this.wwtpOut,
    required this.date,
    this.createdAt,
    this.updatedAt,
    this.warehouse,
    this.material,
  });

  factory Wwtp.fromJson(Map<String, dynamic> json) {
    return Wwtp(
      id: json['id'] as int,
      warehouseId: json['warehouse_id'] as int,
      materialId: json['material_id'] as int,
      pickerName: json['picker_name'] as String,
      wwtpIn: double.tryParse(json['wwtp_in'].toString()) ?? 0.0,
      wwtpOut: double.tryParse(json['wwtp_out'].toString()) ?? 0.0,
      date: json['date'] as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      warehouse: json['warehouse'] != null 
          ? WwtpWarehouse.fromJson(json['warehouse']) 
          : null,
      material: json['material'] != null 
          ? WwtpMaterial.fromJson(json['material']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouse_id': warehouseId,
      'material_id': materialId,
      'picker_name': pickerName,
      'wwtp_in': wwtpIn,
      'wwtp_out': wwtpOut,
      'date': date,
    };
  }
}

class WwtpWarehouse {
  final int id;
  final String name;
  final String? code;

  WwtpWarehouse({
    required this.id,
    required this.name,
    this.code,
  });

  factory WwtpWarehouse.fromJson(Map<String, dynamic> json) {
    return WwtpWarehouse(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
    );
  }
}

class WwtpMaterial {
  final int id;
  final String nama;
  final String? uom;

  WwtpMaterial({
    required this.id,
    required this.nama,
    this.uom,
  });

  factory WwtpMaterial.fromJson(Map<String, dynamic> json) {
    return WwtpMaterial(
      id: json['id'] as int,
      nama: json['nama'] as String,
      uom: json['uom'] as String?,
    );
  }
}

class WwtpStatistics {
  final double totalWwtpIn;
  final double totalWwtpOut;
  final double balance;
  final int totalRecords;

  WwtpStatistics({
    required this.totalWwtpIn,
    required this.totalWwtpOut,
    required this.balance,
    required this.totalRecords,
  });

  factory WwtpStatistics.fromJson(Map<String, dynamic> json) {
    return WwtpStatistics(
      totalWwtpIn: double.tryParse(json['total_wwtp_in']?.toString() ?? '0') ?? 0.0,
      totalWwtpOut: double.tryParse(json['total_wwtp_out']?.toString() ?? '0') ?? 0.0,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      totalRecords: int.tryParse(json['total_records']?.toString() ?? '0') ?? 0,
    );
  }
}
