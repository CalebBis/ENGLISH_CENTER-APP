import 'teacher.dart';

class EnglishClass {
  final String id;
  final String name;
  final String level;
  final String teacherId;
  final int maxCapacity;
  final int currentEnrollment;
  final String schedule;
  final String location;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relation properties populated by DAO
  final Teacher? teacher;

  EnglishClass({
    required this.id,
    required this.name,
    required this.level,
    required this.teacherId,
    required this.maxCapacity,
    this.currentEnrollment = 0,
    required this.schedule,
    required this.location,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.teacher,
  });

  bool get isUnlimited => maxCapacity == 0;
  bool get isFull => !isUnlimited && currentEnrollment >= maxCapacity;
  int get remainingSeats => isUnlimited ? -1 : (maxCapacity - currentEnrollment);

  EnglishClass copyWith({
    String? id,
    String? name,
    String? level,
    String? teacherId,
    int? maxCapacity,
    int? currentEnrollment,
    String? schedule,
    String? location,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Teacher? teacher,
  }) {
    return EnglishClass(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      teacherId: teacherId ?? this.teacherId,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      currentEnrollment: currentEnrollment ?? this.currentEnrollment,
      schedule: schedule ?? this.schedule,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      teacher: teacher ?? this.teacher,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'teacherId': teacherId,
      'maxCapacity': maxCapacity,
      'currentEnrollment': currentEnrollment,
      'schedule': schedule,
      'location': location,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EnglishClass.fromMap(Map<String, dynamic> map, {Teacher? teacher}) {
    return EnglishClass(
      id: map['id'] as String,
      name: map['name'] as String,
      level: map['level'] as String,
      teacherId: map['teacherId'] as String,
      maxCapacity: map['maxCapacity'] as int,
      currentEnrollment: map['currentEnrollment'] as int? ?? 0,
      schedule: map['schedule'] as String,
      location: map['location'] as String,
      isActive: (map['isActive'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      teacher: teacher,
    );
  }
}

