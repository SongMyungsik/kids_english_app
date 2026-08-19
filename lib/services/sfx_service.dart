import 'package:just_audio/just_audio.dart';

class SfxService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playStickerEarned() async {
    try {
      await _player.setAsset('assets/audio/ui/sticker_earned.wav');
      await _player.play();
    } catch (_) {
      // 효과음은 부가 기능이므로 재생 실패가 완료 화면 흐름을 막지 않게 한다.
    }
  }
}
