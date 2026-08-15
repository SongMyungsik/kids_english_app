import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// setAsset()은 데스크톱(mpv/media_kit)에서 asset 스킴을 제대로 스트리밍하지
/// 못해 재생이 끝까지 가지 않고 멈추는 문제가 있어, 웹이 아니면 실제 파일로
/// 복사한 뒤 setFilePath()로 로드한다. 웹은 파일시스템이 없고
/// just_audio_web이 asset을 정상적으로 처리하므로 setAsset()을 그대로 쓴다.
Future<void> loadAudioAsset(AudioPlayer player, String assetPath) async {
  if (kIsWeb) {
    await player.setAsset(assetPath);
    return;
  }

  final bytes = await rootBundle.load(assetPath);
  final dir = await getTemporaryDirectory();
  final fileName = assetPath.split('/').last;
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    flush: true,
  );
  await player.setFilePath(file.path);
}
