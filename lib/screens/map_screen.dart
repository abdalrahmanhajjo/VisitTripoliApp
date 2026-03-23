import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/map_provider.dart';
import '../providers/places_provider.dart';
import '../theme/app_theme.dart';
import '../models/place.dart';
import '../services/route_service.dart';
import '../utils/map_launcher.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_profile_icon_button.dart';
import '../widgets/app_image.dart';
import '../map/map_camera_utils.dart';
import '../map/map_constants.dart';
import '../map/map_style.dart';
import '../map/place_coordinates.dart';
import '../widgets/route_origin_picker.dart';

/// True when deep link should run [MapScreen] in-app routing (not "view only").
bool mapWantsRouteIntent(Map<String, String> params) {
  if (params['pickStartOnMap'] == '1') return true;
  final tour = params['tourPlaces'];
  if (tour != null && tour.isNotEmpty) return true;
  final rf = params['routeFrom'];
  if (rf != null && rf.isNotEmpty) return true;
  final pid = params['placeId'];
  if (pid != null && pid.isNotEmpty && params.containsKey('travelMode')) {
    return true;
  }
  return false;
}

/// Haversine distance in meters (for polyline sanity checks).
double _haversineMeters(LatLng a, LatLng b) {
  const earthM = 6371000.0;
  double rad(double d) => d * math.pi / 180.0;
  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final lat1 = rad(a.latitude);
  final lat2 = rad(b.latitude);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * earthM * math.asin(math.min(1.0, math.sqrt(h)));
}

List<LatLng> _dedupeAdjacentPolylinePoints(List<LatLng> pts) {
  if (pts.length < 2) return pts;
  final out = <LatLng>[pts.first];
  for (var i = 1; i < pts.length; i++) {
    final a = out.last;
    final b = pts[i];
    if ((a.latitude - b.latitude).abs() < 1e-7 &&
        (a.longitude - b.longitude).abs() < 1e-7) {
      continue;
    }
    out.add(b);
  }
  return out;
}

/// Thin very dense routes — web GL can glitch with 5k+ vertices + wide strokes.
List<LatLng> _subsamplePolyline(List<LatLng> pts, int maxPoints) {
  if (pts.length <= maxPoints) return pts;
  final step = (pts.length / maxPoints).ceil();
  final out = <LatLng>[];
  for (var i = 0; i < pts.length; i += step) {
    out.add(pts[i]);
  }
  final last = pts.last;
  if (out.isEmpty ||
      (out.last.latitude - last.latitude).abs() > 1e-7 ||
      (out.last.longitude - last.longitude).abs() > 1e-7) {
    out.add(last);
  }
  return out;
}

/// Split where consecutive vertices jump (bad merge / ferry / data glitch) so we
/// don't draw one long chord across the map.
List<List<LatLng>> _splitPolylineByLargeGaps(
  List<LatLng> pts, {
  double maxJumpM = 4000,
}) {
  if (pts.length < 2) return pts.isEmpty ? [] : [pts];
  final chunks = <List<LatLng>>[];
  var cur = <LatLng>[pts[0]];
  for (var i = 1; i < pts.length; i++) {
    final prev = cur.last;
    final p = pts[i];
    if (_haversineMeters(prev, p) > maxJumpM) {
      if (cur.length >= 2) chunks.add(cur);
      cur = <LatLng>[p];
    } else {
      cur.add(p);
    }
  }
  if (cur.length >= 2) chunks.add(cur);
  return chunks;
}

