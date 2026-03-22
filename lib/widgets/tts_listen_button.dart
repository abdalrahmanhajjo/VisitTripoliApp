import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../theme/app_theme.dart';

/// Button to listen to text via text-to-speech.
class TtsListenButton extends StatefulWidget {
  final String text;
  final String label;

  const TtsListenButton({
    super.key,
    required this.text,
    this.label = 'Listen',
  });

  @override
  State<TtsListenButton> createState() => _TtsListenButtonState();
}

class _TtsListenButtonState extends State<TtsListenButton> {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    if (mounted) setState(() => _initialized = true);
  }

  Future<void> _toggle() async {
    if (widget.text.trim().isEmpty) return;
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
    } else {
      setState(() => _speaking = true);
      await _tts.speak(widget.text);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || widget.text.trim().isEmpty) return const SizedBox.shrink();
    return Material(
      color: AppTheme.primaryColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                _speaking ? 'Stop' : widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
