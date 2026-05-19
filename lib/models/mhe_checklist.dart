class EquipmentType {
  final String id;
  final String name;
  final String icon;

  EquipmentType({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory EquipmentType.fromJson(Map<String, dynamic> json) {
    return EquipmentType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}

class WeekData {
  bool ttdOperator;
  bool ttdLeader;

  WeekData({
    this.ttdOperator = false,
    this.ttdLeader = false,
  });

  factory WeekData.fromJson(Map<String, dynamic> json) {
    return WeekData(
      ttdOperator: json['ttd_operator'] == true || json['ttd_operator'] == 1,
      ttdLeader: json['ttd_leader'] == true || json['ttd_leader'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ttd_operator': ttdOperator,
      'ttd_leader': ttdLeader,
    };
  }
}

class MheChecklistTask {
  final String taskDescription;
  final Map<int, WeekData> weeks; // 1-5
  String notes;

  MheChecklistTask({
    required this.taskDescription,
    required this.weeks,
    this.notes = '',
  });

  factory MheChecklistTask.fromJson(Map<String, dynamic> json) {
    Map<int, WeekData> weeksMap = {};

    if (json['weeks'] != null) {
      (json['weeks'] as Map<String, dynamic>).forEach((key, value) {
        int weekNum = int.parse(key.toString());
        if (value is Map<String, dynamic>) {
          weeksMap[weekNum] = WeekData.fromJson(value);
        }
      });
    }

    return MheChecklistTask(
      taskDescription: json['task_description']?.toString() ?? '',
      weeks: weeksMap,
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> weeksJson = {};
    weeks.forEach((key, value) {
      weeksJson[key.toString()] = value.toJson();
    });

    return {
      'task_description': taskDescription,
      'weeks': weeksJson,
      'notes': notes,
    };
  }
}

class MheChecklistTable {
  final int id;
  final String equipmentName;
  final int warehouseId;
  List<MheChecklistTask> tasks;

  MheChecklistTable({
    required this.id,
    required this.equipmentName,
    required this.warehouseId,
    required this.tasks,
  });

  factory MheChecklistTable.fromJson(Map<String, dynamic> json) {
    List<MheChecklistTask> tasksList = [];

    if (json['checklist_data'] != null && json['checklist_data'] is List) {
      tasksList = (json['checklist_data'] as List)
          .map((item) => MheChecklistTask.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return MheChecklistTable(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      equipmentName: json['equipment_name']?.toString() ?? '',
      warehouseId: json['warehouse_id'] is int ? json['warehouse_id'] as int : int.tryParse(json['warehouse_id'].toString()) ?? 0,
      tasks: tasksList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipment_name': equipmentName,
      'warehouse_id': warehouseId,
      'checklist_data': tasks.map((task) => task.toJson()).toList(),
    };
  }
}
