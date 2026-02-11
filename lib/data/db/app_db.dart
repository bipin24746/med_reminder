import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static final AppDb instance = AppDb._();
  AppDb._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'med_reminder.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL
          );
        ''');

        await database.execute('''
          CREATE TABLE medicines(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            note TEXT,
            timesPerDay INTEGER NOT NULL,
            days INTEGER NOT NULL,
            timezone TEXT NOT NULL,
            timesJson TEXT NOT NULL,
            startDateMillis INTEGER NOT NULL
          );
        ''');
      },
    );
  }
}
