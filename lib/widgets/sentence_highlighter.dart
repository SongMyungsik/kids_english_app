import 'package:flutter/material.dart';

import '../models/sentence.dart';

class SentenceHighlighter extends StatefulWidget {
  final List<SentenceModel> sentences;
  final int currentIndex;
  final ValueChanged<SentenceModel> onTapSentence;

  const SentenceHighlighter({
    super.key,
    required this.sentences,
    required this.currentIndex,
    required this.onTapSentence,
  });

  @override
  State<SentenceHighlighter> createState() => _SentenceHighlighterState();
}

class _SentenceHighlighterState extends State<SentenceHighlighter> {
  late List<GlobalKey> _itemKeys;

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(widget.sentences.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(covariant SentenceHighlighter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sentences.length != _itemKeys.length) {
      _itemKeys = List.generate(widget.sentences.length, (_) => GlobalKey());
    }
    if (widget.currentIndex != oldWidget.currentIndex) {
      _scrollToCurrent();
    }
  }

  void _scrollToCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.currentIndex < 0 ||
          widget.currentIndex >= _itemKeys.length) {
        return;
      }
      final itemContext = _itemKeys[widget.currentIndex].currentContext;
      if (itemContext != null) {
        Scrollable.ensureVisible(
          itemContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: widget.sentences.length,
      itemBuilder: (context, index) {
        final sentence = widget.sentences[index];
        final isActive = index == widget.currentIndex;

        return GestureDetector(
          key: _itemKeys[index],
          onTap: () => widget.onTapSentence(sentence),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive ? Colors.amber.shade200 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sentence.textEn,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sentence.textKo,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
