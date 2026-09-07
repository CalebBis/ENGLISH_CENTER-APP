import 'package:flutter/material.dart';

class PaymentProvider extends ChangeNotifier {
  double _totalRevenue = 1250.0;
  int _unpaidCount = 12;
  bool _isLoading = false;

  double get totalRevenue => _totalRevenue;
  int get unpaidCount => _unpaidCount;
  bool get isLoading => _isLoading;

  Future<void> loadPaymentStats() async {
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
