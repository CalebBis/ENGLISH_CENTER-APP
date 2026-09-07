import 'package:flutter/material.dart';

class ClassProvider extends ChangeNotifier {
  List<dynamic> _classes = [];
  bool _isLoading = false;

  List<dynamic> get classes => _classes;
  bool get isLoading => _isLoading;

  Future<void> loadClasses() async {
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
