import 'package:sqflite/sqflite.dart';
import '../../models/english_class.dart';
import '../../models/teacher.dart';
import '../../models/student.dart';
import '../database_helper.dart';

class ClassDao {
  static const _table = 'classes';

  Future<List<EnglishClass>> getAllClasses() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT c.*, 
             t.id as t_id, t.firstName as t_firstName, t.lastName as t_lastName, 
             t.postName as t_postName, t.email as t_email, t.phone as t_phone, 
             t.specializations as t_specializations, t.isActive as t_isActive,
             t.createdAt as t_createdAt, t.updatedAt as t_updatedAt,
             (SELECT COUNT(*) FROM enrollments e WHERE e.classId = c.id) as realEnrollmentCount
      FROM classes c
      LEFT JOIN teachers t ON c.teacherId = t.id
      ORDER BY c.name ASC
    ''');

    return rows.map((row) {
      // Build Teacher if exists
      Teacher? teacher;
      if (row['t_id'] != null) {
        teacher = Teacher(
          id: row['t_id'] as String,
          firstName: row['t_firstName'] as String,
          lastName: row['t_lastName'] as String,
          postName: (row['t_postName'] as String?) ?? '',
          email: row['t_email'] as String,
          phone: row['t_phone'] as String,
          specializations: (row['t_specializations'] as String).isNotEmpty
              ? (row['t_specializations'] as String).split(',')
              : [],
          isActive: (row['t_isActive'] as int? ?? 1) == 1,
          createdAt: DateTime.parse(row['t_createdAt'] as String),
          updatedAt: DateTime.parse(row['t_updatedAt'] as String),
        );
      }

      // Map class data and override currentEnrollment with dynamic count
      final map = Map<String, dynamic>.from(row);
      map['currentEnrollment'] = row['realEnrollmentCount'];

      return EnglishClass.fromMap(map, teacher: teacher);
    }).toList();
  }

  Future<EnglishClass?> getClassById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT c.*, 
             t.id as t_id, t.firstName as t_firstName, t.lastName as t_lastName, 
             t.postName as t_postName, t.email as t_email, t.phone as t_phone, 
             t.specializations as t_specializations, t.isActive as t_isActive,
             t.createdAt as t_createdAt, t.updatedAt as t_updatedAt,
             (SELECT COUNT(*) FROM enrollments e WHERE e.classId = c.id) as realEnrollmentCount
      FROM classes c
      LEFT JOIN teachers t ON c.teacherId = t.id
      WHERE c.id = ?
    ''', [id]);

    if (rows.isEmpty) return null;

    final row = rows.first;
    Teacher? teacher;
    if (row['t_id'] != null) {
      teacher = Teacher(
        id: row['t_id'] as String,
        firstName: row['t_firstName'] as String,
        lastName: row['t_lastName'] as String,
        postName: (row['t_postName'] as String?) ?? '',
        email: row['t_email'] as String,
        phone: row['t_phone'] as String,
        specializations: (row['t_specializations'] as String).isNotEmpty
            ? (row['t_specializations'] as String).split(',')
            : [],
        isActive: (row['t_isActive'] as int? ?? 1) == 1,
        createdAt: DateTime.parse(row['t_createdAt'] as String),
        updatedAt: DateTime.parse(row['t_updatedAt'] as String),
      );
    }
    
    final map = Map<String, dynamic>.from(row);
    map['currentEnrollment'] = row['realEnrollmentCount'];
    return EnglishClass.fromMap(map, teacher: teacher);
  }

  Future<void> insertClass(EnglishClass englishClass) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(_table, englishClass.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateClass(EnglishClass englishClass) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(_table, englishClass.toMap(),
        where: 'id = ?', whereArgs: [englishClass.id]);
  }

  Future<void> deleteClass(String id) async {
    final db = await DatabaseHelper.instance.database;
    // Transaction to safely delete enrollments then the class
    await db.transaction((txn) async {
      await txn.delete('enrollments', where: 'classId = ?', whereArgs: [id]);
      await txn.delete(_table, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Student>> getStudentsInClass(String classId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT s.* 
      FROM students s
      INNER JOIN enrollments e ON s.id = e.studentId
      WHERE e.classId = ?
      ORDER BY s.lastName ASC
    ''', [classId]);
    return rows.map(Student.fromMap).toList();
  }

  Future<void> enrollStudent(String classId, String studentId) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // Rule: One student = One class. Delete any existing enrollment.
      await txn.delete(
        'enrollments',
        where: 'studentId = ?',
        whereArgs: [studentId],
      );

      // Create new enrollment
      final enrollment = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'studentId': studentId,
        'classId': classId,
        'enrollmentDate': DateTime.now().toIso8601String(),
        'status': 'Active',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await txn.insert('enrollments', enrollment);
    });
  }

  Future<void> unenrollStudent(String classId, String studentId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'enrollments',
      where: 'classId = ? AND studentId = ?',
      whereArgs: [classId, studentId],
    );
  }

  Future<List<Student>> getOtherStudents(String classId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT 
        s.*, 
        c.id as class_id, c.name as class_name, c.level as class_level, 
        c.teacherId as class_teacherId, c.maxCapacity as class_maxCapacity, 
        c.currentEnrollment as class_currentEnrollment, c.schedule as class_schedule, 
        c.location as class_location, c.createdAt as class_createdAt, c.updatedAt as class_updatedAt
      FROM students s
      LEFT JOIN enrollments e ON s.id = e.studentId
      LEFT JOIN classes c ON e.classId = c.id
      WHERE s.id NOT IN (
        SELECT studentId FROM enrollments WHERE classId = ?
      )
      ORDER BY s.lastName ASC
    ''', [classId]);
    
    return rows.map((row) {
      EnglishClass? englishClass;
      if (row['class_id'] != null) {
        englishClass = EnglishClass(
          id: row['class_id'] as String,
          name: row['class_name'] as String,
          level: row['class_level'] as String,
          teacherId: row['class_teacherId'] as String,
          maxCapacity: row['class_maxCapacity'] as int,
          currentEnrollment: row['class_currentEnrollment'] as int? ?? 0,
          schedule: row['class_schedule'] as String,
          location: row['class_location'] as String,
          createdAt: DateTime.parse(row['class_createdAt'] as String),
          updatedAt: DateTime.parse(row['class_updatedAt'] as String),
        );
      }
      return Student.fromMap(row, englishClass: englishClass);
    }).toList();
  }
}

