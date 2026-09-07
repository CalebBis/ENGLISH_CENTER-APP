class Enrollment {
  final String id;
  final String studentId;
  final String classId;
  final DateTime enrollmentDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Enrollment({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.enrollmentDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'classId': classId,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Enrollment.fromMap(Map<String, dynamic> map) {
    return Enrollment(
      id: map['id'],
      studentId: map['studentId'],
      classId: map['classId'],
      enrollmentDate: DateTime.parse(map['enrollmentDate']),
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
