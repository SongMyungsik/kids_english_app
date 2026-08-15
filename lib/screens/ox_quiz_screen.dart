import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';

import '../models/book.dart';
import '../models/ox_question.dart';
import '../services/audio_asset_loader.dart';

/// OxQuizScreen이 완료 시 Navigator.pop으로 돌려주는 결과.
/// 이 책에 퀴즈가 없어 곧바로 되돌아간 경우에는 null이 전달된다.
typedef OxQuizResult = ({int correct, int total});

class OxQuizScreen extends StatefulWidget {
  final Book book;

  const OxQuizScreen({super.key, required this.book});

  @override
  State<OxQuizScreen> createState() => _OxQuizScreenState();
}

class _OxQuizScreenState extends State<OxQuizScreen> {
  final AudioPlayer _player = AudioPlayer();
  List<OxQuestion> _questions = [];
  int _index = 0;
  int _correctCount = 0;
  bool? _selectedAnswer;
  bool _isLoading = true;

  String get _bookDir =>
      'book_${widget.book.id.toString().padLeft(3, '0')}';
  String get _audioPath => 'assets/audio/$_bookDir/quiz_ox.mp3';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final jsonStr = await rootBundle
          .loadString('assets/audio/$_bookDir/quiz_ox.json');
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final questions = (data['questions'] as List<dynamic>)
          .map((e) => OxQuestion.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      if (!mounted) return;
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      await _playCurrentQuestion();
    } catch (_) {
      // 이 책에 아직 퀴즈가 없으면 결과 없이 허브로 돌아간다.
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _playCurrentQuestion() async {
    final q = _questions[_index];
    // quiz_ox.mp3는 모든 질문이 이어진 하나의 파일이라, 다음 질문까지
    // 흘러 들어가지 않도록 이 질문 구간만 클리핑해서 로드한다.
    final clip = await loadClippedSegment(
      _audioPath,
      start: Duration(milliseconds: (q.startTime * 1000).toInt()),
      end: Duration(milliseconds: (q.endTime * 1000).toInt()),
    );
    await _player.setAudioSource(clip);
    await _player.play();
  }

  void _answer(bool value) {
    if (_selectedAnswer != null) return;
    final q = _questions[_index];
    setState(() {
      _selectedAnswer = value;
      if (value == q.answer) _correctCount++;
    });
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
      _selectedAnswer = null;
    });
    _playCurrentQuestion();
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
    final answered = _selectedAnswer != null;
    final isCorrect = answered && _selectedAnswer == q.answer;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.book.title} 퀴즈')),
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
              onPressed: _playCurrentQuestion,
            ),
            Text(
              q.questionEn,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              q.questionKo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _OxButton(
                  label: 'O',
                  color: Colors.green,
                  selected: answered && _selectedAnswer == true,
                  disabled: answered,
                  onTap: () => _answer(true),
                ),
                _OxButton(
                  label: 'X',
                  color: Colors.red,
                  selected: answered && _selectedAnswer == false,
                  disabled: answered,
                  onTap: () => _answer(false),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (answered) ...[
              Text(
                isCorrect ? '정답이에요! 🎉' : '아쉬워요!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                q.feedbackEn,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                q.feedbackKo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
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

class _OxButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _OxButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? color : color.withValues(alpha: 0.15),
          border: Border.all(color: color, width: 3),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
