#!/usr/bin/env python3
"""Azure Neural TTS로 assets/audio/<book_dir>/full.mp3 + timing.json을 생성한다.

기존 timing.json에서 문장(text_en / text_ko)을 읽어와 Azure Neural TTS로
합성하고, SSML <bookmark>로 얻은 정확한 문장별 시작/끝 시간으로
timing.json의 start/end를 새로 채운다. 기존 파일은 .bak으로 백업한다.

사용법 (PowerShell):
    $env:AZURE_SPEECH_KEY = "..."
    $env:AZURE_SPEECH_REGION = "..."
    python scripts/generate_tts.py book_001
    python scripts/generate_tts.py book_001 --voice en-US-AnaNeural
"""
import argparse
import json
import os
import shutil
import sys
import time
from pathlib import Path
from xml.sax.saxutils import escape

import azure.cognitiveservices.speech as speechsdk

DEFAULT_VOICE = "en-US-AnaNeural"  # 어린이 동화에 어울리는 아이 목소리
SENTENCE_BREAK_MS = 500

ASSETS_ROOT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def build_ssml(sentences: list, voice: str) -> str:
    parts = [
        '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" '
        'xml:lang="en-US">',
        f'<voice name="{voice}">',
    ]
    for i, s in enumerate(sentences):
        text = escape(s["text_en"])
        parts.append(
            f'<bookmark mark="s{i}_start"/>{text}<bookmark mark="s{i}_end"/>'
        )
        if i != len(sentences) - 1:
            parts.append(f'<break time="{SENTENCE_BREAK_MS}ms"/>')
    parts.append("</voice></speak>")
    return "".join(parts)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("book_dir", help="예: book_001 (assets/audio/ 아래 폴더명)")
    parser.add_argument("--voice", default=DEFAULT_VOICE)
    args = parser.parse_args()

    key = os.environ.get("AZURE_SPEECH_KEY")
    region = os.environ.get("AZURE_SPEECH_REGION")
    if not key or not region:
        sys.exit("AZURE_SPEECH_KEY / AZURE_SPEECH_REGION 환경변수를 설정해주세요.")

    book_path = ASSETS_ROOT / args.book_dir
    timing_path = book_path / "timing.json"
    audio_path = book_path / "full.mp3"
    if not timing_path.exists():
        sys.exit(f"{timing_path} 가 없습니다.")

    data = json.loads(timing_path.read_text(encoding="utf-8"))
    sentences = sorted(data["sentences"], key=lambda s: s["order"])

    ssml = build_ssml(sentences, args.voice)

    speech_config = speechsdk.SpeechConfig(subscription=key, region=region)
    speech_config.set_speech_synthesis_output_format(
        speechsdk.SpeechSynthesisOutputFormat.Audio24Khz96KBitRateMonoMp3
    )

    bookmarks = {}

    def on_bookmark(evt: speechsdk.SpeechSynthesisBookmarkEventArgs) -> None:
        bookmarks[evt.text] = evt.audio_offset / 10_000_000  # ticks(100ns) -> 초

    tmp_audio_path = book_path / "full.mp3.new"
    audio_config = speechsdk.audio.AudioOutputConfig(filename=str(tmp_audio_path))
    synthesizer = speechsdk.SpeechSynthesizer(
        speech_config=speech_config, audio_config=audio_config
    )
    synthesizer.bookmark_reached.connect(on_bookmark)

    print(
        f"[generate_tts] synthesizing {len(sentences)} sentences "
        f"with voice={args.voice} ..."
    )
    result = synthesizer.speak_ssml(ssml)

    if result.reason != speechsdk.ResultReason.SynthesizingAudioCompleted:
        details = speechsdk.CancellationDetails.from_result(result)
        sys.exit(
            f"합성 실패: {result.reason} / {details.reason} / "
            f"{details.error_details}"
        )

    # SDK가 파일 핸들을 비동기로 늦게 닫는 경우가 있어, 명시적으로 해제하고
    # 잠깐 대기한 뒤에야 안전하게 이동/삭제할 수 있다.
    del synthesizer
    del audio_config

    for i, s in enumerate(sentences):
        start_key, end_key = f"s{i}_start", f"s{i}_end"
        if start_key not in bookmarks or end_key not in bookmarks:
            sys.exit(f"문장 {i}의 bookmark를 찾지 못했습니다: {s['text_en']!r}")
        s["start"] = round(bookmarks[start_key], 3)
        s["end"] = round(bookmarks[end_key], 3)

    if audio_path.exists():
        shutil.copy2(audio_path, book_path / "full.mp3.bak")
    shutil.copy2(timing_path, book_path / "timing.json.bak")

    for attempt in range(5):
        try:
            shutil.move(str(tmp_audio_path), str(audio_path))
            break
        except PermissionError:
            if attempt == 4:
                raise
            time.sleep(0.5)
    data["sentences"] = sentences
    timing_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(f"[generate_tts] done: {audio_path}")
    print(f"[generate_tts] done: {timing_path}")


if __name__ == "__main__":
    main()
