// Web-only video element; dart:html is the standard Flutter web approach until package:web migration.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Global set of view-types already registered with the platform view registry.
/// Must be global because factories are global (can't be re-registered).
final Set<String> _registeredViewTypes = {};

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

class _ReelVideoImplState extends State<ReelVideoImpl> {
  double _progress = 0.0;
  Timer? _progressTimer;

  String get _viewType => 'reel-video-${widget.reelId}';

  @override
  void initState() {
    super.initState();
    _registerFactory();
    // Give the browser a frame to mount the element before trying to control it.
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _syncActive();
    });
  }

  void _registerFactory() {
    final vt = _viewType;
    if (_registeredViewTypes.contains(vt)) return;
    _registeredViewTypes.add(vt);
    final videoUrl = widget.videoUrl;
    try {
      ui_web.platformViewRegistry.registerViewFactory(vt, (int viewId) {
        final video = html.VideoElement()
          ..id = vt
          ..loop = true
          ..muted = widget.isMuted
          ..volume = widget.isMuted ? 0.0 : 1.0
          // Prefer metadata until play() — avoids downloading full files for off-screen reels.
          ..preload = 'metadata';

        video.setAttribute('autoplay', '');
        video.setAttribute('playsinline', '');
        video.setAttribute('webkit-playsinline', '');
        video.controls = false;
        video.style
          ..objectFit = 'cover'
          ..width = '100%'
          ..height = '100%'
          ..backgroundColor = '#000000'
          ..display = 'block';

        if (videoUrl.isNotEmpty) {
          video.src = videoUrl;
          // Show a cover frame while video loads
          if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
            video.setAttribute('poster', widget.thumbnailUrl!);
          }
          // Do not call load() here — it forces an aggressive buffer fetch; play() loads enough to start.
        }
        return video;
      });
    } catch (_) {
      // Factory may already exist from a hot reload — that's fine.
    }
  }

  html.VideoElement? get _videoEl =>
      html.document.getElementById(_viewType) as html.VideoElement?;

  Future<void> _syncActive() async {
    if (!mounted) return;
    final el = _videoEl;
    if (el == null) {
      // Element not yet in DOM — retry after another frame.
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) await _syncActive();
      return;
    }

    // Update src in case it changed (e.g. after hot reload).
    if (widget.videoUrl.isNotEmpty && el.src != widget.videoUrl) {
      el.src = widget.videoUrl;
    }

    if (widget.isActive) {
      try {
        // Once this reel is active, allow full buffering for smooth playback.
        el.preload = 'auto';
        // Do not call load() here — it resets the element and clears muted/volume.
        el.muted = widget.isMuted;
        el.volume = widget.isMuted ? 0.0 : 1.0;
        await el.play();
        // Re-apply after play(): some browsers reset muted/volume during play().
        el.muted = widget.isMuted;
        el.volume = widget.isMuted ? 0.0 : 1.0;
        _startProgressTimer(el);
      } catch (_) {
        // Autoplay can be blocked by browser policy until user interaction.
      }
    } else {
      el.preload = 'metadata';
      el.pause();
      _stopProgressTimer();
    }
  }

  void _startProgressTimer(html.VideoElement el) {
    _stopProgressTimer();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      final dur = el.duration;
      final cur = el.currentTime;
      if (dur > 0) {
        final p = (cur / dur).clamp(0.0, 1.0);
        if (mounted) setState(() => _progress = p);
      }
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void _toggleMute() {
    widget.onMuteToggled();
  }

  @override
  void didUpdateWidget(covariant ReelVideoImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      final el = _videoEl;
      if (el != null && widget.videoUrl.isNotEmpty) {
        el.src = widget.videoUrl;
      }
    }
    if (oldWidget.isActive != widget.isActive) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _syncActive();
      });
    }

    if (oldWidget.isMuted != widget.isMuted) {
      final el = _videoEl;
      if (el != null) {
        el.muted = widget.isMuted;
        el.volume = widget.isMuted ? 0.0 : 1.0;
        // WebKit/Chromium often need play() after unmute for audio to unlock.
        if (widget.isActive && !widget.isMuted) {
          el.play().catchError((_) {});
        }
      }
    }
  }

  @override
  void dispose() {
    _stopProgressTimer();
    final el = _videoEl;
    if (el != null) {
      try {
        el.pause();
        el.removeAttribute('src');
        el.load();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl.isEmpty) {
      return Container(color: const Color(0xFF0D0D0D));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // The actual HTML video element
        HtmlElementView(viewType: _viewType),

        // Progress bar at the top
        if (widget.isActive)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _progress,
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
  }
}
