# Kids English App (Phase 1 MVP)

어린이 영어 동화 읽기 앱. Flutter로 제작하며 Windows/Android 타겟.

## 이 zip 안에 들어있는 것

- `lib/` : 전체 Dart 소스 코드 (완성)
- `pubspec.yaml` : 의존성 목록
- `assets/audio/book_001/` : 샘플 timing.json + **무음 placeholder mp3** (실제 성우 음원으로 교체 필요)
- `assets/images/covers/` : placeholder 표지 이미지 (교체 필요)

이 zip에는 `android/`, `windows/` 등 플랫폼 네이티브 폴더가 없습니다.
(빌드 환경에 Flutter SDK가 없어 `flutter create`를 실행하지 못했습니다.)

## 로컬에서 실행하는 방법

1. 압축을 원하는 위치에 풀기 (예: `C:\dev\kids_english_app`)
2. 해당 폴더에서 터미널 열고 플랫폼 폴더 생성:
   ```
   flutter create .
   ```
   → 이미 있는 `lib/`, `pubspec.yaml`은 덮어쓰지 않고 android/windows/ios 등만 새로 생성됩니다.
   (만약 pubspec.yaml을 덮어쓰겠냐고 물으면 **거부(N)** 하세요 — 이미 완성된 버전입니다)

3. 패키지 설치:
   ```
   flutter pub get
   ```

4. Windows 데스크톱 지원 활성화 (처음이라면):
   ```
   flutter config --enable-windows-desktop
   ```

5. 실행:
   ```
   flutter run -d windows
   ```
   또는 안드로이드 에뮬레이터/기기 연결 후
   ```
   flutter run -d android
   ```

## 실행 전 꼭 해야 할 것

- **오디오 교체**: `assets/audio/book_001/full.mp3`는 무음 placeholder입니다. 실제 성우 녹음(또는 고품질 TTS)으로 교체하세요.
- **timing.json 재작성**: 교체한 오디오의 실제 문장별 시작/끝 시간(초)에 맞춰 `assets/audio/book_001/timing.json`을 수정하세요.
- **표지 이미지 교체**: `assets/images/covers/book_001.png`도 실제 일러스트로 교체하세요.
- **마이크 권한 설정**:
  - Android: `android/app/src/main/AndroidManifest.xml`에 아래 추가
    ```xml
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    ```
  - Windows: `record` 패키지가 Windows 데스크톱 녹음을 정식 지원하는지 최신 버전 기준으로 재확인 필요 (지원 범위가 종종 바뀝니다)

## 다음 동화책 추가하는 방법

1. `assets/audio/book_002/`에 `full.mp3`, `timing.json` 추가
2. `assets/images/covers/book_002.png` 추가
3. `pubspec.yaml`의 `assets:` 목록에 `assets/audio/book_002/` 경로 추가
4. `lib/data/seed_books.dart`에 book_002 항목 추가

## 코드 구조 요약

```
lib/
├── main.dart                 앱 진입점, Provider 설정
├── models/                   Book, SentenceModel, UserProgress
├── db/db_helper.dart         sqflite (Windows는 ffi 백엔드)
├── data/seed_books.dart      초기 동화책 메타데이터
├── services/
│   ├── audio_service.dart    녹음/재생 (따라읽기)
│   └── progress_service.dart 완독 기록 저장
├── providers/
│   ├── book_provider.dart    책 목록 로드
│   └── reading_provider.dart 오디오 재생 + 문장 하이라이트 싱크
├── widgets/
│   ├── sentence_highlighter.dart
│   ├── book_card.dart
│   └── record_button.dart    길게 누르면 녹음, 떼면 정지
└── screens/
    ├── home_screen.dart
    ├── bookshelf_screen.dart
    ├── reading_screen.dart   듣기 모드 ↔ 따라읽기 모드 전환 (상단 아이콘)
    └── complete_screen.dart
```

## 다음 단계 (Phase 2 예고)

- 발음 점수 없이 "내 목소리 들어보기"까지가 Phase 1 목표입니다.
- Phase 2에서 Azure Pronunciation Assessment 등 STT 기반 점수화를 붙일 예정입니다.
