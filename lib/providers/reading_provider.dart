import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import '../models/sentence.dart';

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
      // setAsset()은 데스크톱(mpv/media_kit)에서 asset 스킴을 제대로 스트리밍하지
      // 못해 재생이 끝까지 가지 않고 멈추는 문제가 있어, 실제 파일로 복사한 뒤
      // setFilePath()로 로드한다. 웹은 파일시스템이 없고 just_audio_web이
      // asset을 정상적으로 처리하므로 setAsset()을 그대로 쓴다.
      debugPrint('[ReadingProvider] loading audio asset: ${book.audioPath}');
      final Future<void> setSource;
      if (kIsWeb) {
        setSource = _player.setAsset(book.audioPath);
      } else {
        final audioFile = await _copyAssetToTempFile(book.audioPath);
        debugPrint(
            '[ReadingProvider] copied audio asset to: ${audioFile.path}');
        setSource = _player.setFilePath(audioFile.path);
      }

      await setSource.timeout(
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

  Future<File> _copyAssetToTempFile(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final dir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
    return file;
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
