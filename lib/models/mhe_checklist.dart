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
  final int week;
  bool ttdOperator;
  bool ttdLeader;
  String notes;

  WeekData({
    required this.week,
    this.ttdOperator = false,
    this.ttdLeader = false,
    this.notes = '',
  });

  factory WeekData.fromJson(Map<String, dynamic> json) {
    return WeekData(
      week: json['week'] is int ? json['week'] as int : int.tryParse(json['week'].toString()) ?? 0,
      ttdOperator: json['ttd_operator'] == true || json['ttd_operator'] == 1,
      ttdLeader: json['ttd_leader'] == true || json['ttd_leader'] == 1,
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ttd_operator': ttdOperator,
      'ttd_leader': ttdLeader,
      'notes': notes,
    };
  }
}

class TaskChecklist {
  final int taskIndex;
  final String taskDescription;
  final Map<int, WeekData> weeks;

  TaskChecklist({
    required this.taskIndex,
    required this.taskDescription,
    required this.weeks,
  });

  factory TaskChecklist.fromJson(Map<String, dynamic> json) {
    Map<int, WeekData> weeksMap = {};
    
    if (json['weeks'] != null) {
      (json['weeks'] as Map<String, dynamic>).forEach((key, value) {
        // Handle both string and int keys
        int weekNum;
        if (key is int) {
          weekNum = key as int;
        } else {
          weekNum = int.parse(key.toString());
        }
        
        // Ensure value is a Map
        if (value is Map<String, dynamic>) {
          weeksMap[weekNum] = WeekData.fromJson(value);
        }
      });
    }

    return TaskChecklist(
      taskIndex: json['task_index'] is int ? json['task_index'] as int : int.tryParse(json['task_index'].toString()) ?? 0,
      taskDescription: json['task_description']?.toString() ?? '',
      weeks: weeksMap,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> weeksJson = {};
    weeks.forEach((key, value) {
      weeksJson[key.toString()] = value.toJson();
    });

    return {
      'task_index': taskIndex,
      'task_description': taskDescription,
      'weeks': weeksJson,
    };
  }
}

class MheChecklistData {
  final String equipmentType;
  final int month;
  final int year;
  final List<TaskChecklist> checklist;

  MheChecklistData({
    required this.equipmentType,
    required this.month,
    required this.year,
    required this.checklist,
  });

  factory MheChecklistData.fromJson(Map<String, dynamic> json) {
    List<TaskChecklist> checklistItems = [];
    
    if (json['checklist'] != null && json['checklist'] is List) {
      checklistItems = (json['checklist'] as List)
          .map((item) => TaskChecklist.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return MheChecklistData(
      equipmentType: json['equipment_type']?.toString() ?? '',
      month: json['month'] is int ? json['month'] as int : int.tryParse(json['month'].toString()) ?? 0,
      year: json['year'] is int ? json['year'] as int : int.tryParse(json['year'].toString()) ?? 0,
      checklist: checklistItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'equipment_type': equipmentType,
      'month': month,
      'year': year,
      'checklist': checklist.map((item) => item.toJson()).toList(),
    };
  }
}
