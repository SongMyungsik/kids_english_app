import 'package:flutter/material.dart';

import 'bookshelf_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('영어 동화 읽기')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories, size: 96, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              '오늘은 어떤 동화를 읽어볼까요?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookshelfScreen()),
                );
              },
              child: const Text('책장으로 가기', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
