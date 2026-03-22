import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_theme.dart';
import 'map_constants.dart';
import 'place_coordinates.dart';
import '../models/place.dart';

/// Shared [GoogleMap] options for read-only previews (detail tabs).
class EmbeddedMapDefaults {
  EmbeddedMapDefaults._();

  static const minMaxZoom = MinMaxZoomPreference(2, 21);

  static GoogleMap singlePlace({
    required LatLng target,
    required String markerId,
    required String infoTitle,
    double zoom = kDetailMapZoom,
  }) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: target, zoom: zoom),
      markers: {
        Marker(
          markerId: MarkerId(markerId),
          position: target,
          infoWindow: InfoWindow(title: infoTitle),
        ),
      },
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: true,
      minMaxZoomPreference: minMaxZoom,
    );
  }

  static GoogleMap multiStopRoute({
    required List<Place> placesWithCoords,
    double zoom = kTourPreviewMapZoom,
  }) {
    final pts = latLngsFromPlaces(placesWithCoords);
    final center = pts.isNotEmpty ? pts.first : kTripoliCenter;
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: zoom),
      markers: {
        for (var i = 0; i < placesWithCoords.length; i++)
          Marker(
            markerId: MarkerId(placesWithCoords[i].id),
            position: LatLng(
              placesWithCoords[i].latitude!,
              placesWithCoords[i].longitude!,
            ),
            infoWindow: InfoWindow(
              title: '${i + 1}. ${placesWithCoords[i].name}',
            ),
          ),
      },
      polylines: pts.length >= 2
          ? {
              Polyline(
                polylineId: const PolylineId('embedded_route'),
                points: pts,
                color: AppTheme.primaryColor,
                width: 4,
              ),
            }
          : {},
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: true,
      minMaxZoomPreference: minMaxZoom,
    );
  }
}

/// Rounded map card used in scrollable detail UIs.
class DetailMapCard extends StatelessWidget {
  const DetailMapCard({
    super.key,
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: child,
      ),
    );
  }
}
