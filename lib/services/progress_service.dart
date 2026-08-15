import 'package:sqflite/sqflite.dart';

import '../db/db_helper.dart';
import '../models/user_progress.dart';

class ProgressService {
  Future<void> markCompleted(int bookId) async {
    final db = await DBHelper.database;
    await db.insert(
      'user_progress',
      {
        'book_id': bookId,
        'completed_pages': 1,
        'last_read_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProgress?> getProgress(int bookId) async {
    final db = await DBHelper.database;
    final rows = await db.query(
      'user_progress',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
    if (rows.isEmpty) return null;
    return UserProgress.fromMap(rows.first);
  }
}
