class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String currentLevel;
  final DateTime enrollmentDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.currentLevel,
    required this.enrollmentDate,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'currentLevel': currentLevel,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      phone: map['phone'],
      currentLevel: map['currentLevel'],
      enrollmentDate: DateTime.parse(map['enrollmentDate']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
