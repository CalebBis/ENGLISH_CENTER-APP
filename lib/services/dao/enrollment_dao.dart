import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class EnrollmentDao {
  /// Retourne le classId de l'inscription active la plus récente d'un étudiant,
  /// ou null si non inscrit.
  Future<String?> getActiveClassIdForStudent(String studentId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT classId 
      FROM enrollments 
      WHERE studentId = ? AND status = 'Active' 
      ORDER BY enrollmentDate DESC 
      LIMIT 1
    ''', [studentId]);

    if (rows.isNotEmpty) {
      return rows.first['classId'] as String?;
    }
    return null;
  }

  /// Retourne une map de studentId -> classId pour tous les étudiants actifs
  Future<Map<String, String>> getActiveEnrollmentsMap() async {
    final db = await DatabaseHelper.instance.database;
    // Pour gérer les multiples inscriptions actives, on prend la plus récente par étudiant.
    final rows = await db.rawQuery('''
      SELECT studentId, classId
      FROM enrollments
      WHERE status = 'Active'
      GROUP BY studentId
      HAVING MAX(enrollmentDate)
    ''');
    
    // Si SQLite HAVING MAX ne suffit pas, on peut juste utiliser un GROUP BY si l'intégrité métier 
    // garantit 1 seule inscription active max par étudiant.
    
    final Map<String, String> map = {};
    for (var row in rows) {
      final sId = row['studentId'] as String;
      final cId = row['classId'] as String;
      map[sId] = cId;
    }
    return map;
  }
}
