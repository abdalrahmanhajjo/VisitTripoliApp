import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_image.dart';

/// Single-image hero matching [PlaceDetailsScreen] treatment: cover backdrop,
/// light blur layer, and full-bleed [BoxFit.contain] foreground (no harsh crop).
class DetailHeroImage extends StatelessWidget {
  final String? imageUrl;
  final Widget? fallback;

  const DetailHeroImage({
    super.key,
    required this.imageUrl,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return fallback ??
          Container(
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: Icon(Icons.image_not_supported_outlined,
                size: 72, color: Colors.grey[500]),
          );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
        final cw = (constraints.maxWidth * dpr).round().clamp(320, 2600);
        final ch = (constraints.maxHeight * dpr).round().clamp(220, 2200);
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: AppImage(
                key: ValueKey('hero_bg_$url'),
                src: url,
                fit: BoxFit.cover,
                cacheWidth: cw,
                cacheHeight: ch,
                placeholder: (_, __) => Container(color: Colors.grey[300]),
                errorWidget: (_, __, ___) => Container(color: Colors.grey[300]),
              ),
            ),
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
            ),
            Center(
              child: AppImage(
                key: ValueKey('hero_fg_$url'),
                src: url,
                fit: BoxFit.contain,
                cacheWidth: cw,
                cacheHeight: ch,
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => Container(color: Colors.grey[300]),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Place-style gradient along the bottom of detail heroes (badges stay readable).
class DetailHeroBottomGradient extends StatelessWidget {
  const DetailHeroBottomGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft event placeholder when there is no image (matches app theme).
class DetailHeroEventFallback extends StatelessWidget {
  const DetailHeroEventFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceColor,
      alignment: Alignment.center,
      child: Icon(
        Icons.event_available_rounded,
        size: 88,
        color: AppTheme.primaryColor.withValues(alpha: 0.45),
      ),
    );
  }
}
