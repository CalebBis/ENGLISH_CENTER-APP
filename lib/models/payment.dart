class Payment {
  final String id;
  final String studentId;
  final String periodMonth; // 'YYYY-MM' or 'ONESHOT'
  final String feeType; // 'monthly' or 'inscription'
  final double amount;
  final String status; // 'paid' | 'unpaid'
  final DateTime paymentDate;
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.studentId,
    required this.periodMonth,
    required this.feeType,
    required this.amount,
    required this.status,
    required this.paymentDate,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => status == 'paid';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'periodMonth': periodMonth,
      'feeType': feeType,
      'amount': amount,
      'status': status,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      studentId: map['studentId'],
      periodMonth: map['periodMonth'] ?? '',
      feeType: map['feeType'] ?? 'monthly',
      amount: (map['amount'] as num).toDouble(),
      status: map['status'],
      paymentDate: DateTime.parse(map['paymentDate']),
      paymentMethod: map['paymentMethod'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Payment copyWith({
    String? id,
    String? studentId,
    String? periodMonth,
    String? feeType,
    double? amount,
    String? status,
    DateTime? paymentDate,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      periodMonth: periodMonth ?? this.periodMonth,
      feeType: feeType ?? this.feeType,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
