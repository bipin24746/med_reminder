import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDb {
  static const _dbName = 'med_reminder.db';
  static const _dbVersion = 2; // bump version when schema changes

  static Database? _database;

  static Future<Database> get db async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (Database db, int version) async {
        // ✅ create users table
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
          );
        ''');

        // ✅ create medicines table
        await db.execute('''
          CREATE TABLE medicines(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            note TEXT,
            timesPerDay INTEGER NOT NULL,
            days INTEGER NOT NULL,
            timezone TEXT NOT NULL,
            timesJson TEXT NOT NULL,
            startDateMillis INTEGER NOT NULL,
            form TEXT NOT NULL DEFAULT 'pill',
            doseAmount TEXT NOT NULL DEFAULT '1'
          );
        ''');
      },

      // ✅ If you change schema later, handle upgrades here
      onUpgrade: (db, oldVersion, newVersion) async {
        // If user is coming from old version without users table
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT NOT NULL UNIQUE,
              password TEXT NOT NULL
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS medicines(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              note TEXT,
              timesPerDay INTEGER NOT NULL,
              days INTEGER NOT NULL,
              timezone TEXT NOT NULL,
              timesJson TEXT NOT NULL,
              startDateMillis INTEGER NOT NULL,
              form TEXT NOT NULL DEFAULT 'pill',
              doseAmount TEXT NOT NULL DEFAULT '1'
            );
          ''');
        }
      },
    );
  }
}
