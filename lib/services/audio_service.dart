import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

/// 아이의 목소리를 녹음하고 재생하는 서비스.
/// Phase 1에서는 점수화 없이 "녹음 → 재생 비교"만 지원한다.
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _playbackPlayer = AudioPlayer();
  String? _lastRecordingPath;

  bool get hasRecording => _lastRecordingPath != null;

  Future<bool> startRecording() async {
    if (!await _recorder.hasPermission()) return false;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/my_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    _lastRecordingPath = path;
    return true;
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    if (path != null) _lastRecordingPath = path;
    return path;
  }

  Future<void> playMyVoice() async {
    if (_lastRecordingPath == null) return;
    await _playbackPlayer.setFilePath(_lastRecordingPath!);
    await _playbackPlayer.play();
  }

  Future<bool> isRecording() => _recorder.isRecording();

  void dispose() {
    _recorder.dispose();
    _playbackPlayer.dispose();
  }
}
