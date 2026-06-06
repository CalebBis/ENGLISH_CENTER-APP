import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Service central de gestion de la base de données SQLite.
///
/// Utilise le **pattern Singleton** : une seule instance de [DatabaseService]
/// est créée et réutilisée dans toute l'application.
/// Cela garantit qu'une seule connexion à la base de données est ouverte.
class DatabaseService {
  /// L'instance unique (Singleton) accessible globalement.
  static final DatabaseService instance = DatabaseService._init();

  /// La connexion à la base de données. Null si pas encore initialisée.
  static Database? _database;

  /// Constructeur privé : empêche la création d'autres instances depuis l'extérieur.
  DatabaseService._init();

  /// Getter asynchrone qui retourne la connexion à la base de données.
  ///
  /// Si la base est déjà ouverte ([_database] != null), on la retourne directement.
  /// Sinon, on l'initialise en appelant [_initDB].
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('english_center.db');
    return _database!;
  }

  /// Initialise la base de données SQLite.
  ///
  /// - Détermine le chemin du fichier `.db` dans le répertoire Documents de l'utilisateur.
  /// - Crée le dossier "EnglishCenter" si nécessaire.
  /// - Ouvre (ou crée) la base de données avec les callbacks [_createDB] et [_upgradeDB].
  ///
  /// [filePath] : nom du fichier de base de données (ex: 'english_center.db').
  Future<Database> _initDB(String filePath) async {
    // Active le driver FFI pour les plateformes Desktop non supportées nativement.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Récupère le dossier "Documents" de l'utilisateur courant.
    final dbPath = await getApplicationDocumentsDirectory();

    // Construit le chemin complet vers le fichier .db.
    final path = join(dbPath.path, 'EnglishCenter', filePath);

    // Crée le dossier 'EnglishCenter' s'il n'existe pas encore.
    await Directory(join(dbPath.path, 'EnglishCenter')).create(recursive: true);

    // Ouvre la base de données. Si elle n'existe pas, [onCreate] est appelé.
    // Si la version change, [onUpgrade] est appelé pour migrer.
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,             // Numéro de version du schéma de la base
        onCreate: _createDB,    // Appelé à la première création
        onUpgrade: _upgradeDB,  // Appelé si la version augmente
      ),
    );
  }

  /// Gère la migration de la base de données lors d'un changement de version.
  ///
  /// Cette stratégie "drop and recreate" supprime toutes les tables dans l'ordre
  /// inverse de leurs dépendances (clés étrangères), puis recrée tout.
  ///
  /// [db] : l'objet base de données.
  /// [oldVersion] : ancienne version du schéma.
  /// [newVersion] : nouvelle version du schéma cible.
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Suppression dans l'ordre inverse des dépendances pour éviter les erreurs
    // de contraintes de clés étrangères.
    await db.execute('DROP TABLE IF EXISTS exam_results');
    await db.execute('DROP TABLE IF EXISTS exams');
    await db.execute('DROP TABLE IF EXISTS attendance');
    await db.execute('DROP TABLE IF EXISTS payments');
    await db.execute('DROP TABLE IF EXISTS enrollments');
    await db.execute('DROP TABLE IF EXISTS classes');
    await db.execute('DROP TABLE IF EXISTS teachers');
    await db.execute('DROP TABLE IF EXISTS certificates');
    await db.execute('DROP TABLE IF EXISTS students');
    await db.execute('DROP TABLE IF EXISTS levels');
    await db.execute('DROP TABLE IF EXISTS users');

    // Recrée toutes les tables avec le nouveau schéma.
    await _createDB(db, newVersion);
  }

  /// Crée toutes les tables de la base de données lors de la première installation.
  ///
  /// Définit également les données initiales (utilisateur admin + niveaux d'anglais).
  ///
  /// [db] : l'objet base de données.
  /// [version] : la version actuelle (utilisée pour les migrations futures).
  Future _createDB(Database db, int version) async {
    // Types SQL réutilisables pour simplifier les déclarations de colonnes.
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT'; // Clé primaire auto-incrémentée
    const textType = 'TEXT NOT NULL';                   // Texte obligatoire
    const intType = 'INTEGER NOT NULL';                 // Entier obligatoire
    const doubleType = 'REAL NOT NULL';                 // Nombre décimal obligatoire
    const boolType = 'BOOLEAN NOT NULL';                // Non utilisé ici (déclaré pour référence future)

    // Table 'users' : stocke les comptes d'accès à l'application (administrateurs, etc.)
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        username $textType,
        password_hash $textType,
        role $textType
      )
    ''');

    // Table 'levels' : définit les niveaux d'anglais disponibles (Beginner, Advanced, etc.)
    await db.execute('''
      CREATE TABLE levels (
        id $idType,
        name $textType,
        description TEXT,
        duration $intType,
        objectives TEXT
      )
    ''');

    // Table 'students' : stocke les informations complètes de chaque étudiant inscrit.
    // Référence la table 'levels' via current_level_id (clé étrangère).
    await db.execute('''
      CREATE TABLE students (
        id $idType,
        last_name $textType,
        postname $textType,
        firstname $textType,
        gender $textType,
        pob $textType,
        dob $textType,
        phone $textType,
        address TEXT,
        email TEXT,
        nationality TEXT,
        photo_path TEXT,
        contact_person TEXT,
        emergency_phone TEXT,
        status $textType,
        enroll_date $textType,
        current_level_id INTEGER,
        FOREIGN KEY (current_level_id) REFERENCES levels (id)
      )
    ''');

    // Table 'teachers' : stocke les informations complètes des enseignants.
    await db.execute('''
      CREATE TABLE teachers (
        id $idType,
        last_name $textType,
        postname $textType,
        firstname $textType,
        gender $textType,
        pob $textType,
        dob $textType,
        phone $textType,
        address TEXT,
        email TEXT,
        nationality TEXT,
        specialty $textType,
        teaching_level TEXT,
        photo_path TEXT,
        status $textType,
        hire_date $textType
      )
    ''');

    // Table 'classes' : représente une classe de cours.
    // Liée à 'levels' (niveau de la classe) et 'teachers' (enseignant responsable).
    await db.execute('''
      CREATE TABLE classes (
        id $idType,
        name $textType,
        level_id $intType,
        teacher_id $intType,
        schedule $textType,
        room $textType,
        max_capacity $intType,
        FOREIGN KEY (level_id) REFERENCES levels (id),
        FOREIGN KEY (teacher_id) REFERENCES teachers (id)
      )
    ''');

    // Table 'enrollments' : table de liaison entre 'students' et 'classes'.
    // Représente l'inscription d'un étudiant dans une classe (relation Many-to-Many).
    await db.execute('''
      CREATE TABLE enrollments (
        id $idType,
        student_id $intType,
        class_id $intType,
        enroll_date $textType,
        FOREIGN KEY (student_id) REFERENCES students (id),
        FOREIGN KEY (class_id) REFERENCES classes (id)
      )
    ''');

    // Table 'payments' : enregistre les paiements effectués par les étudiants.
    await db.execute('''
      CREATE TABLE payments (
        id $idType,
        student_id $intType,
        amount $doubleType,
        payment_date $textType,
        month $textType,
        payment_method $textType,
        FOREIGN KEY (student_id) REFERENCES students (id)
      )
    ''');

    // Table 'attendance' : registre des présences/absences par classe et par étudiant.
    await db.execute('''
      CREATE TABLE attendance (
        id $idType,
        class_id $intType,
        student_id $intType,
        date $textType,
        status $textType,
        FOREIGN KEY (class_id) REFERENCES classes (id),
        FOREIGN KEY (student_id) REFERENCES students (id)
      )
    ''');

    // Table 'exams' : définit les examens organisés dans une classe donnée.
    await db.execute('''
      CREATE TABLE exams (
        id $idType,
        class_id $intType,
        title $textType,
        max_score $doubleType,
        date $textType,
        FOREIGN KEY (class_id) REFERENCES classes (id)
      )
    ''');

    // Table 'exam_results' : stocke les notes obtenues par les étudiants aux examens.
    await db.execute('''
      CREATE TABLE exam_results (
        id $idType,
        exam_id $intType,
        student_id $intType,
        score $doubleType,
        FOREIGN KEY (exam_id) REFERENCES exams (id),
        FOREIGN KEY (student_id) REFERENCES students (id)
      )
    ''');

    // Table 'certificates' : trace les certificats de niveau émis pour les étudiants.
    await db.execute('''
      CREATE TABLE certificates (
        id $idType,
        student_id $intType,
        level_id $intType,
        issue_date $textType,
        pdf_path $textType,
        FOREIGN KEY (student_id) REFERENCES students (id),
        FOREIGN KEY (level_id) REFERENCES levels (id)
      )
    ''');

    // Insère l'utilisateur administrateur par défaut.
    // IMPORTANT : Dans une application en production, le mot de passe doit être haché.
    await db.execute('''
      INSERT INTO users (username, password_hash, role) 
      VALUES ('admin', 'admin', 'Administrateur')
    ''');

    // Insère les 6 niveaux d'anglais standards utilisés dans tout le système.
    final levels = [
      'Beginner', 'Elementary', 'Intermediate',
      'Upper Intermediate', 'Advanced', 'IELTS / TOEFL'
    ];
    for (var level in levels) {
      await db.execute('''
        INSERT INTO levels (name, description, duration, objectives)
        VALUES ('$level', 'Description pour $level', 3, 'Terminer le programme $level')
      ''');
    }
  }

  /// Ferme la connexion à la base de données.
  ///
  /// À appeler avant de quitter l'application pour libérer les ressources.
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
