import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_schema.dart';

/// Singleton SQLite helper for the English Center app.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'english_center.db');

    return openDatabase(
      path,
      version: kDatabaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final sql in databaseTables) {
      await db.execute(sql);
    }
    for (final sql in databaseIndexes) {
      await db.execute(sql);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2 : add new columns to teachers (ignore error if already exists)
      for (final sql in migrationV1toV2) {
        try {
          await db.execute(sql);
        } catch (_) {
          // Column already exists – safe to ignore
        }
      }
    }
  }
}

