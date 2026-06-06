class StudentModel {
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
  final String? photoPath;
  final String? contactPerson;
  final String? emergencyPhone;
  final String status;
  final String enrollDate;
  final int? currentLevelId;

  StudentModel({
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
    this.photoPath,
    this.contactPerson,
    this.emergencyPhone,
    required this.status,
    required this.enrollDate,
    this.currentLevelId,
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
      'photo_path': photoPath,
      'contact_person': contactPerson,
      'emergency_phone': emergencyPhone,
      'status': status,
      'enroll_date': enrollDate,
      'current_level_id': currentLevelId,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
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
      photoPath: map['photo_path'],
      contactPerson: map['contact_person'],
      emergencyPhone: map['emergency_phone'],
      status: map['status'],
      enrollDate: map['enroll_date'],
      currentLevelId: map['current_level_id'],
    );
  }
}
