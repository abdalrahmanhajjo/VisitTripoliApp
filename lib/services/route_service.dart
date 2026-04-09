import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/api_config.dart';

/// Last-resort CORS proxies for web when the app API cannot reach OSRM.
const _corsProxies = [
  'https://corsproxy.org/?',
  'https://api.allorigins.win/raw?url=',
];

/// Turn-by-turn instruction for in-app directions.
class RouteStep {
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final String? maneuverType;
  final String? maneuverModifier;

  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    this.maneuverType,
    this.maneuverModifier,
  });
}

/// Result of a routing request: polyline + steps + summary.
class RouteResult {
  final List<LatLng> polyline;
  final List<RouteStep> steps;
  final double totalDistanceMeters;
  final double totalDurationSeconds;

  const RouteResult({
    required this.polyline,
    required this.steps,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });
}

/// Fetches routes: **Google Directions** (traffic-aware, same provider as Google Maps) when
/// the backend has `GOOGLE_MAPS_API_KEY`, otherwise **OSRM**.
class RouteService {
  static const _osrmPublicBase = 'https://router.project-osrm.org/route/v1';

  /// OSRM profile: driving or walking.
  static String _profile(String travelMode) {
    switch (travelMode) {
      case 'walking':
        return 'foot';
      case 'driving':
      default:
        return 'driving';
    }
  }

  static Uri _backendDirectionsUri(
    String profile,
    String coords, {
    required bool continueStraightAtWaypoints,
  }) {
    final base = ApiConfig.effectiveBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final q = <String, String>{
      'profile': profile,
      'coords': coords,
      'overview': 'full',
      'steps': 'true',
      'geometries': 'geojson',
    };
    if (continueStraightAtWaypoints) {
      q['continue_straight'] = 'true';
    }
    return Uri.parse('$base/api/directions/route').replace(queryParameters: q);
  }

  static Uri _osrmDirectUri(
    String profile,
    String coords, {
    required bool continueStraightAtWaypoints,
  }) {
    final cs =
        continueStraightAtWaypoints ? '&continue_straight=true' : '';
    return Uri.parse(
      '$_osrmPublicBase/$profile/$coords'
      '?overview=full&geometries=geojson&steps=true$cs',
    );
  }

