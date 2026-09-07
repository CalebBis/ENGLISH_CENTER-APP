import 'english_class.dart';

class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String postName;
  final String email;
  final String phone;
  final String currentLevel;
  final String? photoUrl;
  final String? placeOfBirth;
  final DateTime? dateOfBirth;
  final String? address;
  final String? guardianFirstName;
  final String? guardianLastName;
  final String? guardianPhone;
  final DateTime enrollmentDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EnglishClass? englishClass;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.postName = '',
    required this.email,
    required this.phone,
    required this.currentLevel,
    this.photoUrl,
    this.placeOfBirth,
    this.dateOfBirth,
    this.address,
    this.guardianFirstName,
    this.guardianLastName,
    this.guardianPhone,
    required this.enrollmentDate,
    required this.createdAt,
    required this.updatedAt,
    this.englishClass,
  });

  String get fullName {
    if (postName.isEmpty) return '$lastName $firstName';
    return '$lastName $postName $firstName';
  }

  Student copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? postName,
    String? email,
    String? phone,
    String? currentLevel,
    String? photoUrl,
    String? placeOfBirth,
    DateTime? dateOfBirth,
    String? address,
    String? guardianFirstName,
    String? guardianLastName,
    String? guardianPhone,
    DateTime? enrollmentDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    EnglishClass? englishClass,
  }) {
    return Student(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      postName: postName ?? this.postName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      currentLevel: currentLevel ?? this.currentLevel,
      photoUrl: photoUrl ?? this.photoUrl,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      guardianFirstName: guardianFirstName ?? this.guardianFirstName,
      guardianLastName: guardianLastName ?? this.guardianLastName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      englishClass: englishClass ?? this.englishClass,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'postName': postName,
      'email': email,
      'phone': phone,
      'currentLevel': currentLevel,
      'photoUrl': photoUrl,
      'placeOfBirth': placeOfBirth,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'guardianFirstName': guardianFirstName,
      'guardianLastName': guardianLastName,
      'guardianPhone': guardianPhone,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map, {EnglishClass? englishClass}) {
    return Student(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      postName: map['postName'] ?? '',
      email: map['email'],
      phone: map['phone'],
      currentLevel: map['currentLevel'],
      photoUrl: map['photoUrl'],
      placeOfBirth: map['placeOfBirth'],
      dateOfBirth: map['dateOfBirth'] != null ? DateTime.tryParse(map['dateOfBirth']) : null,
      address: map['address'],
      guardianFirstName: map['guardianFirstName'],
      guardianLastName: map['guardianLastName'],
      guardianPhone: map['guardianPhone'],
      enrollmentDate: DateTime.parse(map['enrollmentDate']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      englishClass: englishClass,
    );
  }
}
