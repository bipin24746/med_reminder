import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDb {
  static const _dbName = 'med_reminder.db';

  // ✅ bump version when schema changes
  static const _dbVersion = 3;

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
        // ✅ users table
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
          );
        ''');

        // ✅ medicines table (NEW schema with frequency fields)
        await db.execute('''
          CREATE TABLE medicines(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            note TEXT,
            timesPerDay INTEGER NOT NULL,

            -- keep days for now (to avoid breaking older code/migrations)
            days INTEGER NOT NULL DEFAULT 0,

            timezone TEXT NOT NULL,
            timesJson TEXT NOT NULL,
            startDateMillis INTEGER NOT NULL,
            form TEXT NOT NULL DEFAULT 'pill',
            doseAmount TEXT NOT NULL DEFAULT '1',

            -- ✅ NEW repeating scheduling fields
            frequencyType INTEGER NOT NULL DEFAULT 0,  -- 0=daily 1=interval 2=weekly 3=monthly
            intervalHours INTEGER NOT NULL DEFAULT 8,
            weeklyMask INTEGER NOT NULL DEFAULT 127,   -- Mon..Sun all selected
            monthlyDay INTEGER NOT NULL DEFAULT 1
          );
        ''');
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        // ✅ ensure users table exists for older installs
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT NOT NULL UNIQUE,
              password TEXT NOT NULL
            );
          ''');
        }

        // ✅ if coming from v1/v2, medicines table exists but missing new columns
        if (oldVersion < 3) {
          // Add columns safely
          await _addColumnIfMissing(db, 'medicines', 'frequencyType',
              "INTEGER NOT NULL DEFAULT 0");
          await _addColumnIfMissing(db, 'medicines', 'intervalHours',
              "INTEGER NOT NULL DEFAULT 8");
          await _addColumnIfMissing(db, 'medicines', 'weeklyMask',
              "INTEGER NOT NULL DEFAULT 127");
          await _addColumnIfMissing(db, 'medicines', 'monthlyDay',
              "INTEGER NOT NULL DEFAULT 1");
        }
      },
    );
  }

  // ---- helpers ----

  static Future<void> _addColumnIfMissing(
      Database db,
      String table,
      String column,
      String columnDefSql,
      ) async {
    final cols = await db.rawQuery("PRAGMA table_info($table)");
    final exists = cols.any((c) => (c['name'] as String) == column);
    if (!exists) {
      await db.execute("ALTER TABLE $table ADD COLUMN $column $columnDefSql;");
    }
  }
}
