import 'package:flutter/material.dart';

class DashboardProvider extends ChangeNotifier {
  int _totalStudents = 120;
  int _newStudentsThisMonth = 18;
  double _attendanceRate = 86.0;
  int _unpaidCount = 12;
  bool _isLoading = false;

  int get totalStudents => _totalStudents;
  int get newStudentsThisMonth => _newStudentsThisMonth;
  double get attendanceRate => _attendanceRate;
  int get unpaidCount => _unpaidCount;
  bool get isLoading => _isLoading;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
