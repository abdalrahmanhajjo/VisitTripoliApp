import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../cache/app_cache_manager.dart';
import '../config/api_config.dart';
import '../models/place.dart';

/// Same URL resolution as [AppImage] so relative paths cache correctly.
String _resolvePlaceImageUrl(String raw) {
  if (raw.isEmpty) return raw;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  if (raw.startsWith('/')) {
    final base = ApiConfig.effectiveBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base$raw';
  }
  final base = ApiConfig.effectiveBaseUrl.replaceAll(RegExp(r'/$'), '');
  return '$base/$raw';
}

/// Warms disk + memory cache for place thumbnails (Explore cards, lists).
void schedulePlacesImagePrecache(BuildContext context, List<Place> places) {
  if (!context.mounted || places.isEmpty) return;
  final mq = MediaQuery.of(context);
  // Typical Explore horizontal card aspect (~268×258 logical).
  final logicalW = (mq.size.width * 0.42).clamp(240.0, 340.0);
  const logicalH = 260.0;
  final size = Size(logicalW, logicalH);
  final cm = AppImageCacheManager.instance;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    var count = 0;
    const maxImages = 64;
    for (final place in places) {
      if (count >= maxImages) break;
      if (place.images.isEmpty) continue;
      for (final raw in place.images.take(2)) {
        if (count >= maxImages) break;
        if (raw.isEmpty) continue;
        final tw = size.width.round();
        final th = size.height.round();
        final uri = AppImageCacheManager.resolveNetworkImageUrl(
          _resolvePlaceImageUrl(raw),
          targetWidth: tw,
          targetHeight: th,
        );
        if (uri.isEmpty) continue;
        precacheImage(
          CachedNetworkImageProvider(uri, cacheManager: cm),
          context,
          size: size,
        );
        count++;
      }
    }
  });
}
