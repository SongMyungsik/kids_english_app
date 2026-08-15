#!/usr/bin/env python3
"""Azure Neural TTS로 assets/audio/<book_dir>/match_pairs.mp3를 생성한다.

match_pairs.json에서 단어(word_en)를 읽어와 Azure Neural TTS로 합성하고,
SSML <bookmark>로 얻은 정확한 단어별 시작/끝 시간으로 match_pairs.json의
start/end를 새로 채운다. generate_tts.py / generate_quiz_tts.py와 동일한
방식이며 대상 필드만 다르다. 기존 파일은 .bak으로 백업한다.

사용법 (PowerShell):
    $env:AZURE_SPEECH_KEY = "..."
    $env:AZURE_SPEECH_REGION = "..."
    python scripts/generate_match_tts.py book_003
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

DEFAULT_VOICE = "en-US-AnaNeural"
WORD_BREAK_MS = 600

ASSETS_ROOT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def build_ssml(pairs: list, voice: str) -> str:
    parts = [
        '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" '
        'xml:lang="en-US">',
        f'<voice name="{voice}">',
    ]
    for i, p in enumerate(pairs):
        text = escape(p["word_en"])
        parts.append(
            f'<bookmark mark="w{i}_start"/>{text}<bookmark mark="w{i}_end"/>'
        )
        if i != len(pairs) - 1:
            parts.append(f'<break time="{WORD_BREAK_MS}ms"/>')
    parts.append("</voice></speak>")
    return "".join(parts)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("book_dir", help="예: book_003 (assets/audio/ 아래 폴더명)")
    parser.add_argument("--voice", default=DEFAULT_VOICE)
    args = parser.parse_args()

    key = os.environ.get("AZURE_SPEECH_KEY")
    region = os.environ.get("AZURE_SPEECH_REGION")
    if not key or not region:
        sys.exit("AZURE_SPEECH_KEY / AZURE_SPEECH_REGION 환경변수를 설정해주세요.")

    book_path = ASSETS_ROOT / args.book_dir
    match_path = book_path / "match_pairs.json"
    audio_path = book_path / "match_pairs.mp3"
    if not match_path.exists():
        sys.exit(f"{match_path} 가 없습니다.")

    data = json.loads(match_path.read_text(encoding="utf-8"))
    pairs = sorted(data["pairs"], key=lambda p: p["order"])

    ssml = build_ssml(pairs, args.voice)

    speech_config = speechsdk.SpeechConfig(subscription=key, region=region)
    speech_config.set_speech_synthesis_output_format(
        speechsdk.SpeechSynthesisOutputFormat.Audio24Khz96KBitRateMonoMp3
    )

    bookmarks = {}

    def on_bookmark(evt: speechsdk.SpeechSynthesisBookmarkEventArgs) -> None:
        bookmarks[evt.text] = evt.audio_offset / 10_000_000  # ticks(100ns) -> 초

    tmp_audio_path = book_path / "match_pairs.mp3.new"
    audio_config = speechsdk.audio.AudioOutputConfig(filename=str(tmp_audio_path))
    synthesizer = speechsdk.SpeechSynthesizer(
        speech_config=speech_config, audio_config=audio_config
    )
    synthesizer.bookmark_reached.connect(on_bookmark)

    print(
        f"[generate_match_tts] synthesizing {len(pairs)} words "
        f"with voice={args.voice} ..."
    )
    result = synthesizer.speak_ssml(ssml)

    if result.reason != speechsdk.ResultReason.SynthesizingAudioCompleted:
        details = speechsdk.CancellationDetails.from_result(result)
        sys.exit(
            f"합성 실패: {result.reason} / {details.reason} / "
            f"{details.error_details}"
        )

    del synthesizer
    del audio_config

    for i, p in enumerate(pairs):
        start_key, end_key = f"w{i}_start", f"w{i}_end"
        if start_key not in bookmarks or end_key not in bookmarks:
            sys.exit(f"단어 {i}의 bookmark를 찾지 못했습니다: {p['word_en']!r}")
        p["start"] = round(bookmarks[start_key], 3)
        p["end"] = round(bookmarks[end_key], 3)

    if audio_path.exists():
        shutil.copy2(audio_path, book_path / "match_pairs.mp3.bak")
    shutil.copy2(match_path, book_path / "match_pairs.json.bak")

    for attempt in range(5):
        try:
            shutil.move(str(tmp_audio_path), str(audio_path))
            break
        except PermissionError:
            if attempt == 4:
                raise
            time.sleep(0.5)
    data["pairs"] = pairs
    match_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(f"[generate_match_tts] done: {audio_path}")
    print(f"[generate_match_tts] done: {match_path}")


if __name__ == "__main__":
    main()