bool _mapParamsEqual(Map<String, String>? a, Map<String, String>? b) {
  final ma = a ?? const <String, String>{};
  final mb = b ?? const <String, String>{};
  if (ma.length != mb.length) return false;
  for (final e in ma.entries) {
    if (mb[e.key] != e.value) return false;
  }
  return true;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.queryParams});

  final Map<String, String>? queryParams;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  int _tourStepIndex = 0;
  MapDisplayStyle _mapStyle = MapDisplayStyle.normal;
  String? _categoryFilter;
  bool _trafficEnabled = true;

  RouteResult? _activeRoute;
  ll.LatLng? _routeOrigin;
  Place? _routeDestination;
  String _routeOriginName = '';
  String _activeTravelMode = MapLauncher.driving;
  bool _routeLoading = false;
  bool _routeParamsHandled = false;
  bool _isNavigating = false;
  bool _awaitingMapStartPick = false;
  List<Place> _pendingStartPickDestinations = const [];
  String _pendingStartPickTravelMode = MapLauncher.driving;
  /// True when the route was built from the user's live GPS (not a map-picked point).
  bool _navigationFollowsDeviceGps = false;

  /// OSRM road geometry for tour/trip preview (empty until resolved).
  String? _tourPreviewInFlightKey;
  String? _tourPreviewResolvedKey;
  List<LatLng>? _tourPreviewPoints;

  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _simulatedPosition;
  double _simulatedBearing = 0.0;

  Future<({double lat, double lng})?> _resolveLiveOrigin(
    MapProvider mapProvider,
  ) async {
    if (mapProvider.currentPosition == null) {
      await mapProvider.getCurrentLocation();
    }
    final pos = mapProvider.currentPosition;
    if (pos == null) return null;
    return (lat: pos.latitude, lng: pos.longitude);
  }

  static const _categoryFilters = [
    ('all', 'All', null),
    ('souks', 'Souks', FontAwesomeIcons.store),
    ('historical', 'Historical', FontAwesomeIcons.landmark),
    ('mosques', 'Mosques', FontAwesomeIcons.mosque),
    ('food', 'Food', FontAwesomeIcons.utensils),
    ('cultural', 'Cultural', FontAwesomeIcons.masksTheater),
    ('architecture', 'Architecture', FontAwesomeIcons.archway),
  ];

  @override
  void initState() {
    super.initState();
    final categoryFromParams = widget.queryParams?['category'];
    if (categoryFromParams != null &&
        categoryFromParams.isNotEmpty &&
        categoryFromParams != 'all') {
      _categoryFilter = categoryFromParams.toLowerCase();
    }
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapParamsEqual(oldWidget.queryParams, widget.queryParams)) {
      _routeParamsHandled = false;
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fitBounds(List<LatLng> points) async {
    if (points.isEmpty) return;
    final controller = await _mapController.future;
    await animateCameraToFitLatLngs(controller, points);
  }

  Future<void> _loadTourPreviewRoute(
    List<Place> places,
    String travelMode,
  ) async {
    final key = places.map((p) => p.id).join(',');
    if (places.length < 2 || key.isEmpty) return;
    if (_tourPreviewInFlightKey == key || _tourPreviewResolvedKey == key) return;
    _tourPreviewInFlightKey = key;
    setState(() {});

    final effective =
        travelMode == MapLauncher.transit ? 'walking' : travelMode;
    final rr = await RouteService.getRouteWithWaypoints(
      waypoints:
          places.map((p) => ll.LatLng(p.latitude!, p.longitude!)).toList(),
      travelMode: effective,
    );

    if (!mounted) return;
    setState(() {
      _tourPreviewInFlightKey = null;
      _tourPreviewResolvedKey = key;
      _tourPreviewPoints =
          rr?.polyline.map((p) => LatLng(p.latitude, p.longitude)).toList();
    });
  }

  Future<void> _loadRouteFromParams(BuildContext context,
      {int retryCount = 0}) async {
    final params = widget.queryParams ?? {};
    final routeFrom = params['routeFrom'];
    final pickStartOnMap = params['pickStartOnMap'] == '1';
    final placeId = params['placeId'];
    final tourPlacesStr = params['tourPlaces'];
    final travelMode = params['travelMode'] ?? MapLauncher.driving;
    final originType = params['originType']; // "map" only when explicitly chosen on map.
    String originName = 'Start';
    try {
      originName = Uri.decodeComponent(params['originName'] ?? 'Start');
    } catch (_) {}

    // Need a destination (single place or tour list). routeFrom is optional: omitted => live GPS.
    if (!pickStartOnMap && placeId == null && tourPlacesStr == null) {
      return;
    }

    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    List<Place> destinations = [];
    if (placeId != null) {
      Place? p = placesProvider.getPlaceById(placeId);
      if (p != null) destinations.add(p);
    } else if (tourPlacesStr != null) {
      final ids = tourPlacesStr.split(',');
      for (final id in ids) {
        Place? p = placesProvider.getPlaceById(id);
        if (p != null) destinations.add(p);
      }
    }

    if (destinations.isEmpty) {
      if (retryCount < 5) {
        Future.delayed(Duration(milliseconds: 300 + retryCount * 200), () {
          if (!mounted) return;
          // ignore: use_build_context_synchronously - guarded by mounted check
          _loadRouteFromParams(context, retryCount: retryCount + 1);
        });
      }
      return;
    }

    if (pickStartOnMap) {
      setState(() {
        _awaitingMapStartPick = true;
        _pendingStartPickDestinations = destinations;
        _pendingStartPickTravelMode = travelMode;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tap any point on the map to choose route start'),
          ),
        );
      }
      return;
    }

    final mapProvider = Provider.of<MapProvider>(context, listen: false);

    // No coordinates in URL => always use current device location (in-app only).
    if (routeFrom == null || routeFrom.isEmpty) {
      final live = await _resolveLiveOrigin(mapProvider);
      if (!context.mounted) return;
      if (live != null) {
        _showInAppDirections(
          context,
          live.lat,
          live.lng,
          destinations,
          travelMode,
          'My Location',
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location needed for directions. Enable GPS or pick a start point on the map.',
            ),
          ),
        );
      }
      return;
    }

    final parts = routeFrom.split(',');
    if (parts.length != 2) return;
    final originLat = double.tryParse(parts[0]);
    final originLng = double.tryParse(parts[1]);
    if (originLat == null || originLng == null) return;

    // Default: ignore stale/query coords and use live GPS unless explicitly map-saved.
    if (originType != 'map') {
      final live = await _resolveLiveOrigin(mapProvider);
      if (!context.mounted) return;
      if (live != null) {
        _showInAppDirections(
          context,
          live.lat,
          live.lng,
          destinations,
          travelMode,
          'My Location',
        );
        return;
      }
    }

    if (!context.mounted) return;
    _showInAppDirections(
      context,
      originLat,
      originLng,
      destinations,
      travelMode,
      originName,
    );
  }

  void _showInAppDirections(
    BuildContext context,
    double originLat,
    double originLng,
    List<Place> destinations,
    String travelMode,
    String originName,
  ) async {
    final validDests = placesWithCoordinates(destinations);
    if (validDests.isEmpty) return;

    // No external MapLauncher calls allowed. Map transit -> walking visually.
    final effectiveMode = travelMode == MapLauncher.transit ? 'walking' : travelMode;

    setState(() => _routeLoading = true);

    try {
      RouteResult? result;
      if (validDests.length == 1) {
        result = await RouteService.getRoute(
          originLat: originLat,
          originLng: originLng,
          destLat: validDests.first.latitude!,
          destLng: validDests.first.longitude!,
          travelMode: effectiveMode,
        );
      } else {
        final waypoints = [
          ll.LatLng(originLat, originLng),
          ...validDests.map((p) => ll.LatLng(p.latitude!, p.longitude!)),
        ];
        result = await RouteService.getRouteWithWaypoints(
          waypoints: waypoints,
          travelMode: effectiveMode,
        );
      }

      if (mounted) {
        if (result != null) {
          final followsGps = originName == 'My Location';
          setState(() {
            _tourPreviewPoints = null;
            _tourPreviewResolvedKey = null;
            _tourPreviewInFlightKey = null;
            _activeRoute = result;
            _activeTravelMode = travelMode;
            _routeOrigin = ll.LatLng(originLat, originLng);
            _routeDestination = validDests.length == 1 ? validDests.first : Place(
              id: 'tour_route',
              name: '${validDests.length} Stops Tour',
              category: 'Tour',
              location: 'Multiple Locations',
              description: '',
              latitude: validDests.last.latitude,
              longitude: validDests.last.longitude,
              images: const [],
            );
            _routeOriginName = originName;
            _navigationFollowsDeviceGps = followsGps;
          });

          final points = [
            LatLng(originLat, originLng),
            ...validDests.map((p) => LatLng(p.latitude!, p.longitude!)),
            if (result.polyline.isNotEmpty)
              ...result.polyline.map((p) => LatLng(p.latitude, p.longitude)),
          ];
          _fitBounds(points);
        } else {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not calculate in-app route. Please try another mode.')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _routeLoading = false);
      }
    }
  }

  void _showMapStyleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Map type',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...[
                  (MapDisplayStyle.normal, 'Standard', 'Default road map', Icons.map),
                  (
                    MapDisplayStyle.satellite,
                    'Satellite',
                    'Aerial imagery',
                    Icons.satellite_alt
                  ),
                  (
                    MapDisplayStyle.hybrid,
                    'Hybrid',
                    'Satellite + roads',
                    Icons.layers
                  ),
                  (
                    MapDisplayStyle.terrain,
                    'Terrain',
                    'Topographic view',
                    Icons.terrain
                  ),
                ].map<Widget>((s) {
                  final isSelected = _mapStyle == s.$1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? const Color(0xFF4285F4).withValues(alpha: 0.08)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          setState(() => _mapStyle = s.$1);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF4285F4)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  s.$4,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.$2,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      s.$3,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded,
                                    color: Color(0xFF4285F4), size: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final placesProvider = Provider.of<PlacesProvider>(context);

    final params = widget.queryParams ?? {};
    if (!_routeParamsHandled && mapWantsRouteIntent(params)) {
      _routeParamsHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadRouteFromParams(context);
      });
    }
    final placeIdsParam = params['placeIds'];
    final tripOnly = params['tripOnly'] == 'true';
    final tourOnly = params['tourOnly'] == 'true';
    final tripDayLabel = params['tripDayLabel'];
    final focusPlaceId = params['placeId'] ?? params['mapFocusPlaceId'];

    List<String> filterIds = [];
    if (placeIdsParam != null && placeIdsParam.isNotEmpty) {
      filterIds = placeIdsParam
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    var places = placesWithCoordinates(placesProvider.places);
    if (filterIds.isNotEmpty) {
      places = places.where((p) => filterIds.contains(p.id)).toList();
      if (tourOnly || tripOnly) {
        places = placesWithCoordinates(
          filterIds
              .map((id) => placesProvider.getPlaceById(id))
              .whereType<Place>(),
        );
      }
    }
    // Apply category filter when showing all places (not tour/trip)
    if (!tourOnly &&
        !tripOnly &&
        _categoryFilter != null &&
        _categoryFilter != 'all') {
      places = places
          .where((p) => (p.categoryId ?? '').toLowerCase() == _categoryFilter)
          .toList();
    }
    // Apply search filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      places = places
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              (p.category.toLowerCase().contains(query)) ||
              ((p.tags ?? []).any((t) => t.toLowerCase().contains(query))))
          .toList();
    }

    if ((tourOnly || tripOnly) && places.length >= 2 && _activeRoute == null) {
      final idsKey = places.map((p) => p.id).join(',');
      final tm = params['travelMode'] ?? MapLauncher.driving;
      if (_tourPreviewResolvedKey != idsKey && _tourPreviewInFlightKey != idsKey) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _activeRoute != null) return;
          if (_tourPreviewResolvedKey == idsKey || _tourPreviewInFlightKey == idsKey) {
            return;
          }
          _loadTourPreviewRoute(places, tm);
        });
      }
    } else if (!tourOnly && !tripOnly) {
      if (_tourPreviewPoints != null ||
          _tourPreviewResolvedKey != null ||
          _tourPreviewInFlightKey != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _tourPreviewPoints = null;
            _tourPreviewResolvedKey = null;
            _tourPreviewInFlightKey = null;
          });
        });
      }
    }

    LatLng defaultCenter = kTripoliCenter;
    double zoom = kExploreMapDefaultZoom;

    if (focusPlaceId != null) {
      final place = placesProvider.getPlaceById(focusPlaceId);
      if (place?.latitude != null && place?.longitude != null) {
        defaultCenter = LatLng(place!.latitude!, place.longitude!);
        zoom = 15.0;
      }
    } else if (places.length == 1) {
      defaultCenter = LatLng(places[0].latitude!, places[0].longitude!);
      zoom = 15.0;
    }

    final coordinates =
        places.map((p) => LatLng(p.latitude!, p.longitude!)).toList();

    final initialPosition = CameraPosition(
      target: defaultCenter,
      zoom: zoom,
    );

    final showSearchAndFilters = !tourOnly && !tripOnly && _activeRoute == null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: (tourOnly || tripOnly)
          ? AppBar(
              title: Text(
                tripOnly
                    ? (tripDayLabel != null && tripDayLabel.isNotEmpty
                        ? tripDayLabel
                        : 'Trip route')
                    : 'Tour route',
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 2,
              foregroundColor: AppTheme.textPrimary,
              actions: const [
                AppProfileIconButton(iconSize: 22),
              ],
            )
          : null,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialPosition,
            mapType: _mapStyle.mapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            trafficEnabled: _trafficEnabled,
            buildingsEnabled: true,
            mapToolbarEnabled: false,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            minMaxZoomPreference: const MinMaxZoomPreference(2, 21),
            padding: EdgeInsets.only(
              top: showSearchAndFilters ? 200 : 80,
              right: 72,
              bottom: 100,
              left: 16,
            ),
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
              if (places.length > 1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitBounds(coordinates);
                });
              }
            },
            markers: _buildMarkers(
              context,
              places,
              tourOnly,
              tripOnly,
              mapProvider,
              placesProvider,
            ),
            polylines: _buildPolylines(places, tourOnly, tripOnly),
            onTap: (latLng) {
              if (!_awaitingMapStartPick || _pendingStartPickDestinations.isEmpty) {
                return;
              }
              final pendingDests = List<Place>.from(_pendingStartPickDestinations);
              final mode = _pendingStartPickTravelMode;
              setState(() {
                _awaitingMapStartPick = false;
                _pendingStartPickDestinations = const [];
              });
              _showInAppDirections(
                context,
                latLng.latitude,
                latLng.longitude,
                pendingDests,
                mode,
                'Selected map point',
              );
            },
          ),
          if (_awaitingMapStartPick)
            Positioned(
              top: showSearchAndFilters ? 214 : 92,
              left: 16,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_rounded, size: 20, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tap map to choose start point',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _awaitingMapStartPick = false;
                              _pendingStartPickDestinations = const [];
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (showSearchAndFilters) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              elevation: 3,
                              shadowColor: Colors.black.withValues(alpha: 0.2),
                              child: InkWell(
                                onTap: () => _searchFocusNode.requestFocus(),
                                borderRadius: BorderRadius.circular(28),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.search_rounded,
                                        size: 22,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          focusNode: _searchFocusNode,
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Search places, souks, food…',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                        ),
                                      ),
                                      if (_searchController.text.isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                          child: const Icon(
                                            Icons.clear_rounded,
                                            size: 20,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_routeLoading || mapProvider.isLoadingLocation)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          const AppProfileIconButton(iconSize: 22),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _categoryFilters.map((f) {
                            final id = f.$1;
                            final label = f.$2;
                            final icon = f.$3;
                            final isActive = (_categoryFilter ?? 'all') == id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Material(
                                color: isActive
                                    ? const Color(0xFF4285F4)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                elevation: isActive ? 0 : 2,
                                shadowColor:
                                    Colors.black.withValues(alpha: 0.15),
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _categoryFilter =
                                        id == 'all' ? null : id);
                                  },
                                  borderRadius: BorderRadius.circular(18),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (icon != null) ...[
                                          FaIcon(
                                            icon,
                                            size: 14,
                                            color: isActive
                                                ? Colors.white
                                                : AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isActive
                                                ? Colors.white
                                                : AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (places.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            '${places.length} place${places.length == 1 ? '' : 's'} on map',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (places.isEmpty && showSearchAndFilters)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_off_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No places found',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try a different search or category',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (tourOnly || tripOnly)
            _TourMapBar(
              places: places,
              currentIndex: _tourStepIndex,
              mapProvider: mapProvider,
              placesProvider: placesProvider,
              onStepChanged: (i) async {
                setState(() => _tourStepIndex = i);
                if (places[i].latitude != null && places[i].longitude != null) {
                  final ctrl = await _mapController.future;
                  await ctrl.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(places[i].latitude!, places[i].longitude!),
                      16,
                    ),
                  );
                }
              },
              onDirections: () => _showTourDirectionsPicker(
                context,
                places,
                mapProvider,
                placesProvider,
              ),
            ),
          if (_activeRoute != null) ...[
            if (!_isNavigating) ...[
              _DirectionsHeader(
                destinationName: _routeDestination?.name ?? 'Destination',
                originName: _routeOriginName.isNotEmpty ? _routeOriginName : 'Your Location',
                travelMode: _activeTravelMode,
                onClose: () {
                  setState(() {
                    _activeRoute = null;
                    _routeOrigin = null;
                    _routeDestination = null;
                    _routeOriginName = '';
                    _isNavigating = false;
                    _navigationFollowsDeviceGps = false;
                    _tourPreviewResolvedKey = null;
                    _tourPreviewPoints = null;
                    _tourPreviewInFlightKey = null;
                  });
                },
                onSwap: () {
                  if (_routeOrigin != null && 
                      _routeDestination != null && 
                      _routeDestination!.latitude != null &&
                      _routeDestination!.id != 'tour_route') {
                    final oldOriginLat = _routeOrigin!.latitude;
                    final oldOriginLng = _routeOrigin!.longitude;
                    final oldOriginName = _routeOriginName;
                    
                    final newOriginLat = _routeDestination!.latitude!;
                    final newOriginLng = _routeDestination!.longitude!;
                    
                    final newDest = Place(
                      id: 'swapped_dest',
                      name: oldOriginName.isNotEmpty ? oldOriginName : 'Previous Origin',
                      category: 'Custom',
                      location: '',
                      description: '',
                      latitude: oldOriginLat,
                      longitude: oldOriginLng,
                      images: const [],
                    );
                    
                    _showInAppDirections(
                      context,
                      newOriginLat,
                      newOriginLng,
                      [newDest],
                      _activeTravelMode,
                      _routeDestination!.name,
                    );
                  }
                },
                onTapOrigin: () {
                  setState(() {
                    _awaitingMapStartPick = true;
                    _pendingStartPickDestinations = _routeDestination != null && _routeDestination!.id != 'tour_route' 
                        ? [_routeDestination!] : const [];
                    _pendingStartPickTravelMode = _activeTravelMode;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tap any point on the map to choose route start')),
                  );
                },
                onTapDestination: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search for destination from the main map')),
                  );
                },
                onTravelModeChanged: (mode) {
                  if (_routeOrigin != null && _routeDestination != null && _routeDestination!.latitude != null) {
                    _showInAppDirections(
                      context,
                      _routeOrigin!.latitude,
                      _routeOrigin!.longitude,
                      [_routeDestination!],
                      mode,
                      _routeOriginName,
                    );
                  }
                },
              ),
              _DirectionsBottomPanel(
                route: _activeRoute!,
                onStart: () async {
                  if (_routeOrigin == null) return;
                  setState(() {
                    _isNavigating = true;
                    _simulatedPosition = LatLng(_routeOrigin!.latitude, _routeOrigin!.longitude);
                    _simulatedBearing = 0.0;
                  });

                  if (_navigationFollowsDeviceGps) {
                    // Start REAL GPS tracking (route built from current location)
                    _positionStreamSubscription?.cancel();
                    _positionStreamSubscription = Geolocator.getPositionStream(
                      locationSettings: const LocationSettings(
                        accuracy: LocationAccuracy.bestForNavigation,
                        distanceFilter: 2,
                      ),
                    ).listen((Position position) {
                      if (!mounted || !_isNavigating) return;
                      setState(() {
                         _simulatedPosition = LatLng(position.latitude, position.longitude);
                         // Use heading from device hardware if available, otherwise default to 0
                         if (position.heading >= 0) {
                           _simulatedBearing = position.heading;
                         }
                      });
                      _mapController.future.then((ctrl) {
                         ctrl.animateCamera(CameraUpdate.newCameraPosition(
                           CameraPosition(
                             target: _simulatedPosition!,
                             zoom: 18.0,
                             tilt: 60.0,
                             bearing: _simulatedBearing,
                           )
                         ));
                      });
                    });
                  } else {
                    // Not starting from My Location - just do a static 3D camera pan
                    final controller = await _mapController.future;
                    await controller.animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(_routeOrigin!.latitude, _routeOrigin!.longitude),
                        zoom: 18.0,
                        tilt: 60.0,
                        bearing: 0.0,
                      )
                    ));
                  }
                },
              ),
            ] else ...[
              _ActiveNavigationPanel(
                route: _activeRoute!,
                onExit: () async {
                  _positionStreamSubscription?.cancel();
                  setState(() {
                    _isNavigating = false;
                    _simulatedPosition = null;
                    _navigationFollowsDeviceGps = false;
                  });
                  // Restore bounds
                  final validDests = _routeDestination != null ? [_routeDestination!] : [];
                  final points = [
                    LatLng(_routeOrigin!.latitude, _routeOrigin!.longitude),
                    if (validDests.isNotEmpty && validDests.last.latitude != null)
                      LatLng(validDests.last.latitude!, validDests.last.longitude!),
                    ..._activeRoute!.polyline.map((p) => LatLng(p.latitude, p.longitude)),
                  ];
                  if (points.isNotEmpty) _fitBounds(points);
                },
              ),
            ],
          ],
          if (mapProvider.lastLocationError != null && showSearchAndFilters)
            Positioned(
              left: 16,
              right: 16,
              top: 168,
              child: Material(
                color: const Color(0xFFFFF8E1),
                elevation: 3,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Icon(
                          Icons.location_off_outlined,
                          color: AppTheme.warningColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            mapProvider.lastLocationError!,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => mapProvider.clearLocationError(),
                        tooltip: 'Dismiss',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: 12,
            top: showSearchAndFilters ? 200 : 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _GoogleStyleMapControls(
                  onZoomIn: () async {
                    final ctrl = await _mapController.future;
                    await ctrl.animateCamera(CameraUpdate.zoomIn());
                  },
                  onZoomOut: () async {
                    final ctrl = await _mapController.future;
                    await ctrl.animateCamera(CameraUpdate.zoomOut());
                  },
                  onLayers: () => _showMapStyleSheet(context),
                  onMyLocation: () async {
                    await mapProvider.getCurrentLocation();
                    if (!mounted) return;
                    if (mapProvider.currentPosition != null) {
                      final ctrl = await _mapController.future;
                      if (!mounted) return;
                      await ctrl.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(
                            mapProvider.currentPosition!.latitude,
                            mapProvider.currentPosition!.longitude,
                          ),
                          16,
                        ),
                      );
                    } else if (mapProvider.lastLocationError != null) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(mapProvider.lastLocationError!),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  onFitPlaces:
                      places.length > 1 ? () => _fitBounds(coordinates) : null,
                  showFitPlaces: places.length > 1,
                  trafficEnabled: _trafficEnabled,
                  onTrafficToggle: () =>
                      setState(() => _trafficEnabled = !_trafficEnabled),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Set<Marker> _buildMarkers(
    BuildContext context,
    List<Place> places,
    bool tourOnly,
    bool tripOnly,
    MapProvider mapProvider,
    PlacesProvider placesProvider,
  ) {
    final markers = <Marker>{};
    if (_routeOrigin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('route_origin'),
          position: _simulatedPosition ?? LatLng(_routeOrigin!.latitude, _routeOrigin!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 10,
          rotation: _simulatedBearing,
          flat: false,
        ),
      );
    }
    for (var i = 0; i < places.length; i++) {
      final place = places[i];

      if (_isNavigating && !tourOnly && !tripOnly) {
        if (_routeDestination != null && _routeDestination!.id != place.id && _routeDestination!.id != 'tour_route') {
          continue; 
        }
      }

      final showNumber = tourOnly || tripOnly;
      final isActive = showNumber && _tourStepIndex == i;
      markers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: LatLng(place.latitude!, place.longitude!),
          icon: showNumber
              ? BitmapDescriptor.defaultMarkerWithHue(
                  isActive
                      ? BitmapDescriptor.hueGreen
                      : BitmapDescriptor.hueRed,
                )
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: place.name),
          onTap: () =>
              _showPlaceSheet(context, place, mapProvider, placesProvider),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildPolylines(
      List<Place> places, bool tourOnly, bool tripOnly) {
    final polylines = <Polyline>{};
    if (tourOnly || tripOnly) {
      final straight =
          places.map((p) => LatLng(p.latitude!, p.longitude!)).toList();
      final tourPts = (_tourPreviewPoints != null &&
              _tourPreviewPoints!.length >= 2)
          ? _tourPreviewPoints!
          : straight;
      if (tourPts.length >= 2 && _activeRoute == null) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('tour_route'),
            points: tourPts,
            color: AppTheme.primaryColor,
            width: 5,
            geodesic: false,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }
    }
    if (_activeRoute != null && _activeRoute!.polyline.length > 1) {
      var pts = _activeRoute!.polyline
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      pts = _dedupeAdjacentPolylinePoints(pts);
      const maxPts = kIsWeb ? 1000 : 2500;
      if (pts.length > maxPts) {
        pts = _subsamplePolyline(pts, maxPts);
      }
      final chunks = _splitPolylineByLargeGaps(pts);
      for (var i = 0; i < chunks.length; i++) {
        final segment = chunks[i];
        if (segment.length < 2) continue;

        if (kIsWeb) {
          // Single stroke: double-wide outline + dense points can produce grid-like
          // GPU artifacts on google_maps_flutter web.
          polylines.add(
            Polyline(
              polylineId: PolylineId('directions_route_$i'),
              points: segment,
              color: const Color(0xFF4285F4),
              width: 5,
              zIndex: 2,
              geodesic: false,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        } else {
          polylines.add(
            Polyline(
              polylineId: PolylineId('directions_route_outline_$i'),
              points: segment,
              color: const Color(0xFF1B6DFB),
              width: 8,
              zIndex: 1,
              geodesic: false,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
          polylines.add(
            Polyline(
              polylineId: PolylineId('directions_route_inner_$i'),
              points: segment,
              color: const Color(0xFF4285F4),
              width: 5,
              zIndex: 2,
              geodesic: false,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        }
      }
    }
    return polylines;
  }

  Future<void> _showTourDirectionsPicker(
    BuildContext context,
    List<Place> places,
    MapProvider mapProvider,
    PlacesProvider placesProvider,
  ) async {
    if (places.isEmpty) return;
    final myCoords = mapProvider.currentPosition != null
        ? (
            mapProvider.currentPosition!.latitude,
            mapProvider.currentPosition!.longitude
          )
        : null;

    if (!context.mounted) return;
    final result = await showModalBottomSheet<RouteOriginResult?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: RouteOriginPicker(
          myLocationCoords: myCoords,
          destinationName: '${places.length} stops',
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );

    if (result == null || !context.mounted) return;
    final validPlaces = placesWithCoordinates(places);
    if (validPlaces.isEmpty) return;

    if (result.chooseStartOnMap) {
      setState(() {
        _awaitingMapStartPick = true;
        _pendingStartPickDestinations = validPlaces;
        _pendingStartPickTravelMode = result.travelMode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap any point on the map to choose route start'),
        ),
      );
      return;
    }

    final live = await _resolveLiveOrigin(mapProvider);
    if (live == null && !context.mounted) return;
    final originLat = live?.lat ?? result.lat;
    final originLng = live?.lng ?? result.lng;
    final originName = live != null ? 'My Location' : result.originName;
    _showInAppDirections(
      context,
      originLat,
      originLng,
      validPlaces,
      result.travelMode,
      originName,
    );
  }

  void _showPlaceSheet(
    BuildContext context,
    Place place,
    MapProvider mapProvider,
    PlacesProvider placesProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PlaceInfoSheet(
        place: place,
        mapProvider: mapProvider,
        placesProvider: placesProvider,
        parentContext: context,
        onViewOnMap: () {
          Navigator.pop(ctx);
          context.push('/map?placeId=${place.id}');
        },
        onDetails: () {
          Navigator.pop(ctx);
          context.push('/place/${place.id}');
        },
        onClose: () => Navigator.pop(ctx),
        onDirectionsRequested:
            (originLat, originLng, travelMode, originName, chooseStartOnMap) async {
          if (chooseStartOnMap) {
            setState(() {
              _awaitingMapStartPick = true;
              _pendingStartPickDestinations = [place];
              _pendingStartPickTravelMode = travelMode;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tap any point on the map to choose route start'),
              ),
            );
            return;
          }
          final live = await _resolveLiveOrigin(mapProvider);
          if (!context.mounted) return;
          final effectiveLat = live?.lat ?? originLat;
          final effectiveLng = live?.lng ?? originLng;
          final effectiveOriginName = live != null ? 'My Location' : originName;
          _showInAppDirections(
            context,
            effectiveLat,
            effectiveLng,
            [place],
            travelMode,
            effectiveOriginName,
          );
        },
      ),
    );
  }
}

class _ActiveNavigationPanel extends StatelessWidget {
  final RouteResult route;
  final VoidCallback onExit;

  const _ActiveNavigationPanel({
    required this.route,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 40,
      child: SafeArea(
        child: Material(
          elevation: 12,
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        RouteService.formatDuration(route.totalDurationSeconds),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF137333),
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${RouteService.formatDistance(route.totalDistanceMeters)} away',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onExit,
                  icon: const Icon(Icons.close_rounded, size: 22),
                  label: const Text('Exit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TourMapBar extends StatelessWidget {
  final List<Place> places;
  final int currentIndex;
  final MapProvider mapProvider;
  final PlacesProvider placesProvider;
  final void Function(int) onStepChanged;
  final VoidCallback onDirections;

  const _TourMapBar({
    required this.places,
    required this.currentIndex,
    required this.mapProvider,
    required this.placesProvider,
    required this.onStepChanged,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.surfaceColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: currentIndex > 0
                          ? () => onStepChanged(currentIndex - 1)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        'Stop ${currentIndex + 1} of ${places.length}',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: currentIndex < places.length - 1
                          ? () => onStepChanged(currentIndex + 1)
                          : null,
                    ),
                  ],
                ),
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: places.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final p = places[i];
                      final isCurrent = i == currentIndex;
                      return GestureDetector(
                        onTap: () => onStepChanged(i),
                        child: Container(
                          width: 120,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppTheme.primaryColor.withValues(alpha: 0.12)
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: isCurrent
                                ? Border.all(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isCurrent
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: isCurrent
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions, size: 20),
                    label: const Text('Get directions for full tour'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectionsHeader extends StatelessWidget {
  final String destinationName;
  final String originName;
  final String travelMode;
  final VoidCallback onClose;
  final VoidCallback onSwap;
  final VoidCallback onTapOrigin;
  final VoidCallback onTapDestination;
  final ValueChanged<String> onTravelModeChanged;

  const _DirectionsHeader({
    super.key,
    required this.destinationName,
    required this.originName,
    required this.travelMode,
    required this.onClose,
    required this.onSwap,
    required this.onTapOrigin,
    required this.onTapDestination,
    required this.onTravelModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 8,
        color: AppTheme.surfaceColor,
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 6),
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LocationField(
                            icon: Icons.my_location,
                            iconColor: AppTheme.primaryColor,
                            label: originName,
                            onTap: onTapOrigin,
                          ),
                          const SizedBox(height: 8),
                          _LocationField(
                            icon: Icons.location_on,
                            iconColor: AppTheme.errorColor,
                            label: destinationName,
                            onTap: onTapDestination,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24),
                        IconButton(
                          icon: Icon(Icons.swap_vert, color: Colors.grey.shade400, size: 28),
                          onPressed: onSwap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ModeTab(
                    icon: Icons.directions_car_rounded,
                    label: 'Drive',
                    isSelected: travelMode == MapLauncher.driving || travelMode == 'driving',
                    onTap: () => onTravelModeChanged(MapLauncher.driving),
                  ),
                  _ModeTab(
                    icon: Icons.directions_walk_rounded,
                    label: 'Walk',
                    isSelected: travelMode == MapLauncher.walking || travelMode == 'walking',
                    onTap: () => onTravelModeChanged(MapLauncher.walking),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFF1A73E8) : Colors.grey.shade600;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? color : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  const _LocationField({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.isEmpty ? 'Choose location' : label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: label.isEmpty ? Colors.grey.shade500 : AppTheme.textPrimary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionsBottomPanel extends StatefulWidget {
  final RouteResult route;
  final VoidCallback onStart;

  const _DirectionsBottomPanel({
    required this.route,
    required this.onStart,
  });

  @override
  State<_DirectionsBottomPanel> createState() => _DirectionsBottomPanelState();
}

class _DirectionsBottomPanelState extends State<_DirectionsBottomPanel> {
  bool _showSteps = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 16,
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            RouteService.formatDuration(
                                widget.route.totalDurationSeconds),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A73E8), // Google blue
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            RouteService.formatDistance(
                                widget.route.totalDistanceMeters),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: widget.onStart,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Start',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!_showSteps)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 20),
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _showSteps = true),
                    icon: const Icon(Icons.list, size: 20),
                    label: const Text('Steps & more'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              if (_showSteps) ...[
                Divider(height: 1, color: Colors.grey.shade200),
                Container(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    itemCount: widget.route.steps.length,
                    separatorBuilder: (_, __) => Divider(height: 1, indent: 64, color: Colors.grey.shade200),
                    itemBuilder: (_, i) {
                      final step = widget.route.steps[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: i == 0
                                    ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                                    : i == widget.route.steps.length - 1
                                        ? AppTheme.errorColor.withValues(alpha: 0.1)
                                        : const Color(0xFF1A73E8).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  i == 0
                                      ? Icons.trip_origin
                                      : i == widget.route.steps.length - 1
                                          ? Icons.location_on
                                          : Icons.turn_right_rounded,
                                  size: 16,
                                  color: i == 0
                                      ? AppTheme.secondaryColor
                                      : i == widget.route.steps.length - 1
                                          ? AppTheme.errorColor
                                          : const Color(0xFF1A73E8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                step.instruction,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: i == widget.route.steps.length - 1 ? FontWeight.w700 : FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              RouteService.formatDistance(step.distanceMeters),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showSteps = false),
                        icon: const Icon(Icons.expand_more, size: 20),
                        label: const Text('Hide steps'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleStyleMapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onLayers;
  final VoidCallback onMyLocation;
  final VoidCallback? onFitPlaces;
  final bool showFitPlaces;
  final bool trafficEnabled;
  final VoidCallback onTrafficToggle;

  const _GoogleStyleMapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLayers,
    required this.onMyLocation,
    this.onFitPlaces,
    this.showFitPlaces = false,
    required this.trafficEnabled,
    required this.onTrafficToggle,
  });

  Widget _controlCard({
    required Widget child,
    BorderRadius? borderRadius,
  }) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      color: Colors.white,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _controlCard(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ControlButton(
                icon: Icons.add,
                onTap: onZoomIn,
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              _ControlButton(
                icon: Icons.remove,
                onTap: onZoomOut,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _controlCard(
          child: _ControlButton(
            icon: Icons.layers_rounded,
            onTap: onLayers,
            tooltip: 'Map type',
          ),
        ),
        if (showFitPlaces && onFitPlaces != null) ...[
          const SizedBox(height: 8),
          _controlCard(
            child: _ControlButton(
              icon: Icons.fit_screen_rounded,
              onTap: onFitPlaces!,
              tooltip: 'Fit all places',
            ),
          ),
        ],
        const SizedBox(height: 8),
        _controlCard(
          child: _ControlButton(
            icon: Icons.traffic_rounded,
            onTap: onTrafficToggle,
            tooltip: trafficEnabled ? 'Hide traffic' : 'Show traffic',
            isActive: trafficEnabled,
          ),
        ),
        const SizedBox(height: 8),
        _controlCard(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onMyLocation,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.my_location_rounded,
                  color: Color(0xFF4285F4),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool isActive;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              size: 22,
              color: isActive ? const Color(0xFF4285F4) : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PlaceStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _PlaceInfoSheet extends StatelessWidget {
  final Place place;
  final MapProvider mapProvider;
  final PlacesProvider placesProvider;
  final BuildContext parentContext;
  final VoidCallback onViewOnMap;
  final VoidCallback onDetails;
  final VoidCallback onClose;
  final void Function(
    double originLat,
    double originLng,
    String travelMode,
    String originName,
    bool chooseStartOnMap,
  ) onDirectionsRequested;

  const _PlaceInfoSheet({
    required this.place,
    required this.mapProvider,
    required this.placesProvider,
    required this.parentContext,
    required this.onViewOnMap,
    required this.onDetails,
    required this.onClose,
    required this.onDirectionsRequested,
  });

  Future<void> _showRoutePicker(BuildContext context) async {
    final myCoords = mapProvider.currentPosition != null
        ? (
            mapProvider.currentPosition!.latitude,
            mapProvider.currentPosition!.longitude
          )
        : null;

    if (!context.mounted) return;
    final result = await showModalBottomSheet<RouteOriginResult?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: RouteOriginPicker(
          myLocationCoords: myCoords,
          destinationName: place.name,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );

    if (result == null || !context.mounted) return;
    if (!place.hasMapCoordinates) return;

    onDirectionsRequested(
      result.lat,
      result.lng,
      result.travelMode,
      result.originName,
      result.chooseStartOnMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (place.images.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(
                        src: place.images.first,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 12,
                        right: 48,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              place.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            if (place.category.isNotEmpty)
                              Text(
                                place.category,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (place.images.isEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                              if (place.category.isNotEmpty)
                                Text(
                                  place.category,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                  if (place.images.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: place.category.isNotEmpty
                              ? Text(
                                  place.category,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                  if (place.rating != null ||
                      place.duration != null ||
                      place.price != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (place.rating != null)
                          _PlaceStatChip(
                            icon: Icons.star_rounded,
                            label: place.rating!.toStringAsFixed(1),
                            color: AppTheme.accentColor,
                          ),
                        if (place.duration != null)
                          _PlaceStatChip(
                            icon: Icons.schedule_rounded,
                            label: place.duration!,
                            color: AppTheme.primaryColor,
                          ),
                        if (place.price != null)
                          _PlaceStatChip(
                            icon: Icons.payments_rounded,
                            label: place.price!,
                            color: AppTheme.successColor,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _showRoutePicker(parentContext);
                          },
                          icon: const Icon(Icons.directions_rounded, size: 20),
                          label: const Text('Directions'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4285F4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onViewOnMap,
                          icon: const Icon(Icons.near_me_rounded, size: 20),
                          label: const Text('View on map'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5F6368),
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.info_outline, size: 20),
                      label: const Text('Place details'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
