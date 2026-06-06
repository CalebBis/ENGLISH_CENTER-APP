import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/database_service.dart';
import '../../core/models/student_model.dart';

/// Couche d'accès aux données (Data Access Object) pour les étudiants.
///
/// Ce repository encapsule toutes les opérations SQLite liées à la table 'students'.
/// Il est utilisé par les providers Riverpod pour lire et écrire les données.
///
/// Chaque méthode est asynchrone car les opérations SQLite sont des I/O.
class StudentRepository {
  /// Getter qui retourne la connexion active à la base de données.
  ///
  /// Utilise le Singleton [DatabaseService.instance] pour garantir
  /// qu'une seule connexion est utilisée dans toute l'application.
  Future<Database> get _db async => await DatabaseService.instance.database;

  /// Insère un nouvel étudiant dans la table 'students'.
  ///
  /// [student] : le modèle étudiant à insérer. Son [id] doit être null
  /// (la base de données générera automatiquement un ID via AUTOINCREMENT).
  ///
  /// Retourne l'identifiant généré pour le nouvel enregistrement.
  Future<int> insertStudent(StudentModel student) async {
    final db = await _db;
    return await db.insert('students', student.toMap());
  }

  /// Met à jour les données d'un étudiant existant dans la table 'students'.
  ///
  /// [student] : le modèle avec les nouvelles valeurs. Son [id] est utilisé
  /// dans la clause WHERE pour cibler la bonne ligne.
  ///
  /// Retourne le nombre de lignes modifiées (devrait être 1).
  Future<int> updateStudent(StudentModel student) async {
    final db = await _db;
    return await db.update(
      'students',
      student.toMap(),       // Nouvelles valeurs
      where: 'id = ?',       // Condition de mise à jour
      whereArgs: [student.id], // Paramètre sécurisé (évite l'injection SQL)
    );
  }

  /// Supprime définitivement un étudiant de la table 'students'.
  ///
  /// [id] : l'identifiant unique de l'étudiant à supprimer.
  ///
  /// Retourne le nombre de lignes supprimées (devrait être 1).
  Future<int> deleteStudent(int id) async {
    final db = await _db;
    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Récupère la liste complète de tous les étudiants enregistrés.
  ///
  /// Exécute un SELECT * sur la table 'students' et convertit chaque ligne
  /// en un objet [StudentModel] via [StudentModel.fromMap].
  ///
  /// Retourne une liste vide si aucun étudiant n'est enregistré.
  Future<List<StudentModel>> getAllStudents() async {
    final db = await _db;
    // Retourne toutes les lignes de la table 'students'.
    final List<Map<String, dynamic>> maps = await db.query('students');
    // Convertit chaque Map SQLite en un objet StudentModel typé.
    return maps.map((map) => StudentModel.fromMap(map)).toList();
  }

  /// Récupère un seul étudiant par son identifiant.
  ///
  /// [id] : l'identifiant unique de l'étudiant recherché.
  ///
  /// Retourne le [StudentModel] correspondant, ou null si non trouvé.
  Future<StudentModel?> getStudentById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Si une ligne a été trouvée, convertit et retourne le premier résultat.
    if (maps.isNotEmpty) {
      return StudentModel.fromMap(maps.first);
    }
    // Aucune correspondance trouvée.
    return null;
  }
}
