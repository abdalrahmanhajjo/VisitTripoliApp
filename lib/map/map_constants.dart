import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'tripoli_geo.dart';

export 'tripoli_geo.dart';

/// [LatLng] for GoogleMap initial targets / fallbacks.
const LatLng kTripoliCenter = LatLng(kTripoliCenterLat, kTripoliCenterLng);

/// Default zoom when focusing one place in detail tabs.
const double kDetailMapZoom = 15;

/// Default zoom when showing a multi-stop tour preview.
const double kTourPreviewMapZoom = 14;

/// Default zoom for the main explore map when not focusing a single place.
const double kExploreMapDefaultZoom = 14;

/// Bounds / fit padding (dp) used when framing multiple markers.
const double kMapFitPaddingDp = 64;
