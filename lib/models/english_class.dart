class EnglishClass {
  final String id;
  final String name;
  final String level;
  final String teacherId;
  final int maxCapacity;
  final int currentEnrollment;
  final String schedule;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;

  EnglishClass({
    required this.id,
    required this.name,
    required this.level,
    required this.teacherId,
    required this.maxCapacity,
    this.currentEnrollment = 0,
    required this.schedule,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
  });

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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EnglishClass.fromMap(Map<String, dynamic> map) {
    return EnglishClass(
      id: map['id'],
      name: map['name'],
      level: map['level'],
      teacherId: map['teacherId'],
      maxCapacity: map['maxCapacity'],
      currentEnrollment: map['currentEnrollment'],
      schedule: map['schedule'],
      location: map['location'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
