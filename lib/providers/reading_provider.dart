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
  String _audioPath = '';
  bool _isClipLoaded = false;

  List<SentenceModel> sentences = [];
  Map<int, String> pageImages = {};
  int currentSentenceIndex = 0;
  bool isPlaying = false;
  bool isLoading = false;

  Future<void> loadBook(Book book) async {
    isLoading = true;
    currentSentenceIndex = 0;
    pageImages = {};
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

      // 페이지 삽화가 있는 책이면 페이지 번호 -> 이미지 경로 맵을 만든다.
      final rawPages = data['pages'] as List<dynamic>?;
      pageImages = {
        for (final p in rawPages ?? <dynamic>[])
          (p as Map<String, dynamic>)['page'] as int: p['image'] as String,
      };

      // 2) 오디오 로드
      _audioPath = book.audioPath;
      debugPrint('[ReadingProvider] loading audio asset: $_audioPath');
      await loadAudioAsset(_player, _audioPath).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[ReadingProvider] !!! audio load TIMED OUT after 10s');
          throw Exception('오디오 로드 타임아웃 (10초)');
        },
      );
      _isClipLoaded = false;
      debugPrint('[ReadingProvider] audio asset loaded successfully');

      _positionSub?.cancel();
      _positionSub = _player.positionStream.listen((position) {
        // 문장 단위로 클리핑된 소스를 재생 중일 때는 위치가 클립 기준
        // (0부터 시작)이라 전체 파일 기준 문장 경계와 비교하면 안 된다.
        // 이 경우 currentSentenceIndex는 playSentenceOnly()에서 이미
        // 직접 설정했으므로 여기서는 건너뛴다.
        if (_isClipLoaded) return;
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

  Future<void> _ensureFullSourceLoaded() async {
    if (!_isClipLoaded) return;
    await loadAudioAsset(_player, _audioPath);
    _isClipLoaded = false;
  }

  Future<void> play() async {
    await _ensureFullSourceLoaded();
    await _player.play();
  }

  Future<void> pause() async => _player.pause();

  /// 전체 듣기 모드: 이 문장부터 이어서 계속 재생한다.
  Future<void> playSentence(SentenceModel sentence) async {
    await _ensureFullSourceLoaded();
    await _player.seek(
      Duration(milliseconds: (sentence.startTime * 1000).toInt()),
    );
    await _player.play();
  }

  /// 한 문장씩 듣기 모드: 이 문장 구간만 재생하고 끝에서 멈춘다.
  Future<void> playSentenceOnly(SentenceModel sentence) async {
    final clip = await loadClippedSegment(
      _audioPath,
      start: Duration(milliseconds: (sentence.startTime * 1000).toInt()),
      end: Duration(milliseconds: (sentence.endTime * 1000).toInt()),
    );
    await _player.setAudioSource(clip);
    _isClipLoaded = true;

    final index = sentences.indexOf(sentence);
    if (index != -1) {
      currentSentenceIndex = index;
      notifyListeners();
    }
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
