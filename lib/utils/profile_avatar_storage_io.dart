import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Saves avatar bytes to app documents directory. Returns the file path or null.
/// [userId] scopes the filename per account (avoids one shared file for all users).
Future<String?> saveProfileAvatarToDevice(List<int> bytes, {String? userId}) async {
  try {
    final safe = (userId ?? 'guest').replaceAll(RegExp(r'[^\w\-]'), '');
    final fileName = 'profile_avatar_$safe.jpg';
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  } catch (e) {
    debugPrint('ProfileAvatarStorage: failed to save $e');
    return null;
  }
}

void clearProfileAvatarFromDevice(String? path) {
  if (path == null || path.isEmpty) return;
  try {
    final f = File(path);
    if (f.existsSync()) f.deleteSync();
  } catch (_) {}
}

Widget buildProfileAvatarImage({
  required String networkUrl,
  String? localPath,
  required double width,
  required double height,
  required Widget placeholder,
  required Widget errorWidget,
}) {
  if (localPath != null &&
      localPath.isNotEmpty &&
      File(localPath).existsSync()) {
    return Image.file(
      File(localPath),
      width: width,
      height: height,
      fit: BoxFit.cover,
      key: ValueKey(localPath),
    );
  }
  return CachedNetworkImage(
    imageUrl: networkUrl,
    width: width,
    height: height,
    fit: BoxFit.cover,
    placeholder: (_, __) => placeholder,
    errorWidget: (_, __, ___) => errorWidget,
  );
}
