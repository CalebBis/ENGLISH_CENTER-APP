import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('english_center.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialiser FFI pour Windows
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, 'EnglishCenter', filePath);
    
    // S'assurer que le répertoire existe
    await Directory(join(dbPath.path, 'EnglishCenter')).create(recursive: true);

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
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
    
    await _createDB(db, newVersion);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';

    await db.execute('''
      CREATE TABLE users (
        id $idType,
        username $textType,
        password_hash $textType,
        role $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE levels (
        id $idType,
        name $textType,
        description TEXT,
        duration $intType,
        objectives TEXT
      )
    ''');

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

    // Insérer un utilisateur Administrateur par défaut
    // Remarque : Dans une vraie application, il faut hacher le mot de passe.
    await db.execute('''
      INSERT INTO users (username, password_hash, role) 
      VALUES ('admin', 'admin', 'Administrateur')
    ''');
    
    // Insérer les niveaux par défaut
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
