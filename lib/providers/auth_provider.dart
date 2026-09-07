import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _currentUserId;
  String? _currentUserRole;
  bool _isAuthenticated = false;

  String? get currentUserId => _currentUserId;
  String? get currentUserRole => _currentUserRole;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String username, String password) async {
    try {
      if (username == 'admin' && password == 'admin') {
        _currentUserId = 'admin-001';
        _currentUserRole = 'admin';
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _currentUserId = null;
    _currentUserRole = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
