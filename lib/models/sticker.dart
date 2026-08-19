class Sticker {
  final int? id;
  final int bookId;
  final String bookTitle;
  final String earnedAt;
  final String emoji;

  Sticker({
    this.id,
    required this.bookId,
    required this.bookTitle,
    required this.earnedAt,
    required this.emoji,
  });

  factory Sticker.fromMap(Map<String, dynamic> map) => Sticker(
        id: map['id'] as int?,
        bookId: map['book_id'] as int,
        bookTitle: map['book_title'] as String,
        earnedAt: map['earned_at'] as String,
        emoji: map['emoji'] as String,
      );

  Map<String, dynamic> toMap() => {
        'book_id': bookId,
        'book_title': bookTitle,
        'earned_at': earnedAt,
        'emoji': emoji,
      };
}
