class SentenceModel {
  final int order;
  final String textEn;
  final String textKo;
  final double startTime; // 초 단위
  final double endTime;

  SentenceModel({
    required this.order,
    required this.textEn,
    required this.textKo,
    required this.startTime,
    required this.endTime,
  });

  factory SentenceModel.fromJson(Map<String, dynamic> json) => SentenceModel(
        order: json['order'] as int,
        textEn: json['text_en'] as String,
        textKo: json['text_ko'] as String,
        startTime: (json['start'] as num).toDouble(),
        endTime: (json['end'] as num).toDouble(),
      );
}
