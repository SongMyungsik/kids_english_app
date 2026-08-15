import 'package:flutter/material.dart';

import '../services/audio_service.dart';

/// 누르고 있는 동안 녹음, 떼면 정지 + 재생 버튼 노출.
class RecordButton extends StatefulWidget {
  final AudioService audioService;

  const RecordButton({super.key, required this.audioService});

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  bool _recording = false;
  bool _hasRecording = false;

  Future<void> _start() async {
    final started = await widget.audioService.startRecording();
    if (started) {
      setState(() => _recording = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마이크 권한이 필요합니다.')),
      );
    }
  }

  Future<void> _stop() async {
    await widget.audioService.stopRecording();
    setState(() {
      _recording = false;
      _hasRecording = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onLongPressStart: (_) => _start(),
          onLongPressEnd: (_) => _stop(),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: _recording ? Colors.red : Colors.blue,
            child: Icon(
              _recording ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        if (_hasRecording) ...[
          const SizedBox(width: 20),
          IconButton(
            iconSize: 40,
            icon: const Icon(Icons.play_circle_fill, color: Colors.green),
            onPressed: () => widget.audioService.playMyVoice(),
          ),
        ],
      ],
    );
  }
}
