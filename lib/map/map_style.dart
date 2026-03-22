import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Visual style for [GoogleMap.mapType] (shared by main map + any future pickers).
enum MapDisplayStyle {
  normal,
  satellite,
  hybrid,
  terrain,
}

extension MapDisplayStyleMapType on MapDisplayStyle {
  MapType get mapType {
    switch (this) {
      case MapDisplayStyle.normal:
        return MapType.normal;
      case MapDisplayStyle.satellite:
        return MapType.satellite;
      case MapDisplayStyle.hybrid:
        return MapType.hybrid;
      case MapDisplayStyle.terrain:
        return MapType.terrain;
    }
  }
}

/// Legacy index from persisted UI / toggles (0 = normal).
MapType mapTypeFromIndex(int index) {
  switch (index) {
    case 1:
      return MapType.satellite;
    case 2:
      return MapType.hybrid;
    case 3:
      return MapType.terrain;
    default:
      return MapType.normal;
  }
}
