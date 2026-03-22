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

  const ReelVideo({
    super.key,
    required this.reelId,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.isActive,
    required this.isMuted,
    required this.onMuteToggled,
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
    );
  }
}
