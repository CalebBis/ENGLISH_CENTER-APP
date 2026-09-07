class Payment {
  final String id;
  final String studentId;
  final double amount;
  final String status;
  final DateTime paymentDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.status,
    required this.paymentDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'amount': amount,
      'status': status,
      'paymentDate': paymentDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      studentId: map['studentId'],
      amount: map['amount'].toDouble(),
      status: map['status'],
      paymentDate: DateTime.parse(map['paymentDate']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
