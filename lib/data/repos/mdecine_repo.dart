import 'package:sqflite/sqflite.dart';
import '../db/app_db.dart';
import '../models/medicine.dart';

class MedicineRepo {
  Future<int> insert(Medicine med) async {
    final Database db = await AppDb.instance.db;
    return db.insert('medicines', med.toMap());
  }

  Future<List<Medicine>> all() async {
    final Database db = await AppDb.instance.db;
    final rows = await db.query('medicines', orderBy: 'id DESC');
    return rows.map(Medicine.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final Database db = await AppDb.instance.db;
    await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }
}
