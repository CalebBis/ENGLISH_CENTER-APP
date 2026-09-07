class Teacher {
  final String id;
  final String firstName;
  final String lastName;
  final String postName;
  final String email;
  final String phone;
  final List<String> specializations;
  final DateTime? dateOfBirth;
  final String? placeOfBirth;
  final String? address;
  final String? photoUrl;
  final String? biography;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Teacher({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.postName = '',
    required this.email,
    required this.phone,
    required this.specializations,
    this.dateOfBirth,
    this.placeOfBirth,
    this.address,
    this.photoUrl,
    this.biography,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Nom complet : Nom Postnom Prénom
  String get fullName {
    final parts = [lastName, if (postName.isNotEmpty) postName, firstName];
    return parts.join(' ');
  }

  Teacher copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? postName,
    String? email,
    String? phone,
    List<String>? specializations,
    DateTime? dateOfBirth,
    String? placeOfBirth,
    String? address,
    String? photoUrl,
    String? biography,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Teacher(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      postName: postName ?? this.postName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specializations: specializations ?? this.specializations,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      biography: biography ?? this.biography,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'specializations': specializations.join(','),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'placeOfBirth': placeOfBirth,
      'address': address,
      'photoUrl': photoUrl,
      'biography': biography,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      postName: (map['postName'] as String?) ?? '',
      email: map['email'] as String,
      phone: map['phone'] as String,
      specializations: (map['specializations'] as String).isNotEmpty
          ? (map['specializations'] as String).split(',')
          : [],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'] as String)
          : null,
      placeOfBirth: map['placeOfBirth'] as String?,
      address: map['address'] as String?,
      photoUrl: map['photoUrl'] as String?,
      biography: map['biography'] as String?,
      isActive: (map['isActive'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