  /// Decodes Google's encoded polyline (`overview_polyline.points`).
  static List<LatLng> decodeEncodedPolyline(String encoded) {
    final poly = <LatLng>[];
    int index = 0;
    final len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b = 0;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      result = result.toSigned(32);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      result = result.toSigned(32);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  static Uri _backendGoogleDirectionsUri({
    required List<LatLng> waypoints,
    required String googleMode,
  }) {
    final base = ApiConfig.effectiveBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final origin = waypoints.first;
    final dest = waypoints.last;
    final q = <String, String>{
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${dest.latitude},${dest.longitude}',
      'mode': googleMode,
    };
    if (waypoints.length > 2) {
      q['waypoints'] = waypoints
          .sublist(1, waypoints.length - 1)
          .map((w) => '${w.latitude},${w.longitude}')
          .join('|');
    }
    return Uri.parse('$base/api/directions/google').replace(queryParameters: q);
  }

  static double _googleNestedValue(Map<String, dynamic> m, String key) {
    final o = m[key] as Map<String, dynamic>?;
    return (o?['value'] as num?)?.toDouble() ?? 0;
  }

  static double _googleLegDurationSeconds(Map<String, dynamic> leg) {
    final dit = leg['duration_in_traffic'] as Map<String, dynamic>?;
    if (dit != null && dit['value'] != null) {
      return (dit['value'] as num).toDouble();
    }
    return _googleNestedValue(leg, 'duration');
  }

  static String _stripGoogleHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _sameLatLng(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 1e-5 &&
        (a.longitude - b.longitude).abs() < 1e-5;
  }

  /// Full path from each step’s polyline (same road geometry as Google Maps when overview is absent).
  static List<LatLng> _mergeGoogleStepPolylines(List<dynamic> legs) {
    final out = <LatLng>[];
    for (final leg in legs) {
      final legMap = leg as Map<String, dynamic>;
      final legSteps = legMap['steps'] as List<dynamic>? ?? [];
      for (final s in legSteps) {
        final stepMap = s as Map<String, dynamic>;
        final polyObj = stepMap['polyline'] as Map<String, dynamic>?;
        final enc = polyObj?['points'] as String?;
        if (enc == null || enc.isEmpty) continue;
        final seg = decodeEncodedPolyline(enc);
        if (seg.isEmpty) continue;
        if (out.isEmpty) {
          out.addAll(seg);
        } else if (_sameLatLng(out.last, seg.first)) {
          out.addAll(seg.skip(1));
        } else {
          out.addAll(seg);
        }
      }
    }
    return out;
  }

  static RouteResult? _parseGoogleDirectionsBody(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return null;
      final routes = json['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      Map<String, dynamic> route = routes.first as Map<String, dynamic>;
      // Web parity: prefer the route with the fastest traffic-aware duration.
      if (routes.length > 1) {
        double best = double.infinity;
        for (final candidate in routes.whereType<Map<String, dynamic>>()) {
          final legs = candidate['legs'] as List<dynamic>? ?? const [];
          var total = 0.0;
          for (final leg in legs.whereType<Map<String, dynamic>>()) {
            total += _googleLegDurationSeconds(leg);
          }
          if (total > 0 && total < best) {
            best = total;
            route = candidate;
          }
        }
      }
      final legs = route['legs'] as List<dynamic>? ?? [];

      final polyObj = route['overview_polyline'] as Map<String, dynamic>?;
      final encoded = polyObj?['points'] as String?;
      List<LatLng> points;
      if (encoded != null && encoded.isNotEmpty) {
        points = decodeEncodedPolyline(encoded);
      } else {
        points = _mergeGoogleStepPolylines(legs);
      }
      if (points.isEmpty) return null;
      // Overview polyline is often heavily simplified (sometimes ~2 points) while step
      // polylines follow roads. Prefer the denser path so the map matches real streets.
      final mergedFromSteps = _mergeGoogleStepPolylines(legs);
      if (mergedFromSteps.length > points.length) {
        points = mergedFromSteps;
      }
      var totalDist = 0.0;
      var totalDur = 0.0;
      final steps = <RouteStep>[];

      for (final leg in legs) {
        final legMap = leg as Map<String, dynamic>;
        totalDist += _googleNestedValue(legMap, 'distance');
        totalDur += _googleLegDurationSeconds(legMap);

        final legSteps = legMap['steps'] as List<dynamic>? ?? [];
        for (final s in legSteps) {
          final stepMap = s as Map<String, dynamic>;
          final html = stepMap['html_instructions'] as String? ?? '';
          final instruction = _stripGoogleHtml(html);
          steps.add(
            RouteStep(
              instruction: instruction.isNotEmpty ? instruction : 'Continue',
              distanceMeters: _googleNestedValue(stepMap, 'distance'),
              durationSeconds: _googleNestedValue(stepMap, 'duration'),
              maneuverType: null,
              maneuverModifier: null,
            ),
          );
        }
      }

      // Still too sparse for a long leg — let OSRM provide full road geometry.
      if (points.length < 3 && totalDist > 2500) {
        return null;
      }

      return RouteResult(
        polyline: points,
        steps: steps,
        totalDistanceMeters: totalDist,
        totalDurationSeconds: totalDur,
      );
    } catch (e, st) {
      debugPrint('RouteService Google parse: $e\n$st');
      return null;
    }
  }

  static Future<RouteResult?> _fetchGoogleDirectionsOnce(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => http.Response('', 408),
      );
      if (response.statusCode != 200 || response.body.isEmpty) {
        return null;
      }
      return _parseGoogleDirectionsBody(response.body);
    } catch (e) {
      debugPrint('RouteService Google fetch: $e');
      return null;
    }
  }

  /// Google Maps–equivalent route when backend has a Directions API key; otherwise null.
  static Future<RouteResult?> _tryGoogleDirections(
    List<LatLng> waypoints,
    String travelMode,
  ) async {
    if (waypoints.length < 2) return null;
    final googleMode =
        (travelMode == 'walking' || travelMode == 'transit') ? 'walking' : 'driving';
    final uri = _backendGoogleDirectionsUri(
      waypoints: waypoints,
      googleMode: googleMode,
    );
    final first = await _fetchGoogleDirectionsOnce(uri);
    if (first != null) return first;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _fetchGoogleDirectionsOnce(uri);
  }

  static Iterable<Uri> _requestUris(
    String profile,
    String coords, {
    required bool continueStraightAtWaypoints,
  }) sync* {
    yield _backendDirectionsUri(
      profile,
      coords,
      continueStraightAtWaypoints: continueStraightAtWaypoints,
    );
    if (!kIsWeb) {
      yield _osrmDirectUri(
        profile,
        coords,
        continueStraightAtWaypoints: continueStraightAtWaypoints,
      );
    } else {
      final target = _osrmDirectUri(
        profile,
        coords,
        continueStraightAtWaypoints: continueStraightAtWaypoints,
      ).toString();
      for (final proxy in _corsProxies) {
        yield Uri.parse('$proxy${Uri.encodeComponent(target)}');
      }
    }
  }

  static RouteResult? _parseOsrmBody(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['code'] != 'Ok') return null;

      final routes = json['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final coordsList = geometry?['coordinates'] as List<dynamic>?;
      if (coordsList == null) return null;

      final polyline = coordsList
          .map((c) {
            final list = c as List<dynamic>;
            return LatLng(
              (list[1] as num).toDouble(),
              (list[0] as num).toDouble(),
            );
          })
          .toList();

      final totalDistance = (route['distance'] as num?)?.toDouble() ?? 0.0;
      final totalDuration = (route['duration'] as num?)?.toDouble() ?? 0.0;

      final legs = route['legs'] as List<dynamic>? ?? [];
      final steps = <RouteStep>[];
      for (final leg in legs) {
        final legMap = leg as Map<String, dynamic>;
        final legSteps = legMap['steps'] as List<dynamic>? ?? [];
        for (final s in legSteps) {
          final stepMap = s as Map<String, dynamic>;
          final maneuver = stepMap['maneuver'] as Map<String, dynamic>?;
          final type = maneuver?['type'] as String?;
          final modifier = maneuver?['modifier'] as String?;
          final name = stepMap['name'] as String? ?? '';
          final dist = (stepMap['distance'] as num?)?.toDouble() ?? 0.0;
          final dur = (stepMap['duration'] as num?)?.toDouble() ?? 0.0;
          final instruction = _instruction(type, modifier, name, maneuver);
          steps.add(RouteStep(
            instruction: instruction,
            distanceMeters: dist,
            durationSeconds: dur,
            maneuverType: type,
            maneuverModifier: modifier,
          ));
        }
      }

      return RouteResult(
        polyline: polyline,
        steps: steps,
        totalDistanceMeters: totalDistance,
        totalDurationSeconds: totalDuration,
      );
    } catch (e, st) {
      debugPrint('RouteService parse: $e\n$st');
      return null;
    }
  }

  static Future<RouteResult?> _fetchRouteOnce(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 12),
        onTimeout: () => http.Response('', 408),
      );
      if (response.statusCode != 200 || response.body.isEmpty) {
        return null;
      }
      return _parseOsrmBody(response.body);
    } catch (e) {
      debugPrint('RouteService fetch: $e');
      return null;
    }
  }

  /// Reject degenerate geometry (e.g. only two points for a multi-km drive) so we try the next URI.
  static bool _routePolylineLooksSane(RouteResult r) {
    if (r.polyline.length < 2) return false;
    if (r.polyline.length >= 3) return true;
    // Two points only: OK for very short hops; long trips need road-following vertices.
    return r.totalDistanceMeters <= 2500;
  }

  static Future<RouteResult?> _fetchRouteBestEffort(
    String profile,
    String coords, {
    bool continueStraightAtWaypoints = false,
  }) async {
    final uris = _requestUris(
      profile,
      coords,
      continueStraightAtWaypoints: continueStraightAtWaypoints,
    ).toList();
    if (uris.isEmpty) return null;

    // Sequential: prefer backend first, then fallbacks. Parallel "first win" could accept
    // a fast bogus response (e.g. sparse geometry) from a proxy.
    for (final uri in uris) {
      final result = await _fetchRouteOnce(uri);
      if (result != null && _routePolylineLooksSane(result)) {
        return result;
      }
    }
    return null;
  }

  static Future<RouteResult?> getRouteWithWaypoints({
    required List<LatLng> waypoints,
    String travelMode = 'driving',
  }) async {
    if (waypoints.length < 2) return null;

    final google = await _tryGoogleDirections(waypoints, travelMode);
    if (google != null) return google;

    final profile = _profile(travelMode);
    final coords = waypoints.map((w) => '${w.longitude},${w.latitude}').join(';');
    final continueStraight = waypoints.length > 2;

    // With parallel fetching, 1 attempt is usually enough, but we can do a quick retry if it failed immediately.
    final result = await _fetchRouteBestEffort(
      profile,
      coords,
      continueStraightAtWaypoints: continueStraight,
    );
    if (result != null) return result;

    // Optional: One single retry after a very short delay if first one failed.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _fetchRouteBestEffort(
      profile,
      coords,
      continueStraightAtWaypoints: continueStraight,
    );
  }

  static Future<RouteResult?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String travelMode = 'driving',
  }) async {
    final google = await _tryGoogleDirections(
      [
        LatLng(originLat, originLng),
        LatLng(destLat, destLng),
      ],
      travelMode,
    );
    if (google != null) return google;

    final profile = _profile(travelMode);
    final coords = '$originLng,$originLat;$destLng,$destLat';

    final result = await _fetchRouteBestEffort(profile, coords);
    if (result != null) return result;

    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _fetchRouteBestEffort(profile, coords);
  }

  static String _instruction(
    String? type,
    String? modifier,
    String roadName,
    Map<String, dynamic>? maneuver,
  ) {
    final exit = maneuver?['exit'];
    switch (type) {
      case 'depart':
        return roadName.isNotEmpty
            ? 'Head from $roadName'
            : 'Head toward destination';
      case 'arrive':
        return 'Arrive at destination';
      case 'turn':
        final dir = _modifierText(modifier);
        return '$dir${roadName.isNotEmpty ? " onto $roadName" : ""}'.trim();
      case 'continue':
      case 'new name':
        return roadName.isNotEmpty ? 'Continue on $roadName' : 'Continue';
      case 'merge':
        return roadName.isNotEmpty ? 'Merge onto $roadName' : 'Merge';
      case 'fork':
        final dir = _modifierText(modifier);
        return '$dir at fork${roadName.isNotEmpty ? " toward $roadName" : ""}'
            .trim();
      case 'end of road':
        final dir = _modifierText(modifier);
        return '$dir at end of road${roadName.isNotEmpty ? " onto $roadName" : ""}'
            .trim();
      case 'roundabout':
      case 'rotary':
        if (exit is num) {
          return 'At roundabout, take exit ${exit.toInt()}'
              '${roadName.isNotEmpty ? " toward $roadName" : ""}';
        }
        return roadName.isNotEmpty
            ? 'Enter roundabout toward $roadName'
            : 'Enter roundabout';
      case 'exit roundabout':
      case 'exit rotary':
        return roadName.isNotEmpty
            ? 'Exit roundabout toward $roadName'
            : 'Exit roundabout';
      case 'on ramp':
        return roadName.isNotEmpty ? 'Take ramp to $roadName' : 'Take ramp';
      case 'off ramp':
      case 'ramp':
        return roadName.isNotEmpty
            ? 'Take exit toward $roadName'
            : 'Take exit';
      case 'notification':
        return roadName.isNotEmpty ? roadName : 'Continue';
      default:
        return roadName.isNotEmpty ? 'Continue on $roadName' : 'Continue';
    }
  }

  static String _modifierText(String? m) {
    switch (m) {
      case 'left':
        return 'Turn left';
      case 'right':
        return 'Turn right';
      case 'slight_left':
        return 'Slight left';
      case 'slight_right':
        return 'Slight right';
      case 'sharp_left':
        return 'Sharp left';
      case 'sharp_right':
        return 'Sharp right';
      case 'straight':
        return 'Continue straight';
      default:
        return 'Continue';
    }
  }

  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String formatDuration(double seconds) {
    final m = (seconds / 60).round();
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final mins = m % 60;
    return mins > 0 ? '$h h $mins min' : '$h h';
  }
}
