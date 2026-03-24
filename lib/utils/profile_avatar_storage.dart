import 'package:flutter/widgets.dart';

import 'profile_avatar_storage_stub.dart'
    if (dart.library.io) 'profile_avatar_storage_io.dart' as impl;

Future<String?> saveProfileAvatarToDevice(List<int> bytes, {String? userId}) =>
    impl.saveProfileAvatarToDevice(bytes, userId: userId);
void clearProfileAvatarFromDevice(String? path) =>
    impl.clearProfileAvatarFromDevice(path);

Widget buildProfileAvatarImage({
  required String networkUrl,
  String? localPath,
  required double width,
  required double height,
  required Widget placeholder,
  required Widget errorWidget,
}) =>
    impl.buildProfileAvatarImage(
      networkUrl: networkUrl,
      localPath: localPath,
      width: width,
      height: height,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
