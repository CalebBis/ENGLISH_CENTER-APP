import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/database_service.dart';
import '../../core/models/class_model.dart';
import '../../core/models/student_model.dart';
import '../../core/models/teacher_model.dart';

class ClassRepository {
  Future<Database> get _db async => await DatabaseService.instance.database;

  Future<int> insertClass(ClassModel classModel) async {
    final db = await _db;
    return await db.insert('classes', classModel.toMap());
  }

  Future<int> updateClass(ClassModel classModel) async {
    final db = await _db;
    return await db.update(
      'classes',
      classModel.toMap(),
      where: 'id = ?',
      whereArgs: [classModel.id],
    );
  }

  Future<int> deleteClass(int id) async {
    final db = await _db;
    return await db.delete(
      'classes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ClassModel>> getAllClasses() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('classes');
    return maps.map((map) => ClassModel.fromMap(map)).toList();
  }

  Future<List<LevelModel>> getAllLevels() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('levels');
    return maps.map((map) => LevelModel.fromMap(map)).toList();
  }

  // Enrollment Logic
  Future<void> enrollStudent(int studentId, int classId, String date) async {
    final db = await _db;
    await db.insert('enrollments', {
      'student_id': studentId,
      'class_id': classId,
      'enroll_date': date,
    });
  }

  Future<void> removeStudentFromClass(int studentId, int classId) async {
    final db = await _db;
    await db.delete(
      'enrollments',
      where: 'student_id = ? AND class_id = ?',
      whereArgs: [studentId, classId],
    );
  }

  Future<List<StudentModel>> getStudentsByClass(int classId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.* FROM students s
      INNER JOIN enrollments e ON s.id = e.student_id
      WHERE e.class_id = ?
    ''', [classId]);
    return maps.map((map) => StudentModel.fromMap(map)).toList();
  }

  Future<TeacherModel?> getTeacherByClass(int teacherId) async {
    final db = await _db;
    final maps = await db.query('teachers', where: 'id = ?', whereArgs: [teacherId]);
    if (maps.isNotEmpty) {
      return TeacherModel.fromMap(maps.first);
    }
    return null;
  }
}
