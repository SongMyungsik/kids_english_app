import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';

import '../models/book.dart';
import '../models/match_pair.dart';
import '../services/audio_asset_loader.dart';

class MatchPairsScreen extends StatefulWidget {
  final Book book;

  const MatchPairsScreen({super.key, required this.book});

  @override
  State<MatchPairsScreen> createState() => _MatchPairsScreenState();
}

class _MatchPairsScreenState extends State<MatchPairsScreen> {
  final AudioPlayer _wordPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  List<MatchPair> _allPairs = [];
  List<MatchPair> _shuffledWords = [];
  final Set<int> _matched = {};
  bool _isLoading = true;
  int _currentRound = 0;
  int _roundCount = 1;

  String get _bookDir => 'book_${widget.book.id.toString().padLeft(3, '0')}';
  String get _wordsAudioPath => 'assets/audio/$_bookDir/match_pairs.mp3';
  String get _sfxAudioPath => 'assets/audio/$_bookDir/match_complete.mp3';

  String _completionEmoji = '🎉';
  String _completionText = 'Great job!';

  List<MatchPair> get _currentRoundPairs =>
      _allPairs.where((p) => p.round == _currentRound).toList();

  bool get _isRoundComplete =>
      _currentRoundPairs.every((p) => _matched.contains(p.order));

  bool get _isLastRound => _currentRound == _roundCount - 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final jsonStr = await rootBundle
          .loadString('assets/audio/$_bookDir/match_pairs.json');
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final pairs = (data['pairs'] as List<dynamic>)
          .map((e) => MatchPair.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      await loadAudioAsset(_sfxPlayer, _sfxAudioPath);

      if (!mounted) return;
      setState(() {
        _allPairs = pairs;
        _roundCount = pairs.map((p) => p.round).toSet().length;
        _currentRound = 0;
        _shuffledWords = List.of(_currentRoundPairs)..shuffle(Random());
        _completionEmoji = data['completion_emoji'] as String? ?? '🎉';
        _completionText = data['completion_text'] as String? ?? 'Great job!';
        _isLoading = false;
      });
    } catch (_) {
      // 이 책에 아직 짝맞추기 게임이 없으면 결과 없이 허브로 돌아간다.
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _playWord(MatchPair pair) async {
    // match_pairs.mp3는 모든 단어가 이어진 하나의 파일이라, 다음 단어까지
    // 흘러 들어가지 않도록 이 단어 구간만 클리핑해서 로드한다.
    final clip = await loadClippedSegment(
      _wordsAudioPath,
      start: Duration(milliseconds: (pair.startTime * 1000).toInt()),
      end: Duration(milliseconds: (pair.endTime * 1000).toInt()),
    );
    await _wordPlayer.setAudioSource(clip);
    await _wordPlayer.play();
  }

  Future<void> _onMatched(MatchPair pair) async {
    if (_matched.contains(pair.order)) return;
    setState(() => _matched.add(pair.order));
    await _playWord(pair);
    if (_isRoundComplete && _isLastRound) {
      // _wordPlayer.play()가 재생 완료를 기다리지 않고 바로 반환하는
      // 백엔드도 있어(media_kit), 단어 길이만큼 명시적으로 기다린 뒤
      // 완료 음성을 재생한다. 안 그러면 두 음성이 겹쳐서 나온다.
      final wordDurationMs =
          ((pair.endTime - pair.startTime) * 1000).round();
      await Future.delayed(
        Duration(milliseconds: wordDurationMs + 400),
      );
      await _sfxPlayer.seek(Duration.zero);
      await _sfxPlayer.play();
    }
  }

  void _nextRound() {
    setState(() {
      _currentRound++;
      _shuffledWords = List.of(_currentRoundPairs)..shuffle(Random());
    });
  }

  @override
  void dispose() {
    _wordPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final roundPairs = _currentRoundPairs;
    final roundComplete = _isRoundComplete;
    final finalComplete = roundComplete && _isLastRound;
    final matchedInRound =
        roundPairs.where((p) => _matched.contains(p.order)).length;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.book.title} 짝맞추기')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: finalComplete ? 1.0 : 0.6,
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                child: AnimatedOpacity(
                  opacity: finalComplete ? 1.0 : 0.25,
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    _completionEmoji,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (finalComplete)
                Text(
                  _completionText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                )
              else
                Text(
                  '라운드 ${_currentRound + 1} / $_roundCount  ·  '
                  '$matchedInRound / ${roundPairs.length}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              const SizedBox(height: 8),
              const Text(
                '오른쪽 단어를 알맞은 그림으로 끌어다 놓아보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: roundPairs
                          .map((p) => _ImageDropTarget(
                                pair: p,
                                matched: _matched.contains(p.order),
                                onCorrectDrop: () => _onMatched(p),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: _shuffledWords
                          .map((p) => _WordDraggable(
                                pair: p,
                                matched: _matched.contains(p.order),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
              if (roundComplete)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_isLastRound) {
                        Navigator.pop(context, true);
                      } else {
                        _nextRound();
                      }
                    },
                    child: Text(_isLastRound ? '다음으로' : '다음 라운드'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageDropTarget extends StatelessWidget {
  final MatchPair pair;
  final bool matched;
  final VoidCallback onCorrectDrop;

  const _ImageDropTarget({
    required this.pair,
    required this.matched,
    required this.onCorrectDrop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DragTarget<MatchPair>(
        onWillAcceptWithDetails: (details) => !matched,
        onAcceptWithDetails: (details) {
          if (details.data.order == pair.order) {
            onCorrectDrop();
          }
        },
        builder: (context, candidateData, rejectedData) {
          final highlighted = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 72,
            decoration: BoxDecoration(
              color: matched
                  ? Colors.green.shade100
                  : highlighted
                      ? Colors.amber.shade100
                      : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: matched ? Colors.green : Colors.grey.shade400,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(pair.emoji, style: const TextStyle(fontSize: 32)),
                if (matched) ...[
                  const SizedBox(width: 8),
                  Text(
                    pair.wordEn,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WordDraggable extends StatelessWidget {
  final MatchPair pair;
  final bool matched;

  const _WordDraggable({required this.pair, required this.matched});

  @override
  Widget build(BuildContext context) {
    if (matched) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(height: 72),
      );
    }

    final chip = Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        pair.wordEn,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Draggable<MatchPair>(
        data: pair,
        feedback: Material(color: Colors.transparent, child: chip),
        childWhenDragging: Opacity(opacity: 0.3, child: chip),
        child: chip,
      ),
    );
  }
}
