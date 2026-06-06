class TeacherModel {
  final int? id;
  final String lastName;
  final String postname;
  final String firstname;
  final String gender;
  final String pob;
  final String dob;
  final String phone;
  final String? address;
  final String? email;
  final String? nationality;
  final String specialty;
  final String? teachingLevel;
  final String? photoPath;
  final String status;
  final String hireDate;

  TeacherModel({
    this.id,
    required this.lastName,
    required this.postname,
    required this.firstname,
    required this.gender,
    required this.pob,
    required this.dob,
    required this.phone,
    this.address,
    this.email,
    this.nationality,
    required this.specialty,
    this.teachingLevel,
    this.photoPath,
    required this.status,
    required this.hireDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'last_name': lastName,
      'postname': postname,
      'firstname': firstname,
      'gender': gender,
      'pob': pob,
      'dob': dob,
      'phone': phone,
      'address': address,
      'email': email,
      'nationality': nationality,
      'specialty': specialty,
      'teaching_level': teachingLevel,
      'photo_path': photoPath,
      'status': status,
      'hire_date': hireDate,
    };
  }

  factory TeacherModel.fromMap(Map<String, dynamic> map) {
    return TeacherModel(
      id: map['id'],
      lastName: map['last_name'],
      postname: map['postname'],
      firstname: map['firstname'],
      gender: map['gender'],
      pob: map['pob'],
      dob: map['dob'],
      phone: map['phone'],
      address: map['address'],
      email: map['email'],
      nationality: map['nationality'],
      specialty: map['specialty'],
      teachingLevel: map['teaching_level'],
      photoPath: map['photo_path'],
      status: map['status'],
      hireDate: map['hire_date'],
    );
  }
}
