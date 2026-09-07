import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/dao/student_dao.dart';

class StudentProvider extends ChangeNotifier {
  final StudentDao _studentDao = StudentDao();

  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = false;

  List<Student> get students => _filteredStudents;
  bool get isLoading => _isLoading;

  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allStudents = await _studentDao.getAllStudents();
      _filteredStudents = List.from(_allStudents);
    } catch (e) {
      debugPrint('Error loading students: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchStudents(String query, String? classId) {
    _filteredStudents = _allStudents.where((student) {
      final matchesQuery = query.isEmpty ||
          student.fullName.toLowerCase().contains(query.toLowerCase()) ||
          student.phone.toLowerCase().contains(query.toLowerCase());
          
      final matchesClass = classId == null || classId.isEmpty || 
          (student.englishClass != null && student.englishClass!.id == classId);

      return matchesQuery && matchesClass;
    }).toList();
    notifyListeners();
  }

  Future<void> addStudent(Student student, String? classId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _studentDao.insertStudent(student, classId);
      await loadStudents();
    } catch (e) {
      debugPrint('Error adding student: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStudent(Student student, String? newClassId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _studentDao.updateStudent(student, newClassId);
      await loadStudents();
    } catch (e) {
      debugPrint('Error updating student: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteStudent(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _studentDao.deleteStudent(id);
      await loadStudents();
    } catch (e) {
      debugPrint('Error deleting student: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
