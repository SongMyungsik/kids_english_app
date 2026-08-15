import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/book.dart';
import 'complete_screen.dart';
import 'match_pairs_screen.dart';
import 'ox_quiz_screen.dart';

class ActivityHubScreen extends StatefulWidget {
  final Book book;

  const ActivityHubScreen({super.key, required this.book});

  @override
  State<ActivityHubScreen> createState() => _ActivityHubScreenState();
}

class _ActivityHubScreenState extends State<ActivityHubScreen> {
  bool _isLoading = true;
  bool _hasQuiz = false;
  bool _hasMatch = false;

  int? _quizCorrect;
  int? _quizTotal;
  bool _matchDone = false;

  String get _bookDir => 'book_${widget.book.id.toString().padLeft(3, '0')}';

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.loadString(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkAvailability() async {
    final hasQuiz = await _assetExists('assets/audio/$_bookDir/quiz_ox.json');
    final hasMatch =
        await _assetExists('assets/audio/$_bookDir/match_pairs.json');
    if (!mounted) return;
    setState(() {
      _hasQuiz = hasQuiz;
      _hasMatch = hasMatch;
      _isLoading = false;
    });
  }

  Future<void> _openOxQuiz() async {
    final result = await Navigator.push<OxQuizResult>(
      context,
      MaterialPageRoute(builder: (_) => OxQuizScreen(book: widget.book)),
    );
    if (result == null || !mounted) return;
    setState(() {
      _quizCorrect = result.correct;
      _quizTotal = result.total;
    });
  }

  Future<void> _openMatchPairs() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MatchPairsScreen(book: widget.book)),
    );
    if (result != true || !mounted) return;
    setState(() => _matchDone = true);
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompleteScreen(
          book: widget.book,
          quizCorrect: _quizCorrect,
          quizTotal: _quizTotal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.book.title} 활동')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      '하고 싶은 활동을 골라보세요!',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    _ActivityTile(
                      emoji: '⭕',
                      title: 'OX 퀴즈',
                      subtitle: _quizTotal != null
                          ? '$_quizCorrect / $_quizTotal 맞혔어요'
                          : '동화 내용을 맞혀보세요',
                      enabled: _hasQuiz,
                      done: _quizTotal != null,
                      onTap: _openOxQuiz,
                    ),
                    const SizedBox(height: 16),
                    _ActivityTile(
                      emoji: '🧩',
                      title: '짝맞추기',
                      subtitle: '단어와 그림을 연결해보세요',
                      enabled: _hasMatch,
                      done: _matchDone,
                      onTap: _openMatchPairs,
                    ),
                    const SizedBox(height: 16),
                    const _ActivityTile(
                      emoji: '🖼️',
                      title: '그림 퀴즈',
                      subtitle: '곧 추가될 예정이에요',
                      enabled: false,
                      done: false,
                      onTap: null,
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        '완료하기',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool done;
  final VoidCallback? onTap;

  const _ActivityTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: done ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: done ? Colors.green : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (done) const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
