class PictureQuizChoice {
  final String emoji;
  final String labelEn;
  final bool correct;
  final double emojiSize;

  PictureQuizChoice({
    required this.emoji,
    required this.labelEn,
    required this.correct,
    this.emojiSize = 40,
  });

  factory PictureQuizChoice.fromJson(Map<String, dynamic> json) =>
      PictureQuizChoice(
        emoji: json['emoji'] as String,
        labelEn: json['label_en'] as String,
        correct: json['correct'] as bool,
        emojiSize: (json['emoji_size'] as num?)?.toDouble() ?? 40,
      );
}

class PictureQuizQuestion {
  final int order;
  final String questionEn;
  final String questionKo;
  final List<PictureQuizChoice> choices;
  final String effectText;
  final double qStart;
  final double qEnd;
  final double effectStart;
  final double effectEnd;

  PictureQuizQuestion({
    required this.order,
    required this.questionEn,
    required this.questionKo,
    required this.choices,
    required this.effectText,
    required this.qStart,
    required this.qEnd,
    required this.effectStart,
    required this.effectEnd,
  });

  PictureQuizChoice get correctChoice =>
      choices.firstWhere((c) => c.correct);

  factory PictureQuizQuestion.fromJson(Map<String, dynamic> json) =>
      PictureQuizQuestion(
        order: json['order'] as int,
        questionEn: json['question_en'] as String,
        questionKo: json['question_ko'] as String,
        choices: (json['choices'] as List<dynamic>)
            .map((e) => PictureQuizChoice.fromJson(e as Map<String, dynamic>))
            .toList(),
        effectText: json['effect_text'] as String,
        qStart: (json['q_start'] as num).toDouble(),
        qEnd: (json['q_end'] as num).toDouble(),
        effectStart: (json['effect_start'] as num).toDouble(),
        effectEnd: (json['effect_end'] as num).toDouble(),
      );
}
