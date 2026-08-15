#!/usr/bin/env python3
"""Azure Neural TTS로 assets/audio/<book_dir>/quiz_ox.mp3를 생성한다.

quiz_ox.json에서 질문(question_en)을 읽어와 Azure Neural TTS로 합성하고,
SSML <bookmark>로 얻은 정확한 질문별 시작/끝 시간으로 quiz_ox.json의
start/end를 새로 채운다. generate_tts.py와 동일한 방식이며 대상 필드만
다르다. 기존 파일은 .bak으로 백업한다.

사용법 (PowerShell):
    $env:AZURE_SPEECH_KEY = "..."
    $env:AZURE_SPEECH_REGION = "..."
    python scripts/generate_quiz_tts.py book_001
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
QUESTION_BREAK_MS = 800

ASSETS_ROOT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def build_ssml(questions: list, voice: str) -> str:
    parts = [
        '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" '
        'xml:lang="en-US">',
        f'<voice name="{voice}">',
    ]
    for i, q in enumerate(questions):
        text = escape(q["question_en"])
        parts.append(
            f'<bookmark mark="q{i}_start"/>{text}<bookmark mark="q{i}_end"/>'
        )
        if i != len(questions) - 1:
            parts.append(f'<break time="{QUESTION_BREAK_MS}ms"/>')
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
    quiz_path = book_path / "quiz_ox.json"
    audio_path = book_path / "quiz_ox.mp3"
    if not quiz_path.exists():
        sys.exit(f"{quiz_path} 가 없습니다.")

    data = json.loads(quiz_path.read_text(encoding="utf-8"))
    questions = sorted(data["questions"], key=lambda q: q["order"])

    ssml = build_ssml(questions, args.voice)

    speech_config = speechsdk.SpeechConfig(subscription=key, region=region)
    speech_config.set_speech_synthesis_output_format(
        speechsdk.SpeechSynthesisOutputFormat.Audio24Khz96KBitRateMonoMp3
    )

    bookmarks = {}

    def on_bookmark(evt: speechsdk.SpeechSynthesisBookmarkEventArgs) -> None:
        bookmarks[evt.text] = evt.audio_offset / 10_000_000  # ticks(100ns) -> 초

    tmp_audio_path = book_path / "quiz_ox.mp3.new"
    audio_config = speechsdk.audio.AudioOutputConfig(filename=str(tmp_audio_path))
    synthesizer = speechsdk.SpeechSynthesizer(
        speech_config=speech_config, audio_config=audio_config
    )
    synthesizer.bookmark_reached.connect(on_bookmark)

    print(
        f"[generate_quiz_tts] synthesizing {len(questions)} questions "
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

    for i, q in enumerate(questions):
        start_key, end_key = f"q{i}_start", f"q{i}_end"
        if start_key not in bookmarks or end_key not in bookmarks:
            sys.exit(f"질문 {i}의 bookmark를 찾지 못했습니다: {q['question_en']!r}")
        q["start"] = round(bookmarks[start_key], 3)
        q["end"] = round(bookmarks[end_key], 3)

    if audio_path.exists():
        shutil.copy2(audio_path, book_path / "quiz_ox.mp3.bak")
    shutil.copy2(quiz_path, book_path / "quiz_ox.json.bak")

    for attempt in range(5):
        try:
            shutil.move(str(tmp_audio_path), str(audio_path))
            break
        except PermissionError:
            if attempt == 4:
                raise
            time.sleep(0.5)
    data["questions"] = questions
    quiz_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(f"[generate_quiz_tts] done: {audio_path}")
    print(f"[generate_quiz_tts] done: {quiz_path}")


if __name__ == "__main__":
    main()
