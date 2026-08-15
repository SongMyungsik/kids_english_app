class OxQuestion {
  final int order;
  final String questionEn;
  final String questionKo;
  final bool answer; // true = O(맞음), false = X(틀림)
  final String feedbackEn;
  final String feedbackKo;
  final double startTime; // 초 단위
  final double endTime;

  OxQuestion({
    required this.order,
    required this.questionEn,
    required this.questionKo,
    required this.answer,
    required this.feedbackEn,
    required this.feedbackKo,
    required this.startTime,
    required this.endTime,
  });

  factory OxQuestion.fromJson(Map<String, dynamic> json) => OxQuestion(
        order: json['order'] as int,
        questionEn: json['question_en'] as String,
        questionKo: json['question_ko'] as String,
        answer: json['answer'] as bool,
        feedbackEn: json['feedback_en'] as String,
        feedbackKo: json['feedback_ko'] as String,
        startTime: (json['start'] as num).toDouble(),
        endTime: (json['end'] as num).toDouble(),
      );
}
