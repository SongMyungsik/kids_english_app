#!/usr/bin/env python3
"""Azure Neural TTS로 한 문장짜리 짧은 mp3를 생성한다. (효과음/UI 음성용)

여러 책이 공유하는 짧은 음성(예: "Great job!")을 만들 때 쓴다.

사용법 (PowerShell):
    $env:AZURE_SPEECH_KEY = "..."
    $env:AZURE_SPEECH_REGION = "..."
    python scripts/generate_single_tts.py "Great job!" assets/audio/shared/great_job.mp3
"""
import argparse
import os
import sys
from pathlib import Path

import azure.cognitiveservices.speech as speechsdk

DEFAULT_VOICE = "en-US-AnaNeural"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("text")
    parser.add_argument("output_path")
    parser.add_argument("--voice", default=DEFAULT_VOICE)
    args = parser.parse_args()

    key = os.environ.get("AZURE_SPEECH_KEY")
    region = os.environ.get("AZURE_SPEECH_REGION")
    if not key or not region:
        sys.exit("AZURE_SPEECH_KEY / AZURE_SPEECH_REGION 환경변수를 설정해주세요.")

    out_path = Path(args.output_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    speech_config = speechsdk.SpeechConfig(subscription=key, region=region)
    speech_config.set_speech_synthesis_output_format(
        speechsdk.SpeechSynthesisOutputFormat.Audio24Khz96KBitRateMonoMp3
    )
    speech_config.speech_synthesis_voice_name = args.voice

    audio_config = speechsdk.audio.AudioOutputConfig(filename=str(out_path))
    synthesizer = speechsdk.SpeechSynthesizer(
        speech_config=speech_config, audio_config=audio_config
    )

    print(f"[generate_single_tts] synthesizing {args.text!r} with voice={args.voice} ...")
    result = synthesizer.speak_text(args.text)

    if result.reason != speechsdk.ResultReason.SynthesizingAudioCompleted:
        details = speechsdk.CancellationDetails.from_result(result)
        sys.exit(
            f"합성 실패: {result.reason} / {details.reason} / "
            f"{details.error_details}"
        )

    del synthesizer
    del audio_config
    print(f"[generate_single_tts] done: {out_path}")


if __name__ == "__main__":
    main()
