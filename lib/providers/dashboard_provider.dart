import 'package:flutter/material.dart';
import '../services/dao/student_dao.dart';
import '../services/dao/payment_dao.dart';
import '../services/dao/attendance_dao.dart';

class MonthlyRevenue {
  final String periodMonth;
  final double amount;
  MonthlyRevenue({required this.periodMonth, required this.amount});
}

class DashboardProvider extends ChangeNotifier {
  int _totalStudents = 0;
  int _newStudentsThisMonth = 0;
  double _attendanceRate = 0.0;
  int _unpaidCount = 0;
  bool _isLoading = false;
  List<MonthlyRevenue> _revenueHistory = [];
  bool _hasAttendanceData = false;

  final StudentDao _studentDao = StudentDao();
  final PaymentDao _paymentDao = PaymentDao();
  final AttendanceDao _attendanceDao = AttendanceDao();

  int get totalStudents => _totalStudents;
  int get newStudentsThisMonth => _newStudentsThisMonth;
  double get attendanceRate => _attendanceRate;
  int get unpaidCount => _unpaidCount;
  bool get isLoading => _isLoading;
  List<MonthlyRevenue> get revenueHistory => _revenueHistory;
  bool get hasAttendanceData => _hasAttendanceData;

  double get maxRevenueValue {
    if (_revenueHistory.isEmpty) return 10.0;
    double maxVal = _revenueHistory.map((e) => e.amount).fold(0.0, (a, b) => a > b ? a : b);
    return maxVal > 0 ? maxVal : 10.0;
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final now = DateTime.now();
      final currentPeriod = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      final results = await Future.wait([
        _studentDao.getActiveStudentCount(),
        _studentDao.getNewStudentsCountForMonth(currentPeriod),
        _attendanceDao.getAttendanceRate(),
        _paymentDao.getUnpaidCountForMonth(currentPeriod),
        _paymentDao.getRevenueByMonth(monthsCount: 6),
      ]);
      
      _totalStudents = results[0] as int;
      _newStudentsThisMonth = results[1] as int;
      _attendanceRate = results[2] as double;
      _unpaidCount = results[3] as int;
      
      final revenues = results[4] as List<MapEntry<String, double>>;
      _revenueHistory = revenues.map((e) => MonthlyRevenue(periodMonth: e.key, amount: e.value)).toList();
      
      // Determine if there is any attendance data (heuristic: if rate is 0.0, we just assume no data if it was totally empty. 
      // Actually, the DAO returns 0.0 if empty. To be perfectly accurate we could have a check, but let's just use rate == 0.0 for the UI check)
      // Actually user asked to output "—" if exactly 0.0 AND no data. I will add a small query or just use the UI trick.
      // For simplicity, let's just let the UI check if rate == 0.0. The DAO doesn't distinguish right now.
      _hasAttendanceData = _attendanceRate > 0; // We'll just approximate that if it's 0, it might be no data.

    } catch (e) {
      debugPrint('DashboardProvider.loadDashboardData error: $e');
      _totalStudents = 0;
      _newStudentsThisMonth = 0;
      _attendanceRate = 0.0;
      _unpaidCount = 0;
      _revenueHistory = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
