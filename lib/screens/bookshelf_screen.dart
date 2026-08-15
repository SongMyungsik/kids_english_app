import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/book_provider.dart';
import '../widgets/book_card.dart';
import 'reading_screen.dart';

class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().loadBooks();
    });
  }

  // "Level 1", "Level 2", ... 형식에서 숫자를 뽑아 정렬한다.
  // (숫자가 없는 레벨명이 섞여도 죽지 않도록 맨 뒤로 보낸다.)
  int _levelSortKey(String level) {
    final match = RegExp(r'\d+').firstMatch(level);
    return match != null ? int.parse(match.group(0)!) : 1 << 30;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('책장')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (provider.books.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('책장')),
            body: const Center(child: Text('아직 준비된 동화책이 없어요.')),
          );
        }

        final levels = provider.books.map((b) => b.level).toSet().toList()
          ..sort((a, b) => _levelSortKey(a).compareTo(_levelSortKey(b)));

        return DefaultTabController(
          length: levels.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('책장'),
              bottom: TabBar(
                isScrollable: true,
                tabs: levels.map((level) => Tab(text: level)).toList(),
              ),
            ),
            body: TabBarView(
              children: levels.map((level) {
                final booksForLevel =
                    provider.books.where((b) => b.level == level).toList();
                return _BookGrid(books: booksForLevel);
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _BookGrid extends StatelessWidget {
  final List<Book> books;

  const _BookGrid({required this.books});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookCard(
          book: book,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReadingScreen(book: book)),
            );
          },
        );
      },
    );
  }
}
