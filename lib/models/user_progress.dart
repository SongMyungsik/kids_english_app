class UserProgress {
  final int bookId;
  final int completedPages;
  final String? lastReadAt;

  UserProgress({
    required this.bookId,
    required this.completedPages,
    this.lastReadAt,
  });

  factory UserProgress.fromMap(Map<String, dynamic> map) => UserProgress(
        bookId: map['book_id'] as int,
        completedPages: map['completed_pages'] as int,
        lastReadAt: map['last_read_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'book_id': bookId,
        'completed_pages': completedPages,
        'last_read_at': lastReadAt,
      };
}
