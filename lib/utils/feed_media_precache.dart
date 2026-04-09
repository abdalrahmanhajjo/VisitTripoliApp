import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../cache/app_cache_manager.dart';
import '../config/api_config.dart';
import '../services/feed_service.dart';

String _resolveMediaUrl(String u) {
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  final base = ApiConfig.effectiveBaseUrl.replaceAll(RegExp(r'/$'), '');
  if (u.startsWith('/')) return '$base$u';
  return '$base/$u';
}

/// Decodes the next feed images after layout so scrolling reveals bitmaps faster.
void scheduleFeedMediaPrecache(BuildContext context, List<FeedPost> posts) {
  if (!context.mounted || posts.isEmpty) return;
  final mq = MediaQuery.of(context);
  final dpr = mq.devicePixelRatio.clamp(1.0, 3.0);
  final w = (mq.size.width * dpr).round().clamp(200, 1200);
  final h = (w / (4 / 3)).round().clamp(150, 900);
  final cm = AppImageCacheManager.instance;
  final size = Size(w.toDouble(), h.toDouble());
  final tw = size.width.round();
  final th = size.height.round();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    var count = 0;
    /// Enough for ~6 rows of a 3-column grid plus a small buffer.
    const maxImages = 18;
    for (final p in posts) {
      if (count >= maxImages) break;
      for (final raw in p.displayImageUrls) {
        if (count >= maxImages) break;
        if (raw.isEmpty) continue;
        final uri = AppImageCacheManager.resolveNetworkImageUrl(
          _resolveMediaUrl(raw),
          targetWidth: tw,
          targetHeight: th,
        );
        precacheImage(
          CachedNetworkImageProvider(uri, cacheManager: cm),
          context,
          size: size,
        );
        count++;
      }
      final thumb = p.imageUrl;
      if (p.videoUrl != null &&
          p.videoUrl!.isNotEmpty &&
          thumb != null &&
          thumb.isNotEmpty &&
          count < maxImages) {
        precacheImage(
          CachedNetworkImageProvider(
            AppImageCacheManager.resolveNetworkImageUrl(
              _resolveMediaUrl(thumb),
              targetWidth: tw,
              targetHeight: th,
            ),
            cacheManager: cm,
          ),
          context,
          size: size,
        );
        count++;
      }
    }
  });
}
