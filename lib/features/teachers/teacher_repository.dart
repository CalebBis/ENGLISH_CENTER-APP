import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/database_service.dart';
import '../../core/models/teacher_model.dart';

class TeacherRepository {
  Future<Database> get _db async => await DatabaseService.instance.database;

  Future<int> insertTeacher(TeacherModel teacher) async {
    final db = await _db;
    return await db.insert('teachers', teacher.toMap());
  }

  Future<int> updateTeacher(TeacherModel teacher) async {
    final db = await _db;
    return await db.update(
      'teachers',
      teacher.toMap(),
      where: 'id = ?',
      whereArgs: [teacher.id],
    );
  }

  Future<int> deleteTeacher(int id) async {
    final db = await _db;
    return await db.delete(
      'teachers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TeacherModel>> getAllTeachers() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('teachers');
    return maps.map((map) => TeacherModel.fromMap(map)).toList();
  }

  Future<TeacherModel?> getTeacherById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'teachers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return TeacherModel.fromMap(maps.first);
    }
    return null;
  }
}
