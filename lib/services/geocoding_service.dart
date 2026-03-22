import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../map/tripoli_geo.dart';

/// Resolves place names to coordinates using Google Places API Text Search.
/// More accurate than Geocoding API for businesses and landmarks.
class GeocodingService {
  static const _placesUrl =
      'https://places.googleapis.com/v1/places:searchText';
  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const _cachePrefix =
      'geocode_v2_'; // v2 = Places API (clear old cache)

  /// Resolve a place by name using Google Places API (more accurate for businesses).
  /// [name] can be the Google Maps name (e.g. "Hallab 1881") for better accuracy.
  static Future<({double lat, double lng})?> geocodePlace({
    required String id,
    required String name,
    required String location,
  }) async {
    final cacheKey = '$_cachePrefix$id';
    final prefs = await SharedPreferences.getInstance();

    // Check cache first
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        final parts = cached.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0]);
          final lng = double.tryParse(parts[1]);
          if (lat != null && lng != null) {
            return (lat: lat, lng: lng);
          }
        }
      } catch (_) {}
    }

    // Try Places API first (best for business/landmark names)
    var coords = await _placesSearch('$name, $location, Tripoli Lebanon');
    // Fallback: try with just name
    coords ??= await _placesSearch('$name Tripoli Lebanon');
    // Fallback: Geocoding API
    coords ??= await _geocodeAddress('$name, $location, Tripoli, Lebanon');

    if (coords != null) {
      await prefs.setString(cacheKey, '${coords.lat},${coords.lng}');
    }
    return coords;
  }

  /// Places API Text Search - returns precise business/landmark coordinates.
  static Future<({double lat, double lng})?> _placesSearch(String query) async {
    try {
      final body = jsonEncode({
        'textQuery': query,
        'locationBias': {
          'circle': {
            'center': {
              'latitude': kTripoliCenterLat,
              'longitude': kTripoliCenterLng,
            },
            'radius': 8000.0, // 8km around Tripoli center
          },
        },
        'regionCode': 'lb',
      });

      final response = await http.post(
        Uri.parse(_placesUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': ApiConfig.googleApiKey,
          'X-Goog-FieldMask': 'places.location',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        debugPrint('Places API failed: ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final places = json['places'] as List<dynamic>?;
      if (places == null || places.isEmpty) return null;

      final loc = places.first['location'] as Map<String, dynamic>?;
      if (loc == null) return null;

      final lat = (loc['latitude'] as num?)?.toDouble();
      final lng = (loc['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return (lat: lat, lng: lng);
    } catch (e) {
      debugPrint('Places API error: $e');
      return null;
    }
  }

  /// Geocoding API fallback.
  static Future<({double lat, double lng})?> _geocodeAddress(
      String address) async {
    try {
      final uri = Uri.parse(_geocodeUrl).replace(
        queryParameters: {
          'address': address,
          'key': ApiConfig.googleApiKey,
          'region': 'lb',
        },
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return null;

      final results = json['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final geometry = results.first['geometry'] as Map<String, dynamic>?;
      final loc = geometry?['location'] as Map<String, dynamic>?;
      if (loc == null) return null;

      final lat = (loc['lat'] as num?)?.toDouble();
      final lng = (loc['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return (lat: lat, lng: lng);
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return null;
    }
  }

  /// Geocode multiple places in batch.
  static Future<Map<String, ({double lat, double lng})>> geocodePlaces(
    List<({String id, String name, String location})> places,
  ) async {
    final results = <String, ({double lat, double lng})>{};
    for (final p in places) {
      final coords = await geocodePlace(
        id: p.id,
        name: p.name,
        location: p.location,
      );
      if (coords != null) {
        results[p.id] = coords;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    return results;
  }
}
