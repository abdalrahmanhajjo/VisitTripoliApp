import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'map_constants.dart';

/// Frames [points] in the camera. No-op if empty.
Future<void> animateCameraToFitLatLngs(
  GoogleMapController controller,
  List<LatLng> points, {
  double padding = kMapFitPaddingDp,
  double singlePointZoom = 16,
}) async {
  if (points.isEmpty) return;
  if (points.length == 1) {
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(points.first, singlePointZoom),
    );
    return;
  }
  var minLat = points.first.latitude;
  var maxLat = points.first.latitude;
  var minLng = points.first.longitude;
  var maxLng = points.first.longitude;
  for (final p in points) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }
  // Avoid zero-area bounds (camera / fit can fail on a line or duplicate points).
  const pad = 0.00015;
  if (maxLat - minLat < pad) {
    maxLat += pad;
    minLat -= pad;
  }
  if (maxLng - minLng < pad) {
    maxLng += pad;
    minLng -= pad;
  }
  final bounds = LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
  await controller.animateCamera(
    CameraUpdate.newLatLngBounds(bounds, padding),
  );
}
