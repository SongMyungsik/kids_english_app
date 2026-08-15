import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';

import '../models/book.dart';
import '../models/sentence.dart';
import '../services/audio_asset_loader.dart';

class ReadingProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;

  List<SentenceModel> sentences = [];
  int currentSentenceIndex = 0;
  bool isPlaying = false;
  bool isLoading = false;

  Future<void> loadBook(Book book) async {
    isLoading = true;
    currentSentenceIndex = 0;
    notifyListeners();

    try {
      // 1) timing.json 로드
      debugPrint('[ReadingProvider] loading timing.json: ${book.timingPath}');
      final jsonStr = await rootBundle.loadString(book.timingPath);
      debugPrint(
          '[ReadingProvider] timing.json loaded (${jsonStr.length} chars)');

      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final List<dynamic> rawSentences = data['sentences'] as List<dynamic>;
      sentences = rawSentences
          .map((e) => SentenceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      debugPrint('[ReadingProvider] parsed ${sentences.length} sentences');

      // 2) 오디오 로드
      debugPrint('[ReadingProvider] loading audio asset: ${book.audioPath}');
      await loadAudioAsset(_player, book.audioPath).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[ReadingProvider] !!! audio load TIMED OUT after 10s');
          throw Exception('오디오 로드 타임아웃 (10초)');
        },
      );
      debugPrint('[ReadingProvider] audio asset loaded successfully');

      _positionSub?.cancel();
      _positionSub = _player.positionStream.listen((position) {
        final seconds = position.inMilliseconds / 1000.0;
        final idx = sentences.indexWhere(
          (s) => seconds >= s.startTime && seconds < s.endTime,
        );
        if (idx != -1 && idx != currentSentenceIndex) {
          currentSentenceIndex = idx;
          notifyListeners();
        }
      });

      _player.playerStateStream.listen((state) {
        isPlaying = state.playing;
        notifyListeners();
      });

      isLoading = false;
      notifyListeners();
      debugPrint('[ReadingProvider] loadBook complete');
    } catch (e, st) {
      debugPrint('[ReadingProvider] !!! ERROR in loadBook: $e');
      debugPrint('$st');
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> play() async => _player.play();
  Future<void> pause() async => _player.pause();

  Future<void> playSentence(SentenceModel sentence) async {
    await _player.seek(
      Duration(milliseconds: (sentence.startTime * 1000).toInt()),
    );
    await _player.play();
  }

  bool get isLastSentence =>
      sentences.isNotEmpty && currentSentenceIndex == sentences.length - 1;

  @override
  void dispose() {
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
