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
  final path = await _resolveLocalPath(assetPath);
  await player.setFilePath(path);
}

/// 하나의 mp3에 여러 구간(문장/문제/단어)이 이어 붙어 있을 때, 그 중 한
/// 구간만 재생하고 정확히 그 지점에서 멈추도록 클리핑된 AudioSource를
/// 만든다. positionStream을 감시해서 수동으로 pause()하는 방식은 seek나
/// 버퍼링 지연 때문에 다음 구간까지 흘러 들어가는 문제가 있어, 오디오
/// 엔진이 직접 재생 범위를 제한하는 이 방식이 훨씬 안정적이다.
Future<ClippingAudioSource> loadClippedSegment(
  String assetPath, {
  required Duration start,
  required Duration end,
}) async {
  final child = kIsWeb
      ? AudioSource.asset(assetPath)
      : AudioSource.file(await _resolveLocalPath(assetPath));
  return ClippingAudioSource(child: child, start: start, end: end);
}

Future<String> _resolveLocalPath(String assetPath) async {
  final bytes = await rootBundle.load(assetPath);
  final dir = await getTemporaryDirectory();
  final fileName = assetPath.split('/').last;
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    flush: true,
  );
  return file.path;
}
