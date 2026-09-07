import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../models/student.dart';
import '../../models/english_class.dart';
import '../../models/enrollment.dart';
import '../database_helper.dart';

class StudentDao {
  Future<List<Student>> getAllStudents() async {
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
      ORDER BY s.lastName ASC
    ''');

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

  Future<void> insertStudent(Student student, String? classId) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.insert('students', student.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      if (classId != null) {
        final enrollment = Enrollment(
          id: const Uuid().v4(),
          studentId: student.id,
          classId: classId,
          enrollmentDate: DateTime.now(),
          status: 'Active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await txn.insert('enrollments', enrollment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> updateStudent(Student student, String? newClassId) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'students',
        student.toMap(),
        where: 'id = ?',
        whereArgs: [student.id],
      );

      // Check current enrollment
      final existingEnrollmentRows = await txn.query(
        'enrollments',
        where: 'studentId = ?',
        whereArgs: [student.id],
      );

      final hasExistingClass = existingEnrollmentRows.isNotEmpty;
      final currentClassId = hasExistingClass ? existingEnrollmentRows.first['classId'] as String : null;

      if (newClassId != currentClassId) {
        // Delete old enrollment if it exists
        if (hasExistingClass) {
          await txn.delete(
            'enrollments',
            where: 'studentId = ?',
            whereArgs: [student.id],
          );
        }

        // Create new enrollment if newClassId is provided
        if (newClassId != null) {
          final enrollment = Enrollment(
            id: const Uuid().v4(),
            studentId: student.id,
            classId: newClassId,
            enrollmentDate: DateTime.now(),
            status: 'Active',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await txn.insert('enrollments', enrollment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  Future<void> deleteStudent(String studentId) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // First delete linked enrollments
      await txn.delete(
        'enrollments',
        where: 'studentId = ?',
        whereArgs: [studentId],
      );
      // Delete payments, attendance, results if necessary
      await txn.delete(
        'payments',
        where: 'studentId = ?',
        whereArgs: [studentId],
      );
      await txn.delete(
        'attendance',
        where: 'studentId = ?',
        whereArgs: [studentId],
      );
      await txn.delete(
        'results',
        where: 'studentId = ?',
        whereArgs: [studentId],
      );
      
      // Finally delete the student
      await txn.delete(
        'students',
        where: 'id = ?',
        whereArgs: [studentId],
      );
    });
  }
}
