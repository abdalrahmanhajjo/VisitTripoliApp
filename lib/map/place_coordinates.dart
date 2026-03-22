import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/place.dart';

extension PlaceMapCoordinates on Place {
  bool get hasMapCoordinates =>
      latitude != null && longitude != null;

  LatLng? get mapLatLng =>
      hasMapCoordinates ? LatLng(latitude!, longitude!) : null;
}

/// Places that have both latitude and longitude.
List<Place> placesWithCoordinates(Iterable<Place> places) =>
    places.where((p) => p.hasMapCoordinates).toList();

/// Non-null [LatLng] list for markers / polylines (skips invalid rows).
List<LatLng> latLngsFromPlaces(Iterable<Place> places) =>
    places.map((p) => p.mapLatLng).whereType<LatLng>().toList();
