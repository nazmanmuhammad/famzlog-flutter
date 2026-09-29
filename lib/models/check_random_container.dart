class CheckRandomContainer {
  final int id;
  final int warehouseId;
  final String operatorName;
  final int containerCount;
  final int koliCount;
  final String date;
  final CheckRandomContainerWarehouse? warehouse;

  CheckRandomContainer({
    required this.id,
    required this.warehouseId,
    required this.operatorName,
    required this.containerCount,
    required this.koliCount,
    required this.date,
    this.warehouse,
  });

  factory CheckRandomContainer.fromJson(Map<String, dynamic> json) {
    return CheckRandomContainer(
      id: json['id'] as int,
      warehouseId: (json['warehouse_id'] ?? 0) as int,
      operatorName: json['operator_name'] as String? ?? '',
      containerCount: (json['container_count'] ?? 0) is int
          ? json['container_count'] as int
          : int.tryParse(json['container_count'].toString()) ?? 0,
      koliCount: (json['koli_count'] ?? 0) is int
          ? json['koli_count'] as int
          : int.tryParse(json['koli_count'].toString()) ?? 0,
      date: json['date'] as String? ?? '',
      warehouse: json['warehouse'] != null
          ? CheckRandomContainerWarehouse.fromJson(json['warehouse'])
          : null,
    );
  }
}

class CheckRandomContainerWarehouse {
  final int id;
  final String name;

  CheckRandomContainerWarehouse({required this.id, required this.name});

  factory CheckRandomContainerWarehouse.fromJson(Map<String, dynamic> json) {
    return CheckRandomContainerWarehouse(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class CheckRandomContainerStatistics {
  final int totalContainers;
  final int totalKoli;
  final int totalRecords;

  CheckRandomContainerStatistics({
    required this.totalContainers,
    required this.totalKoli,
    required this.totalRecords,
  });

  factory CheckRandomContainerStatistics.fromJson(Map<String, dynamic> json) {
    int _parse(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return CheckRandomContainerStatistics(
      totalContainers: _parse(json['total_containers']),
      totalKoli: _parse(json['total_koli']),
      totalRecords: _parse(json['total_records']),
    );
  }
}
