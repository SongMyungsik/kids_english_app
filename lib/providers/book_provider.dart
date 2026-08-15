import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import '../data/seed_books.dart';
import '../models/book.dart';

class BookProvider extends ChangeNotifier {
  List<Book> _books = [];
  bool _loading = false;

  List<Book> get books => _books;
  bool get isLoading => _loading;

  Future<void> loadBooks() async {
    _loading = true;
    notifyListeners();

    await DBHelper.seedIfEmpty(seedBooks);

    final db = await DBHelper.database;
    final rows = await db.query('books', orderBy: 'id ASC');
    _books = rows.map((row) => Book.fromMap(row)).toList();

    _loading = false;
    notifyListeners();
  }
}
