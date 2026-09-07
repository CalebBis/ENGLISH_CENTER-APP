import 'package:flutter/material.dart';

class StudentProvider extends ChangeNotifier {
  List<dynamic> _students = [];
  bool _isLoading = false;

  List<dynamic> get students => _students;
  bool get isLoading => _isLoading;

  Future<void> loadStudents() async {
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
