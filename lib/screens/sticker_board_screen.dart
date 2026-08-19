import 'package:flutter/material.dart';

import '../models/sticker.dart';
import '../services/sticker_service.dart';

class StickerBoardScreen extends StatefulWidget {
  const StickerBoardScreen({super.key});

  @override
  State<StickerBoardScreen> createState() => _StickerBoardScreenState();
}

class _StickerBoardScreenState extends State<StickerBoardScreen> {
  final _stickerService = StickerService();
  bool _isLoading = true;
  StickerBoard? _board;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final board = await _stickerService.getCurrentBoard();
    final all = await _stickerService.getAllStickers();
    if (!mounted) return;
    setState(() {
      _board = board;
      _totalCount = all.length;
      _isLoading = false;
    });
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 스티커판')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '${_board!.boardNumber}번째 스티커판',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '지금까지 모은 스티커: $_totalCount개',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        stickerBoardSize,
                        (i) => _StickerSlot(
                          sticker: i < _board!.stickers.length
                              ? _board!.stickers[i]
                              : null,
                          formatDate: _formatDate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_board!.isComplete)
                      const Text(
                        '판을 다 채웠어요! 🎉 새 스티커판이 시작돼요',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      )
                    else
                      Text(
                        '${stickerBoardSize - _board!.stickers.length}개 더 모으면 판이 완성돼요',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StickerSlot extends StatelessWidget {
  final Sticker? sticker;
  final String Function(String) formatDate;

  const _StickerSlot({required this.sticker, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final filled = sticker != null;
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.amber.shade100 : Colors.grey.shade100,
        border: Border.all(
          color: filled ? Colors.amber : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: filled
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(sticker!.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  formatDate(sticker!.earnedAt),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            )
          : Icon(Icons.star_border, size: 32, color: Colors.grey.shade300),
    );
  }
}
