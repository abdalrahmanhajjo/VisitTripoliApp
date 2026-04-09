import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../cache/app_cache_manager.dart';
import '../config/api_config.dart';

/// Displays image from local asset or network URL.
/// Use asset path (e.g. "assets/images/intro_1.jpg") for bundled images.
/// Use http(s) URL for network images.
/// Relative paths (e.g. /uploads/places/x.jpg) are resolved with ApiConfig.effectiveBaseUrl.
/// For list/grid thumbnails, set [cacheWidth]/[cacheHeight] (e.g. 400x300) to decode at
/// display size and reduce memory and improve scroll performance.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.src,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.cacheWidth,
    this.cacheHeight,
    this.fadeInDuration = Duration.zero,
  });

  final String src;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  /// Decode network image at this width (2x logical px recommended). Ignored for assets.
  final int? cacheWidth;
  /// Decode network image at this height (2x logical px recommended). Ignored for assets.
  final int? cacheHeight;
  /// Shorter fades feel snappier when images are already on disk.
  final Duration fadeInDuration;
  static final Set<String> _failedUrls = <String>{};
  static const int _maxFailedUrls = 512;

  static bool _isAsset(String s) =>
      s.startsWith('assets/') || s.startsWith('asset/');

  static String _resolveUrl(String s) {
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('/')) {
      final base = ApiConfig.effectiveBaseUrl.replaceAll(RegExp(r'/$'), '');
      return '$base$s';
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (_isAsset(src)) {
      return Image.asset(
        src,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            errorWidget?.call(context, src, Object()) ??
            Container(color: Colors.grey[300]),
      );
    }
    final url = AppImageCacheManager.resolveNetworkImageUrl(
      _resolveUrl(src),
      targetWidth: cacheWidth,
      targetHeight: cacheHeight,
    );
    if (_failedUrls.contains(url)) {
      return errorWidget?.call(context, url, Object()) ??
          Container(color: Colors.grey[300]);
    }
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: AppImageCacheManager.instance,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      maxWidthDiskCache: cacheWidth,
      maxHeightDiskCache: cacheHeight,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: const Duration(milliseconds: 60),
      placeholder: placeholder != null
          ? (c, u) => placeholder!(c, u)
          : (_, __) => Container(color: Colors.grey[300]),
      errorWidget: (c, u, e) {
        if (_failedUrls.length >= _maxFailedUrls) {
          _failedUrls.remove(_failedUrls.first);
        }
        _failedUrls.add(u);
        if (errorWidget != null) return errorWidget!(c, u, e);
        return Container(color: Colors.grey[300]);
      },
    );
  }
}
