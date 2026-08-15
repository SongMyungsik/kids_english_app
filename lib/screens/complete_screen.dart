import 'package:flutter/material.dart';

import '../models/book.dart';

class CompleteScreen extends StatelessWidget {
  final Book book;
  final int? quizCorrect;
  final int? quizTotal;

  const CompleteScreen({
    super.key,
    required this.book,
    this.quizCorrect,
    this.quizTotal,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuizResult = quizTotal != null && quizTotal! > 0;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              '${book.title}\n완독 성공!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('스티커를 획득했어요! 🎉', style: TextStyle(fontSize: 16)),
            if (hasQuizResult) ...[
              const SizedBox(height: 16),
              Text(
                'OX 퀴즈: $quizCorrect / $quizTotal 맞혔어요!',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
