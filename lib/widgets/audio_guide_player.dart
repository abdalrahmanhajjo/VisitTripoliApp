import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme/app_theme.dart';

/// In-app audio guide player with play/pause and progress.
class AudioGuidePlayer extends StatefulWidget {
  final String url;
  final String title;
  final String? durationLabel;

  const AudioGuidePlayer({
    super.key,
    required this.url,
    required this.title,
    this.durationLabel,
  });

  @override
  State<AudioGuidePlayer> createState() => _AudioGuidePlayerState();
}

class _AudioGuidePlayerState extends State<AudioGuidePlayer> {
  final _audio = AudioService.instance;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audio.onPlayerStateChanged.listen((_) {
      if (mounted) setState(() {});
    });
    _audio.onPositionChanged.listen((d) {
      if (mounted) setState(() => _position = d);
    });
    _audio.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isThisPlaying = _audio.isPlayingUrl(widget.url);
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          if (isThisPlaying) {
            await _audio.pause();
          } else {
            await _audio.play(widget.url);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        if (widget.durationLabel != null)
                          Text(
                            widget.durationLabel!,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    isThisPlaying ? _formatDuration(_position) : (widget.durationLabel ?? ''),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isThisPlaying ? AppTheme.primaryColor : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              if (isThisPlaying && _duration.inSeconds > 0) ...[
                const SizedBox(height: 10),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    thumbColor: AppTheme.primaryColor,
                    overlayColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                    max: _duration.inMilliseconds.toDouble(),
                    onChanged: (v) => _audio.seek(Duration(milliseconds: v.toInt())),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
