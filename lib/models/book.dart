class Book {
  final int id;
  final String title;
  final String level; // 예: "Level 1"
  final String coverImage; // asset 경로
  final String audioPath; // asset 경로 (full.mp3)
  final String timingPath; // asset 경로 (timing.json)

  Book({
    required this.id,
    required this.title,
    required this.level,
    required this.coverImage,
    required this.audioPath,
    required this.timingPath,
  });

  factory Book.fromMap(Map<String, dynamic> map) => Book(
        id: map['id'] as int,
        title: map['title'] as String,
        level: map['level'] as String,
        coverImage: map['cover_image'] as String,
        audioPath: map['audio_path'] as String,
        timingPath: map['timing_path'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'level': level,
        'cover_image': coverImage,
        'audio_path': audioPath,
        'timing_path': timingPath,
      };
}
