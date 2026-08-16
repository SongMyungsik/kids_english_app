import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';

import '../models/book.dart';
import '../models/picture_quiz_question.dart';
import '../services/audio_asset_loader.dart';

/// PictureQuizScreen이 완료 시 Navigator.pop으로 돌려주는 결과.
/// 이 책에 그림 퀴즈가 없어 곧바로 되돌아간 경우에는 null이 전달된다.
typedef PictureQuizResult = ({int correct, int total});

class PictureQuizScreen extends StatefulWidget {
  final Book book;

  const PictureQuizScreen({super.key, required this.book});

  @override
  State<PictureQuizScreen> createState() => _PictureQuizScreenState();
}

class _PictureQuizScreenState extends State<PictureQuizScreen> {
  final AudioPlayer _player = AudioPlayer();
  List<PictureQuizQuestion> _questions = [];
  int _index = 0;
  int _correctCount = 0;
  int? _selectedChoice;
  bool _isLoading = true;

  String get _bookDir =>
      'book_${widget.book.id.toString().padLeft(3, '0')}';
  String get _audioPath => 'assets/audio/$_bookDir/picture_quiz.mp3';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final jsonStr = await rootBundle
          .loadString('assets/audio/$_bookDir/picture_quiz.json');
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final questions = (data['questions'] as List<dynamic>)
          .map((e) =>
              PictureQuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      if (!mounted) return;
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      await _playSegment(_questions[_index].qStart, _questions[_index].qEnd);
    } catch (_) {
      // 이 책에 아직 그림 퀴즈가 없으면 결과 없이 허브로 돌아간다.
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _playSegment(double start, double end) async {
    final clip = await loadClippedSegment(
      _audioPath,
      start: Duration(milliseconds: (start * 1000).toInt()),
      end: Duration(milliseconds: (end * 1000).toInt()),
    );
    await _player.setAudioSource(clip);
    await _player.play();
  }

  void _playQuestion() {
    final q = _questions[_index];
    _playSegment(q.qStart, q.qEnd);
  }

  Future<void> _select(int choiceIndex) async {
    if (_selectedChoice != null) return;
    final q = _questions[_index];
    setState(() {
      _selectedChoice = choiceIndex;
      if (q.choices[choiceIndex].correct) _correctCount++;
    });
    await _playSegment(q.effectStart, q.effectEnd);
  }

  void _next() {
    if (_index == _questions.length - 1) {
      Navigator.pop(
        context,
        (correct: _correctCount, total: _questions.length),
      );
      return;
    }
    setState(() {
      _index++;
      _selectedChoice = null;
    });
    _playQuestion();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = _questions[_index];
    final answered = _selectedChoice != null;
    final isCorrect = answered && q.choices[_selectedChoice!].correct;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.book.title} 그림 퀴즈')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_index + 1} / ${_questions.length}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            IconButton(
              iconSize: 48,
              icon: const Icon(Icons.volume_up, color: Colors.blue),
              onPressed: _playQuestion,
            ),
            Text(
              q.questionEn,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              q.questionKo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            for (var i = 0; i < q.choices.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ChoiceCard(
                  choice: q.choices[i],
                  state: !answered
                      ? _ChoiceState.idle
                      : q.choices[i].correct
                          ? _ChoiceState.correct
                          : i == _selectedChoice
                              ? _ChoiceState.wrong
                              : _ChoiceState.idle,
                  onTap: () => _select(i),
                ),
              ),
            const SizedBox(height: 12),
            if (answered) ...[
              Text(
                isCorrect ? '정답이에요! 🎉' : '아쉬워요!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _next,
                child: Text(
                  _index == _questions.length - 1 ? '결과 보기' : '다음 문제',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ChoiceState { idle, correct, wrong }

class _ChoiceCard extends StatelessWidget {
  final PictureQuizChoice choice;
  final _ChoiceState state;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.choice,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _ChoiceState.correct => Colors.green,
      _ChoiceState.wrong => Colors.red,
      _ChoiceState.idle => Colors.grey,
    };

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: state == _ChoiceState.idle
            ? Colors.grey.shade100
            : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state == _ChoiceState.idle ? Colors.grey.shade300 : color,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(
              begin: choice.emojiSize,
              end: state == _ChoiceState.correct
                  ? choice.emojiSize * 1.3
                  : choice.emojiSize,
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, size, child) => Text(
              choice.emoji,
              style: TextStyle(fontSize: size),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              choice.labelEn,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (state == _ChoiceState.correct)
            const Icon(Icons.check_circle, color: Colors.green)
          else if (state == _ChoiceState.wrong)
            const Icon(Icons.cancel, color: Colors.red),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: card,
    );
  }
}
