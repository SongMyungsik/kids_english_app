import 'dart:math';

import '../db/db_helper.dart';
import '../models/sticker.dart';

const stickerBoardSize = 5;

const stickerEmojis = [
  '⭐',
  '🌟',
  '🐰',
  '🐻',
  '🦄',
  '🌈',
  '❤️',
  '🐥',
  '🍎',
  '🎈',
];

class StickerBoard {
  final int boardNumber;
  final List<Sticker> stickers;

  StickerBoard({required this.boardNumber, required this.stickers});

  bool get isComplete => stickers.length == stickerBoardSize;
}

class StickerAward {
  final Sticker sticker;
  final int boardNumber;
  final bool boardCompleted;

  StickerAward({
    required this.sticker,
    required this.boardNumber,
    required this.boardCompleted,
  });
}

class StickerService {
  final _random = Random();

  Future<StickerAward> awardSticker({
    required int bookId,
    required String bookTitle,
  }) async {
    final db = await DBHelper.database;
    final emoji = stickerEmojis[_random.nextInt(stickerEmojis.length)];
    final earnedAt = DateTime.now().toIso8601String();
    final id = await db.insert('stickers', {
      'book_id': bookId,
      'book_title': bookTitle,
      'earned_at': earnedAt,
      'emoji': emoji,
    });

    final countRows = await db.rawQuery('SELECT COUNT(*) AS c FROM stickers');
    final total = countRows.first['c'] as int;

    return StickerAward(
      sticker: Sticker(
        id: id,
        bookId: bookId,
        bookTitle: bookTitle,
        earnedAt: earnedAt,
        emoji: emoji,
      ),
      boardNumber: (total / stickerBoardSize).ceil(),
      boardCompleted: total % stickerBoardSize == 0,
    );
  }

  Future<List<Sticker>> getAllStickers() async {
    final db = await DBHelper.database;
    final rows = await db.query('stickers', orderBy: 'earned_at ASC');
    return rows.map(Sticker.fromMap).toList();
  }

  /// 가장 최근에 쌓이고 있는(또는 방금 완성된) 5칸짜리 스티커판을 반환한다.
  Future<StickerBoard> getCurrentBoard() async {
    final all = await getAllStickers();
    if (all.isEmpty) {
      return StickerBoard(boardNumber: 1, stickers: const []);
    }
    final totalBoards = (all.length / stickerBoardSize).ceil();
    final start = (totalBoards - 1) * stickerBoardSize;
    return StickerBoard(
      boardNumber: totalBoards,
      stickers: all.sublist(start),
    );
  }
}
