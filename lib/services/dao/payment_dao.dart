import 'package:sqflite/sqflite.dart';
import '../../models/payment.dart';
import '../database_helper.dart';

class PaymentDao {
  static const _table = 'payments';

  // -----------------------------------------------------------------------
  // Ensure every enrolled student has a payment record for the given month.
  // -----------------------------------------------------------------------
  Future<void> ensureInvoicesForMonth(String periodMonth, double monthlyFee) async {
    final db = await DatabaseHelper.instance.database;

    // All active students
    final students = await db.query('students');

    for (final s in students) {
      final studentId = s['id'] as String;

      // Check if invoice already exists
      final existing = await db.query(
        _table,
        where: 'studentId = ? AND periodMonth = ?',
        whereArgs: [studentId, periodMonth],
        limit: 1,
      );

      if (existing.isEmpty) {
        final now = DateTime.now();
        await db.insert(
          _table,
          {
            'id': '${studentId}_$periodMonth',
            'studentId': studentId,
            'periodMonth': periodMonth,
            'feeType': 'monthly',
            'amount': monthlyFee,
            'status': 'unpaid',
            'paymentDate': now.toIso8601String(),
            'paymentMethod': null,
            'notes': null,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  // -----------------------------------------------------------------------
  // Get payments + student info for a given month (for the list screen).
  // -----------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getPaymentsForMonth(String periodMonth) async {
    final db = await DatabaseHelper.instance.database;
    return db.rawQuery('''
      SELECT p.*, s.firstName, s.lastName, s.postName, s.phone, s.photoUrl, s.currentLevel
      FROM payments p
      INNER JOIN students s ON p.studentId = s.id
      WHERE p.periodMonth = ?
      ORDER BY s.lastName ASC
    ''', [periodMonth]);
  }

  // -----------------------------------------------------------------------
  // Get calendar month revenue based on paymentDate
  // -----------------------------------------------------------------------
  Future<double> getRevenueForCalendarMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final monthStr = month.toString().padLeft(2, '0');
    final queryStr = '$year-$monthStr';
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM payments
      WHERE status = 'paid' AND strftime('%Y-%m', paymentDate) = ?
    ''', [queryStr]);
    
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // -----------------------------------------------------------------------
  // Get all inscription payments
  // -----------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllInscriptionPayments() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(_table, where: 'feeType = ?', whereArgs: ['inscription']);
  }

  // -----------------------------------------------------------------------
  // Get all payments for a given student.
  // -----------------------------------------------------------------------
  Future<List<Payment>> getPaymentsForStudent(String studentId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      _table,
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'periodMonth DESC',
    );
    return rows.map(Payment.fromMap).toList();
  }

  // -----------------------------------------------------------------------
  // Mark a payment as paid.
  // -----------------------------------------------------------------------
  Future<Payment> markAsPaid(
    String paymentId, {
    String? paymentMethod,
    String? notes,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    await db.update(
      _table,
      {
        'status': 'paid',
        'paymentDate': now.toIso8601String(),
        'paymentMethod': paymentMethod,
        'notes': notes,
        'updatedAt': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [paymentId],
    );
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [paymentId]);
    return Payment.fromMap(rows.first);
  }

  // -----------------------------------------------------------------------
  // Revert a payment to unpaid.
  // -----------------------------------------------------------------------
  Future<void> markAsUnpaid(String paymentId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      _table,
      {
        'status': 'unpaid',
        'paymentMethod': null,
        'notes': null,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }
  // -----------------------------------------------------------------------
  // Create an inscription payment (One-shot)
  // -----------------------------------------------------------------------
  Future<Payment> createInscriptionPayment(String studentId, double amount, {String? paymentMethod}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final paymentId = '${studentId}_inscription';
    
    try {
      await db.insert(
        _table,
        {
          'id': paymentId,
          'studentId': studentId,
          'periodMonth': 'ONESHOT',
          'feeType': 'inscription',
          'amount': amount,
          'status': 'paid',
          'paymentDate': now.toIso8601String(),
          'paymentMethod': paymentMethod,
          'notes': 'Frais d\'inscription',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
      );
      final rows = await db.query(_table, where: 'id = ?', whereArgs: [paymentId]);
      return Payment.fromMap(rows.first);
    } catch (e) {
      if (e is DatabaseException && e.isUniqueConstraintError()) {
        throw Exception("Frais d'inscription déjà payé");
      }
      rethrow;
    }
  }

  // -----------------------------------------------------------------------
  // Manually create a monthly payment if it doesn't exist, and mark it paid.
  // -----------------------------------------------------------------------
  Future<Payment> createMonthlyPayment(String studentId, String periodMonth, double amount, {String? paymentMethod}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final paymentId = '${studentId}_$periodMonth';
    
    await db.insert(
      _table,
      {
        'id': paymentId,
        'studentId': studentId,
        'periodMonth': periodMonth,
        'feeType': 'monthly',
        'amount': amount,
        'status': 'paid',
        'paymentDate': now.toIso8601String(),
        'paymentMethod': paymentMethod,
        'notes': 'Frais mensuel',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [paymentId]);
    return Payment.fromMap(rows.first);
  }

  // -----------------------------------------------------------------------
  // Get unpaid payments count for a given month.
  // -----------------------------------------------------------------------
  Future<int> getUnpaidCountForMonth(String periodMonth) async {
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM payments WHERE periodMonth = ? AND status = 'unpaid'",
        [periodMonth]
      )
    );
    return count ?? 0;
  }

  // -----------------------------------------------------------------------
  // Get revenue grouped by month for the last X months.
  // -----------------------------------------------------------------------
  Future<List<MapEntry<String, double>>> getRevenueByMonth({int monthsCount = 6}) async {
    final db = await DatabaseHelper.instance.database;
    final List<MapEntry<String, double>> revenues = [];
    final now = DateTime.now();
    
    for (int i = monthsCount - 1; i >= 0; i--) {
      // Calculate the month and year
      var d = DateTime(now.year, now.month - i, 1);
      final periodStr = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      
      final result = await db.rawQuery('''
        SELECT SUM(amount) as total
        FROM payments
        WHERE status = 'paid' AND strftime('%Y-%m', paymentDate) = ?
      ''', [periodStr]);
      
      double total = 0.0;
      if (result.isNotEmpty && result.first['total'] != null) {
        total = (result.first['total'] as num).toDouble();
      }
      
      revenues.add(MapEntry(periodStr, total));
    }
    
    return revenues;
  }
}
