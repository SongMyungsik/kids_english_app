class MatchPair {
  final int order;
  final String emoji;
  final String wordEn;
  final String wordKo;
  final double startTime; // 초 단위 (match_pairs.mp3 안에서의 위치)
  final double endTime;

  MatchPair({
    required this.order,
    required this.emoji,
    required this.wordEn,
    required this.wordKo,
    required this.startTime,
    required this.endTime,
  });

  factory MatchPair.fromJson(Map<String, dynamic> json) => MatchPair(
        order: json['order'] as int,
        emoji: json['emoji'] as String,
        wordEn: json['word_en'] as String,
        wordKo: json['word_ko'] as String,
        startTime: (json['start'] as num).toDouble(),
        endTime: (json['end'] as num).toDouble(),
      );
}
