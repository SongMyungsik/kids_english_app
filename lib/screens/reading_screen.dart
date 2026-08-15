import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/reading_provider.dart';
import '../services/audio_service.dart';
import '../services/progress_service.dart';
import '../widgets/sentence_highlighter.dart';
import '../widgets/record_button.dart';
import 'ox_quiz_screen.dart';

class ReadingScreen extends StatefulWidget {
  final Book book;

  const ReadingScreen({super.key, required this.book});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final AudioService _audioService = AudioService();
  final ProgressService _progressService = ProgressService();
  bool _followMode = false; // false: 듣기 모드, true: 따라읽기 모드

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReadingProvider>().loadBook(widget.book);
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          IconButton(
            icon: Icon(_followMode ? Icons.headphones : Icons.mic),
            tooltip: _followMode ? '듣기 모드로 전환' : '따라읽기 모드로 전환',
            onPressed: () => setState(() => _followMode = !_followMode),
          ),
        ],
      ),
      body: Consumer<ReadingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading || provider.sentences.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: SentenceHighlighter(
                  sentences: provider.sentences,
                  currentIndex: provider.currentSentenceIndex,
                  onTapSentence: (sentence) => provider.playSentence(sentence),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _followMode
                    ? RecordButton(audioService: _audioService)
                    : _buildListenControls(provider),
              ),
              if (provider.isLastSentence)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text(
                      '다 읽었어요! 퀴즈를 풀어요!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await _progressService.markCompleted(widget.book.id);
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OxQuizScreen(book: widget.book),
                          ),
                        );
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListenControls(ReadingProvider provider) {
    return IconButton(
      iconSize: 56,
      icon: Icon(
        provider.isPlaying
            ? Icons.pause_circle_filled
            : Icons.play_circle_filled,
        color: Colors.blue,
      ),
      onPressed: () {
        if (provider.isPlaying) {
          provider.pause();
        } else {
          provider.play();
        }
      },
    );
  }
}
