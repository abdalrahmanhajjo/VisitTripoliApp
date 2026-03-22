import 'dart:typed_data';

import 'package:image/image.dart' as img;

bool videoPostIdsEqual(Set<String>? prev, Set<String> next) {
  if (identical(prev, next)) return true;
  if (prev == null || prev.length != next.length) return false;
  for (final id in next) {
    if (!prev.contains(id)) return false;
  }
  return true;
}

Uint8List? resizeAndCompressForPost(Uint8List bytes, {int maxSize = 1080, int quality = 85}) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final resized = decoded.width > maxSize || decoded.height > maxSize
        ? img.copyResize(decoded, width: decoded.width > decoded.height ? maxSize : null, height: decoded.height > decoded.width ? maxSize : null)
        : decoded;
    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  } catch (_) {
    return null;
  }
}
