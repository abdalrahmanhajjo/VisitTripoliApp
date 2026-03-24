import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Stub: no local file storage (e.g. on web). Always use network.
Future<String?> saveProfileAvatarToDevice(List<int> bytes, {String? userId}) async =>
    null;
void clearProfileAvatarFromDevice(String? path) {}

Widget buildProfileAvatarImage({
  required String networkUrl,
  String? localPath,
  required double width,
  required double height,
  required Widget placeholder,
  required Widget errorWidget,
}) {
  return CachedNetworkImage(
    imageUrl: networkUrl,
    width: width,
    height: height,
    fit: BoxFit.cover,
    placeholder: (_, __) => placeholder,
    errorWidget: (_, __, ___) => errorWidget,
  );
}
