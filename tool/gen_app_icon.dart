// Generates assets/images/app_icon.png from the Tripoli/Lebanon cedar icon design.
// Run from project root: dart run tool/gen_app_icon.dart
// Requires: dev_dependency image

import 'dart:io';

import 'package:image/image.dart' as img;

void main() async {
  final packageRoot = Directory.current.path;
  if (!packageRoot.endsWith('Figma1') && !packageRoot.endsWith('tripoli_explorer')) {
    final scriptDir = File(Platform.script.toFilePath()).parent.path;
    Directory.current = Directory(scriptDir).parent;
  }
  final outDir = Directory('assets/images');
  if (!await outDir.exists()) outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/app_icon.png');

  const size = 1024;
  const scale = size / 64.0;

  img.Point scalePoint(num x, num y) =>
      img.Point((x * scale).round(), (y * scale).round());

  final backgroundColor = img.ColorRgba8(0x0D, 0x5C, 0x55, 255);
  final white = img.ColorRgba8(255, 255, 255, 255);

  final image = img.Image(width: size, height: size);
  image.clear(backgroundColor);

  final polygons = [
    [img.Point(32, 10), img.Point(48, 38), img.Point(32, 34), img.Point(16, 38)],
    [img.Point(32, 22), img.Point(44, 46), img.Point(32, 42), img.Point(20, 46)],
    [img.Point(32, 34), img.Point(40, 54), img.Point(32, 52), img.Point(24, 54)],
    [img.Point(30, 52), img.Point(34, 52), img.Point(34, 58), img.Point(30, 58)],
  ];

  for (final poly in polygons) {
    final vertices = poly.map((p) => scalePoint(p.x, p.y)).toList();
    img.fillPolygon(image, vertices: vertices, color: white);
  }

  await outFile.writeAsBytes(img.encodePng(image));
  // ignore: avoid_print — CLI tool output
  print('Generated ${outFile.path}');
}
