import 'package:sqflite/sqflite.dart';
import '../db/app_db.dart';
import '../models/user_local.dart';

class UserRepo {
  Future<LocalUser?> signIn(String email, String password) async {
    final Database db = await AppDb.db;
    final rows = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LocalUser.fromMap(rows.first);
  }

  Future<bool> signUp(String email, String password) async {
    final Database db = await AppDb.db;
    try {
      await db.insert('users', {
        'email': email,
        'password': password,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
