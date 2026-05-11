class UsedOil {
  final int id;
  final int warehouseId;
  final String tanggal;
  final String jam;
  final String? kodeToko;
  final String namaToko;
  final String nopol;
  final String namaDriver;
  final String? noPo;
  final double usedOilIn;
  final double usedOilOut;
  final String? keterangan;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  UsedOil({
    required this.id,
    required this.warehouseId,
    required this.tanggal,
    required this.jam,
    this.kodeToko,
    required this.namaToko,
    required this.nopol,
    required this.namaDriver,
    this.noPo,
    required this.usedOilIn,
    required this.usedOilOut,
    this.keterangan,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory UsedOil.fromJson(Map<String, dynamic> json) {
    return UsedOil(
      id: json['id'] as int,
      warehouseId: json['warehouse_id'] as int,
      tanggal: json['tanggal'] as String,
      jam: json['jam'] as String,
      kodeToko: json['kode_toko'] as String?,
      namaToko: json['nama_toko'] as String,
      nopol: json['nopol'] as String,
      namaDriver: json['nama_driver'] as String,
      noPo: json['no_po'] as String?,
      usedOilIn: double.tryParse(json['used_oil_in'].toString()) ?? 0.0,
      usedOilOut: double.tryParse(json['used_oil_out'].toString()) ?? 0.0,
      keterangan: json['keterangan'] as String?,
      createdBy: json['created_by'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouse_id': warehouseId,
      'tanggal': tanggal,
      'jam': jam,
      'kode_toko': kodeToko,
      'nama_toko': namaToko,
      'nopol': nopol,
      'nama_driver': namaDriver,
      'no_po': noPo,
      'used_oil_in': usedOilIn,
      'used_oil_out': usedOilOut,
      'keterangan': keterangan,
    };
  }
}

class UsedOilStatistics {
  final double totalUsedOilIn;
  final double totalUsedOilOut;
  final double balance;
  final int totalRecords;

  UsedOilStatistics({
    required this.totalUsedOilIn,
    required this.totalUsedOilOut,
    required this.balance,
    required this.totalRecords,
  });

  factory UsedOilStatistics.fromJson(Map<String, dynamic> json) {
    return UsedOilStatistics(
      totalUsedOilIn: double.tryParse(json['total_used_oil_in'].toString()) ?? 0.0,
      totalUsedOilOut: double.tryParse(json['total_used_oil_out'].toString()) ?? 0.0,
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      totalRecords: json['total_records'] as int? ?? 0,
    );
  }
}
