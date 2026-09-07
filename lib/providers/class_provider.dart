import 'package:flutter/material.dart';
import '../models/english_class.dart';
import '../services/dao/class_dao.dart';

class ClassProvider extends ChangeNotifier {
  final ClassDao _classDao = ClassDao();
  
  List<EnglishClass> _classes = [];
  List<EnglishClass> _filteredClasses = [];
  
  bool _isLoading = false;
  String _searchQuery = '';

  List<EnglishClass> get classes => _filteredClasses.isEmpty && _searchQuery.isEmpty ? _classes : _filteredClasses;
  bool get isLoading => _isLoading;

  Future<void> loadClasses() async {
    _isLoading = true;
    notifyListeners();
    try {
      _classes = await _classDao.getAllClasses();
      _filterClasses();
    } catch (e) {
      debugPrint('Error loading classes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _filterClasses();
    notifyListeners();
  }

  void _filterClasses() {
    if (_searchQuery.isEmpty) {
      _filteredClasses = _classes;
    } else {
      _filteredClasses = _classes.where((c) {
        final nameMatches = c.name.toLowerCase().contains(_searchQuery);
        final teacherMatches = c.teacher != null && c.teacher!.fullName.toLowerCase().contains(_searchQuery);
        return nameMatches || teacherMatches;
      }).toList();
    }
  }

  Future<void> addClass(EnglishClass newClass) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _classDao.insertClass(newClass);
      await loadClasses();
    } catch (e) {
      debugPrint('Error adding class: $e');
      rethrow;
    }
  }

  Future<void> updateClass(EnglishClass updatedClass) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _classDao.updateClass(updatedClass);
      await loadClasses();
    } catch (e) {
      debugPrint('Error updating class: $e');
      rethrow;
    }
  }

  Future<void> deleteClass(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _classDao.deleteClass(id);
      await loadClasses();
    } catch (e) {
      debugPrint('Error deleting class: $e');
      rethrow;
    }
  }

  Future<void> enrollStudent(String classId, String studentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _classDao.enrollStudent(classId, studentId);
      await loadClasses();
    } catch (e) {
      debugPrint('Error enrolling student: $e');
      rethrow;
    }
  }
  
  Future<void> unenrollStudent(String classId, String studentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _classDao.unenrollStudent(classId, studentId);
      await loadClasses();
    } catch (e) {
      debugPrint('Error unenrolling student: $e');
      rethrow;
    }
  }
}

