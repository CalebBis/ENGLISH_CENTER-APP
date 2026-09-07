import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/dao/teacher_dao.dart';

class TeacherProvider extends ChangeNotifier {
  final _dao = TeacherDAO();

  List<Teacher> _teachers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Teacher> get teachers => _filtered;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<Teacher> get _filtered {
    if (_searchQuery.isEmpty) return List.unmodifiable(_teachers);
    final q = _searchQuery.toLowerCase();
    return _teachers.where((t) {
      return t.fullName.toLowerCase().contains(q) ||
          t.phone.contains(q) ||
          t.email.toLowerCase().contains(q) ||
          (t.placeOfBirth?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadTeachers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _teachers = await _dao.getAllTeachers();
    } catch (e) {
      debugPrint('TeacherProvider.loadTeachers error: \$e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTeacher(Teacher teacher) async {
    await _dao.insertTeacher(teacher);
    await loadTeachers();
  }

  Future<void> updateTeacher(Teacher teacher) async {
    await _dao.updateTeacher(teacher);
    await loadTeachers();
  }

  Future<void> deleteTeacher(String id) async {
    await _dao.deleteTeacher(id);
    await loadTeachers();
  }
}

