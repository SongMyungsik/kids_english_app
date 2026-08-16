#!/usr/bin/env python3
"""Azure Neural TTS로 assets/audio/<book_dir>/picture_quiz.mp3를 생성한다.

picture_quiz.json의 각 문제마다 (1) 질문(question_en)과 (2) 정답 터치 시
재생할 효과음 대사(effect_text) 두 구간을 합성하고, SSML <bookmark>로 얻은
정확한 시작/끝 시간으로 picture_quiz.json의 q_start/q_end,
effect_start/effect_end를 채운다. 기존 파일은 .bak으로 백업한다.

사용법 (PowerShell):
    $env:AZURE_SPEECH_KEY = "..."
    $env:AZURE_SPEECH_REGION = "..."
    python scripts/generate_picture_quiz_tts.py book_003
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
BREAK_MS = 700

ASSETS_ROOT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def build_ssml(questions: list, voice: str) -> str:
    parts = [
        '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" '
        'xml:lang="en-US">',
        f'<voice name="{voice}">',
    ]
    for i, q in enumerate(questions):
        question_text = escape(q["question_en"])
        effect_text = escape(q["effect_text"])
        parts.append(
            f'<bookmark mark="q{i}_start"/>{question_text}'
            f'<bookmark mark="q{i}_end"/>'
        )
        parts.append(f'<break time="{BREAK_MS}ms"/>')
        parts.append(
            f'<bookmark mark="e{i}_start"/>{effect_text}'
            f'<bookmark mark="e{i}_end"/>'
        )
        if i != len(questions) - 1:
            parts.append(f'<break time="{BREAK_MS}ms"/>')
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
    quiz_path = book_path / "picture_quiz.json"
    audio_path = book_path / "picture_quiz.mp3"
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

    tmp_audio_path = book_path / "picture_quiz.mp3.new"
    audio_config = speechsdk.audio.AudioOutputConfig(filename=str(tmp_audio_path))
    synthesizer = speechsdk.SpeechSynthesizer(
        speech_config=speech_config, audio_config=audio_config
    )
    synthesizer.bookmark_reached.connect(on_bookmark)

    print(
        f"[generate_picture_quiz_tts] synthesizing {len(questions)} questions "
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
        qs, qe = f"q{i}_start", f"q{i}_end"
        es, ee = f"e{i}_start", f"e{i}_end"
        for key_name in (qs, qe, es, ee):
            if key_name not in bookmarks:
                sys.exit(f"문제 {i}의 bookmark를 찾지 못했습니다: {key_name!r}")
        q["q_start"] = round(bookmarks[qs], 3)
        q["q_end"] = round(bookmarks[qe], 3)
        q["effect_start"] = round(bookmarks[es], 3)
        q["effect_end"] = round(bookmarks[ee], 3)

    if audio_path.exists():
        shutil.copy2(audio_path, book_path / "picture_quiz.mp3.bak")
    shutil.copy2(quiz_path, book_path / "picture_quiz.json.bak")

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

    print(f"[generate_picture_quiz_tts] done: {audio_path}")
    print(f"[generate_picture_quiz_tts] done: {quiz_path}")


if __name__ == "__main__":
    main()
