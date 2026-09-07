import 'package:sqflite/sqflite.dart';
import '../../models/teacher.dart';
import '../database_helper.dart';


/// Data Access Object for the [Teacher] model.
class TeacherDAO {
  static const _table = 'teachers';

  Future<List<Teacher>> getAllTeachers() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_table, orderBy: 'lastName ASC');
    return rows.map(Teacher.fromMap).toList();
  }

  Future<Teacher?> getTeacherById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Teacher.fromMap(rows.first);
  }

  Future<void> insertTeacher(Teacher teacher) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(_table, teacher.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTeacher(Teacher teacher) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(_table, teacher.toMap(),
        where: 'id = ?', whereArgs: [teacher.id]);
  }

  Future<void> deleteTeacher(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}

