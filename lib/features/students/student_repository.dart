import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/database_service.dart';
import '../../core/models/student_model.dart';

class StudentRepository {
  Future<Database> get _db async => await DatabaseService.instance.database;

  Future<int> insertStudent(StudentModel student) async {
    final db = await _db;
    return await db.insert('students', student.toMap());
  }

  Future<int> updateStudent(StudentModel student) async {
    final db = await _db;
    return await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await _db;
    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<StudentModel>> getAllStudents() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('students');
    return maps.map((map) => StudentModel.fromMap(map)).toList();
  }

  Future<StudentModel?> getStudentById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return StudentModel.fromMap(maps.first);
    }
    return null;
  }
}
