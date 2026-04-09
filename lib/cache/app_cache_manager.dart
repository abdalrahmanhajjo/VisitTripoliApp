import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../config/api_config.dart';
import '../services/feed_service.dart';

/// Disk + in-memory cache for [CachedNetworkImage] / [AppImage].
///
/// On pull-to-refresh, [evictUrlsForPosts] clears entries for the **previous**
/// list so replaced images at the same URL show up again immediately.
class AppImageCacheManager {
  AppImageCacheManager._();

  static final CacheManager instance = CacheManager(
    Config(
      'tripoli_explorer_images',
      // Shorter than the old 30d default so stale assets refresh without a full clear.
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 1200,
    ),
  );

  /// Normalizes relative API paths and full URLs for cache keys and eviction.
  static String resolveNetworkImageUrl(
    String raw, {
    int? targetWidth,
    int? targetHeight,
  }) {
    if (raw.isEmpty) return raw;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _optimizedImageUrl(
        raw,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
    }
    final base = ApiConfig.effectiveBaseUrl.replaceAll(RegExp(r'/$'), '');
    final resolved = raw.startsWith('/') ? '$base$raw' : '$base/$raw';
    return _optimizedImageUrl(
      resolved,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }

  static String _optimizedImageUrl(
    String url, {
    int? targetWidth,
    int? targetHeight,
  }) {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.hasScheme && uri.host.isNotEmpty)) return url;

    // Only transform known ImageKit CDN URLs; keep other hosts untouched.
    final host = uri.host.toLowerCase();
    final isImageKit = host.contains('imagekit');
    if (!isImageKit) return url;

    // Don't re-apply if transformation already exists.
    if (uri.queryParameters.containsKey('tr') || uri.path.contains('/tr:')) {
      return url;
    }

    final w = (targetWidth ?? 0).clamp(0, 2800);
    final h = (targetHeight ?? 0).clamp(0, 2800);
    final parts = <String>[
      if (w > 0) 'w-$w',
      if (h > 0) 'h-$h',
      // Keep quality balanced for speed while preserving detail.
      'q-72',
      'f-auto',
    ];
    final next = Map<String, String>.from(uri.queryParameters);
    next['tr'] = parts.join(',');
    return uri.replace(queryParameters: next).toString();
  }

  /// Removes a URL from disk cache and Flutter's [ImageCache] (memory).
  static Future<void> evictUrl(String raw) async {
    final url = resolveNetworkImageUrl(raw);
    if (url.isEmpty) return;
    try {
      await CachedNetworkImage.evictFromCache(
        url,
        cacheManager: instance,
      );
    } catch (_) {}
  }

  /// Evicts many URLs in parallel (fast; ignores per-item failures).
  static Future<void> evictUrls(Iterable<String> urls) async {
    final resolved = urls.map(resolveNetworkImageUrl).where((u) => u.isNotEmpty).toSet();
    if (resolved.isEmpty) return;
    await Future.wait(
      resolved.map(
        (url) => CachedNetworkImage.evictFromCache(
          url,
          cacheManager: instance,
        ).catchError((_) => false),
      ),
    );
  }

  /// Collects every image URL referenced by [posts] and evicts them from cache.
  static Future<void> evictUrlsForPosts(List<FeedPost> posts) async {
    if (posts.isEmpty) return;
    final urls = <String>{};
    for (final p in posts) {
      for (final u in p.displayImageUrls) {
        if (u.isNotEmpty) urls.add(u);
      }
      final iu = p.imageUrl;
      final vid = p.videoUrl;
      if (iu != null &&
          iu.isNotEmpty &&
          vid != null &&
          vid.isNotEmpty) {
        urls.add(iu);
      }
      final ap = p.authorPlaceImage;
      if (ap != null && ap.isNotEmpty) urls.add(ap);
    }
    await evictUrls(urls);
  }
}
