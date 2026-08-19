import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/sfx_service.dart';
import '../services/sticker_service.dart';
import 'sticker_board_screen.dart';

class CompleteScreen extends StatefulWidget {
  final Book book;
  final int? quizCorrect;
  final int? quizTotal;
  final StickerAward? stickerAward;

  const CompleteScreen({
    super.key,
    required this.book,
    this.quizCorrect,
    this.quizTotal,
    this.stickerAward,
  });

  @override
  State<CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends State<CompleteScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.stickerAward != null) {
      SfxService.playStickerEarned();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuizResult = widget.quizTotal != null && widget.quizTotal! > 0;
    final award = widget.stickerAward;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                '${widget.book.title}\n완독 성공!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                award != null ? '스티커를 획득했어요!' : 'OX 퀴즈를 풀면 스티커를 받을 수 있어요',
                style: const TextStyle(fontSize: 16),
              ),
              if (award != null) ...[
                const SizedBox(height: 12),
                _PopIn(
                  child: Text(
                    award.sticker.emoji,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ],
              if (hasQuizResult) ...[
                const SizedBox(height: 16),
                Text(
                  'OX 퀴즈: ${widget.quizCorrect} / ${widget.quizTotal} 맞혔어요!',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
              if (award != null && award.boardCompleted) ...[
                const SizedBox(height: 24),
                _PopIn(
                  child: Column(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 4),
                      Text(
                        '${award.boardNumber}번째 스티커판 완성! 🎉',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (award != null) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StickerBoardScreen()),
                    );
                  },
                  icon: const Text('⭐'),
                  label: const Text('내 스티커판 보기'),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text('홈으로 돌아가기'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 등장할 때 통통 튀며 커지는 연출.
class _PopIn extends StatelessWidget {
  final Widget child;

  const _PopIn({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        final clamped = (value).clamp(0.0, 1.5);
        return Opacity(
          opacity: clamped.clamp(0.0, 1.0),
          child: Transform.scale(scale: clamped, child: child),
        );
      },
      child: child,
    );
  }
}
