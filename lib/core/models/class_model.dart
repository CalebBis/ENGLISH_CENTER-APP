class ClassModel {
  final int? id;
  final String name;
  final int levelId;
  final int teacherId;
  final String schedule;
  final String room;
  final int maxCapacity;

  ClassModel({
    this.id,
    required this.name,
    required this.levelId,
    required this.teacherId,
    required this.schedule,
    required this.room,
    required this.maxCapacity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level_id': levelId,
      'teacher_id': teacherId,
      'schedule': schedule,
      'room': room,
      'max_capacity': maxCapacity,
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'],
      name: map['name'],
      levelId: map['level_id'],
      teacherId: map['teacher_id'],
      schedule: map['schedule'],
      room: map['room'],
      maxCapacity: map['max_capacity'],
    );
  }
}

class LevelModel {
  final int? id;
  final String name;
  final String? description;
  final int duration;
  final String? objectives;

  LevelModel({
    this.id,
    required this.name,
    this.description,
    required this.duration,
    this.objectives,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'objectives': objectives,
    };
  }

  factory LevelModel.fromMap(Map<String, dynamic> map) {
    return LevelModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      duration: map['duration'],
      objectives: map['objectives'],
    );
  }
}
