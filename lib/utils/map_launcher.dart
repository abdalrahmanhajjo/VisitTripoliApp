import 'package:url_launcher/url_launcher.dart';

/// Opens Google Maps with directions from origin to destination.
/// Works on iOS, Android, and web - opens Maps app or browser.
/// Uses place search names for destinations when provided (Google Maps resolves
/// by name); falls back to lat/lng when no name is given.
class MapLauncher {
  static const String driving = 'driving';
  static const String walking = 'walking';
  static const String transit = 'transit';
  static const String bicycling = 'bicycling';

  static String _encode(String s) => Uri.encodeComponent(s);

  /// Launch Google Maps directions (opens in Maps app for navigation).
  /// Prefers [destName] for destination when provided (Google search by name);
  /// otherwise uses [destLat]/[destLng]. Same for [originName] vs coordinates.
  static Future<bool> launchDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String? originName,
    String? destName,
    String travelMode = driving,
  }) async {
    final origin = originName != null && originName.trim().isNotEmpty
        ? _encode(originName.trim())
        : '$originLat,$originLng';
    final dest = destName != null && destName.trim().isNotEmpty
        ? _encode(destName.trim())
        : '$destLat,$destLng';
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$origin'
      '&destination=$dest'
      '&travelmode=$travelMode',
    );
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Launch Google Maps with multiple stops (tour/route).
  /// Prefers [destName] for destination when provided; same for [originName].
  /// Waypoints use coordinates.
  static Future<bool> launchDirectionsWithWaypoints({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    List<({double lat, double lng})> waypoints = const [],
    String? originName,
    String? destName,
    String travelMode = driving,
  }) async {
    final origin = originName != null && originName.trim().isNotEmpty
        ? _encode(originName.trim())
        : '$originLat,$originLng';
    final dest = destName != null && destName.trim().isNotEmpty
        ? _encode(destName.trim())
        : '$destLat,$destLng';
    final waypointsStr =
        waypoints.take(9).map((w) => '${w.lat},${w.lng}').join('|');
    final waypointsParam =
        waypointsStr.isNotEmpty ? '&waypoints=${_encode(waypointsStr)}' : '';
    final query =
        'api=1&origin=$origin&destination=$dest$waypointsParam&travelmode=$travelMode';
    final url = Uri.parse('https://www.google.com/maps/dir/?$query');
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Launch Google Maps to view a place.
  /// Prefers [placeName] (Google search by name) when provided; otherwise uses
  /// lat/lng coordinates.
  static Future<bool> launchMap(double lat, double lng,
      {String? placeName}) async {
    final query = placeName != null && placeName.trim().isNotEmpty
        ? _encode(placeName.trim())
        : '$lat,$lng';
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
