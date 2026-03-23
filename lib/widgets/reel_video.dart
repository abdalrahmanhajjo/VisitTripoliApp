import 'package:flutter/widgets.dart';

// Conditional import so this file works on mobile too.
import 'reel_video_io.dart' if (dart.library.html) 'reel_video_web.dart';

/// Inline video player used by Reels (Instagram-like).
class ReelVideo extends StatelessWidget {
  final String reelId;
  final String videoUrl;
  final String? thumbnailUrl;
  final bool isActive;
  final bool isMuted;
  final VoidCallback onMuteToggled;
  /// When false (default), no mute chip is drawn on the video — use for Reels where mute lives on the action rail.
  /// Set true for inline/feed/dialog players that need an on-video control.
  final bool showMuteButton;

  const ReelVideo({
    super.key,
    required this.reelId,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.isActive,
    required this.isMuted,
    required this.onMuteToggled,
    this.showMuteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return ReelVideoImpl(
      reelId: reelId,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      isActive: isActive,
      isMuted: isMuted,
      onMuteToggled: onMuteToggled,
      showMuteButton: showMuteButton,
    );
  }
}
