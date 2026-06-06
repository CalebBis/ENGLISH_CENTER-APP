import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/database_service.dart';

/// Modèle de données représentant toutes les statistiques du tableau de bord.
///
/// Regroupe les indicateurs clés calculés depuis la base de données SQLite :
/// nombre d'étudiants, revenus, taux de présence, etc.
/// Utilisé par [DashboardRepository.getStats] et affiché dans [DashboardScreen].
class DashboardStats {
  /// Nombre total d'étudiants enregistrés (tous statuts confondus).
  final int totalStudents;

  /// Nombre d'étudiants avec le statut "Actif" uniquement.
  final int activeStudents;

  /// Nombre total d'enseignants enregistrés.
  final int totalTeachers;

  /// Nombre total de classes créées.
  final int totalClasses;

  /// Somme des paiements enregistrés pour le mois en cours (en USD).
  final double monthlyRevenue;

  /// Somme de tous les paiements enregistrés pour l'année en cours (en USD).
  final double annualRevenue;

  /// Nombre total de transactions de paiement enregistrées.
  final int totalPayments;

  /// Taux de présence moyen calculé depuis la table 'attendance' (en %).
  /// Retourne 100.0 si aucune donnée de présence n'existe encore.
  final double attendanceRate;

  DashboardStats({
    required this.totalStudents,
    required this.activeStudents,
    required this.totalTeachers,
    required this.totalClasses,
    required this.monthlyRevenue,
    required this.annualRevenue,
    required this.totalPayments,
    required this.attendanceRate,
  });
}

/// Couche d'accès aux données pour les statistiques du tableau de bord.
///
/// Ce repository exécute des requêtes SQL d'agrégation (COUNT, SUM)
/// pour calculer dynamiquement les indicateurs affichés sur le Dashboard.
class DashboardRepository {
  /// Getter qui retourne la connexion active à la base de données.
  Future<Database> get _db async => await DatabaseService.instance.database;

  /// Calcule et retourne toutes les statistiques du tableau de bord en une seule méthode.
  ///
  /// Exécute plusieurs requêtes SQL d'agrégation en séquence et encapsule
  /// les résultats dans un objet [DashboardStats].
  ///
  /// Toutes les valeurs utilisent l'opérateur `?? 0` pour éviter les erreurs null
  /// quand les tables sont vides.
  Future<DashboardStats> getStats() async {
    final db = await _db;

    // --- NOMBRE TOTAL D'ÉTUDIANTS ---
    // COUNT(*) retourne le nombre de lignes dans la table 'students'.
    final totalStudentsResult = await db.rawQuery('SELECT COUNT(*) as count FROM students');
    final int totalStudents = (totalStudentsResult.first['count'] as num?)?.toInt() ?? 0;

    // --- ÉTUDIANTS ACTIFS ---
    // Filtre uniquement les étudiants avec le statut = 'Actif'.
    final activeStudentsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM students WHERE status = ?', ['Actif'],
    );
    final int activeStudents = (activeStudentsResult.first['count'] as num?)?.toInt() ?? 0;

    // --- NOMBRE TOTAL D'ENSEIGNANTS ---
    final totalTeachersResult = await db.rawQuery('SELECT COUNT(*) as count FROM teachers');
    final int totalTeachers = (totalTeachersResult.first['count'] as num?)?.toInt() ?? 0;

    // --- NOMBRE TOTAL DE CLASSES ---
    final totalClassesResult = await db.rawQuery('SELECT COUNT(*) as count FROM classes');
    final int totalClasses = (totalClassesResult.first['count'] as num?)?.toInt() ?? 0;

    // --- REVENUS DU MOIS EN COURS ---
    // strftime('%Y-%m', payment_date) extrait l'année et le mois de chaque paiement.
    // La comparaison avec strftime('%Y-%m', 'now') filtre le mois courant.
    final monthlyRevenueResult = await db.rawQuery(
      "SELECT SUM(amount) as total FROM payments WHERE strftime('%Y-%m', payment_date) = strftime('%Y-%m', 'now')",
    );
    final double monthlyRevenue = (monthlyRevenueResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // --- REVENUS DE L'ANNÉE EN COURS ---
    // Même logique mais filtre sur l'année entière avec '%Y'.
    final annualRevenueResult = await db.rawQuery(
      "SELECT SUM(amount) as total FROM payments WHERE strftime('%Y', payment_date) = strftime('%Y', 'now')",
    );
    final double annualRevenue = (annualRevenueResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // --- NOMBRE TOTAL DE PAIEMENTS ---
    final totalPaymentsResult = await db.rawQuery('SELECT COUNT(*) as count FROM payments');
    final int totalPayments = (totalPaymentsResult.first['count'] as num?)?.toInt() ?? 0;

    // --- TAUX DE PRÉSENCE ---
    // Calcule le % de présences "Présent" sur le total des enregistrements d'assiduité.
    // Si aucune donnée n'existe (table vide), retourne 100.0 par défaut.
    final attendanceResult = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN status = 'Présent' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as rate 
      FROM attendance
    ''');
    final double attendanceRate = (attendanceResult.first['rate'] as num?)?.toDouble() ?? 100.0;

    // Construit et retourne l'objet DashboardStats avec toutes les statistiques calculées.
    return DashboardStats(
      totalStudents: totalStudents,
      activeStudents: activeStudents,
      totalTeachers: totalTeachers,
      totalClasses: totalClasses,
      monthlyRevenue: monthlyRevenue,
      annualRevenue: annualRevenue,
      totalPayments: totalPayments,
      attendanceRate: attendanceRate,
    );
  }
}
