import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../cache/app_cache_manager.dart';
import '../models/place.dart';

/// Warms disk + memory cache for the first image of each place (Explore cards, lists).
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
    const maxImages = 28;
    for (final place in places) {
      if (count >= maxImages) break;
      if (place.images.isEmpty) continue;
      final raw = place.images.first;
      if (raw.isEmpty) continue;
      final uri = AppImageCacheManager.resolveNetworkImageUrl(raw);
      if (uri.isEmpty) continue;
      precacheImage(
        CachedNetworkImageProvider(uri, cacheManager: cm),
        context,
        size: size,
      );
      count++;
    }
  });
}
