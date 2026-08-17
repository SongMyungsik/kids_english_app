import 'package:flutter/material.dart';

import '../models/sentence.dart';

class SentenceHighlighter extends StatefulWidget {
  final List<SentenceModel> sentences;
  final int currentIndex;
  final ValueChanged<SentenceModel> onTapSentence;
  final bool showReplayButton;
  final ValueChanged<SentenceModel>? onReplay;
  final Map<int, String> pageImages;

  const SentenceHighlighter({
    super.key,
    required this.sentences,
    required this.currentIndex,
    required this.onTapSentence,
    this.showReplayButton = false,
    this.onReplay,
    this.pageImages = const {},
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

  Widget _buildSentenceCard(int index) {
    final sentence = widget.sentences[index];
    final isActive = index == widget.currentIndex;
    final showReplay =
        isActive && widget.showReplayButton && widget.onReplay != null;

    return GestureDetector(
      key: _itemKeys[index],
      onTap: () => widget.onTapSentence(sentence),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: EdgeInsets.fromLTRB(14, 14, 14, showReplay ? 32 : 14),
        decoration: BoxDecoration(
          color: isActive ? Colors.amber.shade200 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Column(
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
            if (showReplay)
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => widget.onReplay!(sentence),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.replay,
                      size: 20,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageImages.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: widget.sentences.length,
        itemBuilder: (context, index) => _buildSentenceCard(index),
      );
    }

    // 페이지 삽화가 있는 책: 같은 page 값을 가진 문장들을 한 그룹으로 묶어
    // 그림과 나란히 보여준다. 그림은 페이지마다 좌우로 번갈아 배치한다.
    final pageOrder = <int>[];
    final pageItems = <int, List<int>>{};
    for (var i = 0; i < widget.sentences.length; i++) {
      final page = widget.sentences[i].page;
      if (page == null) continue;
      if (!pageItems.containsKey(page)) {
        pageOrder.add(page);
        pageItems[page] = [];
      }
      pageItems[page]!.add(i);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: pageOrder.length,
      itemBuilder: (context, pageIdx) {
        final page = pageOrder[pageIdx];
        final imagePath = widget.pageImages[page];
        final indices = pageItems[page]!;
        final imageOnLeft = pageIdx.isEven;

        final image = imagePath == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(imagePath, fit: BoxFit.cover),
                  ),
                ),
              );

        final textColumn = Column(
          mainAxisSize: MainAxisSize.min,
          children: indices.map(_buildSentenceCard).toList(),
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: imageOnLeft
                ? [
                    Expanded(child: image),
                    Expanded(child: textColumn),
                  ]
                : [
                    Expanded(child: textColumn),
                    Expanded(child: image),
                  ],
          ),
        );
      },
    );
  }
}
