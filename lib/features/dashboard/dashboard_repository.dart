import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/database_service.dart';

class DashboardStats {
  final int totalStudents;
  final int activeStudents;
  final int totalTeachers;
  final int totalClasses;
  final double monthlyRevenue;
  final double annualRevenue;
  final int totalPayments;
  final double attendanceRate;

  DashboardStats({
    required this.totalStudents,
    required this.activeStudents,
    required this.totalTeachers,
    required this.totalClasses,
    required this.monthlyRevenue,
    required this.annualRevenue,
    required this.totalPayments,
    required this.attendanceRate,
  });
}

class DashboardRepository {
  Future<Database> get _db async => await DatabaseService.instance.database;

  Future<DashboardStats> getStats() async {
    final db = await _db;

    final totalStudentsResult = await db.rawQuery('SELECT COUNT(*) as count FROM students');
    final int totalStudents = (totalStudentsResult.first['count'] as num?)?.toInt() ?? 0;

    final activeStudentsResult = await db.rawQuery('SELECT COUNT(*) as count FROM students WHERE status = ?', ['Actif']);
    final int activeStudents = (activeStudentsResult.first['count'] as num?)?.toInt() ?? 0;

    final totalTeachersResult = await db.rawQuery('SELECT COUNT(*) as count FROM teachers');
    final int totalTeachers = (totalTeachersResult.first['count'] as num?)?.toInt() ?? 0;

    final totalClassesResult = await db.rawQuery('SELECT COUNT(*) as count FROM classes');
    final int totalClasses = (totalClassesResult.first['count'] as num?)?.toInt() ?? 0;

    final monthlyRevenueResult = await db.rawQuery("SELECT SUM(amount) as total FROM payments WHERE strftime('%Y-%m', payment_date) = strftime('%Y-%m', 'now')");
    final double monthlyRevenue = (monthlyRevenueResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final annualRevenueResult = await db.rawQuery("SELECT SUM(amount) as total FROM payments WHERE strftime('%Y', payment_date) = strftime('%Y', 'now')");
    final double annualRevenue = (annualRevenueResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final totalPaymentsResult = await db.rawQuery('SELECT COUNT(*) as count FROM payments');
    final int totalPayments = (totalPaymentsResult.first['count'] as num?)?.toInt() ?? 0;

    // Fake attendance rate if no data
    final attendanceResult = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN status = 'Présent' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as rate 
      FROM attendance
    ''');
    final double attendanceRate = (attendanceResult.first['rate'] as num?)?.toDouble() ?? 100.0;

    return DashboardStats(
      totalStudents: totalStudents,
      activeStudents: activeStudents,
      totalTeachers: totalTeachers,
      totalClasses: totalClasses,
      monthlyRevenue: monthlyRevenue,
      annualRevenue: annualRevenue,
      totalPayments: totalPayments,
      attendanceRate: attendanceRate,
    );
  }
}
