import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:tripoli_explorer/l10n/app_localizations.dart';

import '../cache/app_cache_manager.dart';

/// Native (iOS/Android/desktop) video for Reels — matches [reel_video_web.dart] UX.
class ReelVideoImpl extends StatefulWidget {
  final String reelId;
  final String videoUrl;
  final String? thumbnailUrl;
  final bool isActive;
  final bool isMuted;
  final VoidCallback onMuteToggled;
  final bool showMuteButton;

  const ReelVideoImpl({
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
  State<ReelVideoImpl> createState() => _ReelVideoImplState();
}

class _ReelVideoImplState extends State<ReelVideoImpl> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _initFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attachController();
  }

  @override
  void didUpdateWidget(covariant ReelVideoImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _attachController();
    } else {
      if (oldWidget.isActive != widget.isActive || oldWidget.isMuted != widget.isMuted) {
        _syncPlayback();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      if (widget.isActive) c.play();
    } else {
      c.pause();
    }
  }

  Future<void> _attachController() async {
    if (widget.videoUrl.isEmpty) return;

    final uri = Uri.tryParse(widget.videoUrl);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      if (mounted) setState(() => _initFailed = true);
      return;
    }

    final c = VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await c.initialize();
    } catch (_) {
      await c.dispose();
      if (mounted) setState(() => _initFailed = true);
      return;
    }

    if (!mounted) {
      await c.dispose();
      return;
    }

    await c.setLooping(true);
    await c.setVolume(widget.isMuted ? 0.0 : 1.0);
    _controller = c;
    _initFailed = false;
    setState(() {});
    _syncPlayback();
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    c?.dispose();
  }

  void _toggleMute() {
    widget.onMuteToggled();
  }

  void _syncPlayback() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    
    // Sync external volume state
    c.setVolume(widget.isMuted ? 0.0 : 1.0);

    if (widget.isActive) {
      c.play();
    } else {
      c.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl.isEmpty) {
      return Container(color: const Color(0xFF0D0D0D));
    }

    if (_initFailed) {
      return Container(
        color: const Color(0xFF0D0D0D),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.white38),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.videoCouldNotPlay,
                style: const TextStyle(color: Colors.white54, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    final c = _controller;
    if (c == null) {
      return _PosterStack(
        thumbnailUrl: widget.thumbnailUrl,
        child: const SizedBox.shrink(),
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (context, VideoPlayerValue v, _) {
        if (v.hasError) {
          return Container(
            color: const Color(0xFF0D0D0D),
            child: Center(
              child: Text(
                v.errorDescription ?? 'Playback error',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!v.isInitialized || v.size.width <= 0 || v.size.height <= 0) {
          return _PosterStack(
            thumbnailUrl: widget.thumbnailUrl,
            child: const SizedBox.shrink(),
          );
        }

        final dur = v.duration;
        final progress = dur.inMilliseconds > 0
            ? (v.position.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: v.size.width,
                height: v.size.height,
                child: VideoPlayer(c),
              ),
            ),
            if (widget.isActive)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 2.5,
                ),
              ),
            if (widget.showMuteButton)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PosterStack extends StatelessWidget {
  const _PosterStack({
    required this.child,
    this.thumbnailUrl,
  });

  final String? thumbnailUrl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final url = thumbnailUrl;
    final mq = MediaQuery.of(context);
    final w = (mq.size.width * mq.devicePixelRatio).round().clamp(200, 1200);
    final h = (mq.size.height * mq.devicePixelRatio).round().clamp(200, 1600);
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFF0D0D0D)),
        if (url != null && url.isNotEmpty)
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            cacheManager: AppImageCacheManager.instance,
            memCacheWidth: w,
            memCacheHeight: h,
            maxWidthDiskCache: w,
            maxHeightDiskCache: h,
            fadeInDuration: Duration.zero,
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        child,
      ],
    );
  }
}
