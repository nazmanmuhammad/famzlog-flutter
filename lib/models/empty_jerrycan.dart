class EmptyJerrycan {
  final int id;
  final int warehouseId;
  final String tanggal;
  final String jam;
  final String? kodeToko;
  final String namaToko;
  final String nopol;
  final String namaDriver;
  final String? noPo;
  final int jerrycanIn;
  final int jerrycanOut;
  final String? keterangan;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  EmptyJerrycan({
    required this.id,
    required this.warehouseId,
    required this.tanggal,
    required this.jam,
    this.kodeToko,
    required this.namaToko,
    required this.nopol,
    required this.namaDriver,
    this.noPo,
    required this.jerrycanIn,
    required this.jerrycanOut,
    this.keterangan,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory EmptyJerrycan.fromJson(Map<String, dynamic> json) {
    return EmptyJerrycan(
      id: json['id'] as int,
      warehouseId: json['warehouse_id'] as int,
      tanggal: json['tanggal'] as String,
      jam: json['jam'] as String,
      kodeToko: json['kode_toko'] as String?,
      namaToko: json['nama_toko'] as String,
      nopol: json['nopol'] as String,
      namaDriver: json['nama_driver'] as String,
      noPo: json['no_po'] as String?,
      jerrycanIn: int.tryParse(json['jerrycan_in'].toString()) ?? 0,
      jerrycanOut: int.tryParse(json['jerrycan_out'].toString()) ?? 0,
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
      'jerrycan_in': jerrycanIn,
      'jerrycan_out': jerrycanOut,
      'keterangan': keterangan,
    };
  }
}

class EmptyJerrycanStatistics {
  final int totalJerrycanIn;
  final int totalJerrycanOut;
  final int balance;
  final int totalRecords;

  EmptyJerrycanStatistics({
    required this.totalJerrycanIn,
    required this.totalJerrycanOut,
    required this.balance,
    required this.totalRecords,
  });

  factory EmptyJerrycanStatistics.fromJson(Map<String, dynamic> json) {
    return EmptyJerrycanStatistics(
      totalJerrycanIn: int.tryParse(json['total_jerrycan_in']?.toString() ?? '0') ?? 0,
      totalJerrycanOut: int.tryParse(json['total_jerrycan_out']?.toString() ?? '0') ?? 0,
      balance: int.tryParse(json['balance']?.toString() ?? '0') ?? 0,
      totalRecords: int.tryParse(json['total_records']?.toString() ?? '0') ?? 0,
    );
  }
}
