import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static Database? _db;

  static const _createStickersTableSql = '''
    CREATE TABLE stickers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER NOT NULL,
      book_title TEXT NOT NULL,
      earned_at TEXT NOT NULL,
      emoji TEXT NOT NULL DEFAULT '⭐'
    )
  ''';

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String path;
    if (kIsWeb) {
      // 웹은 IndexedDB 기반 wasm sqlite3 백엔드 사용, 실제 파일 경로가 없다.
      databaseFactory = databaseFactoryFfiWeb;
      path = 'kids_english.db';
    } else {
      // Windows/Linux 데스크톱은 ffi 백엔드 필요 (Android/iOS는 기본 sqflite 사용)
      if (Platform.isWindows || Platform.isLinux) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      final dir = await getApplicationDocumentsDirectory();
      path = join(dir.path, 'kids_english.db');
    }

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE books (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            level TEXT NOT NULL,
            cover_image TEXT NOT NULL,
            audio_path TEXT NOT NULL,
            timing_path TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE user_progress (
            book_id INTEGER PRIMARY KEY,
            completed_pages INTEGER DEFAULT 0,
            last_read_at TEXT
          )
        ''');

        await db.execute(_createStickersTableSql);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(_createStickersTableSql);
        }
        if (oldVersion == 2) {
          await db.execute(
            "ALTER TABLE stickers ADD COLUMN emoji TEXT NOT NULL DEFAULT '⭐'",
          );
        }
      },
    );
  }

  /// seedBooks에 있지만 아직 DB에 없는 동화책을 채워 넣는다.
  /// (id가 이미 있으면 건너뛰므로, 새 책을 seed_books.dart에 추가하는 것만으로
  /// 기존 설치에도 반영된다.)
  static Future<void> seedIfEmpty(List<Map<String, dynamic>> seedBooks) async {
    final db = await database;
    final batch = db.batch();
    for (final book in seedBooks) {
      batch.insert('books', book, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }
}
