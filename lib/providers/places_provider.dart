import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';
import '../map/place_coordinates.dart';
import '../services/api_service.dart';
import '../services/geocoding_service.dart';
import '../utils/locale_data_cache.dart';
import '../utils/network_error.dart';

/// Disk cache prefix: `places_list_cache_en` / `_ar` / `_fr` (see [readLocaleScopedJson]).
const String _placesCachePrefix = 'places_list_cache';

class PlacesProvider extends ChangeNotifier {
  List<Place> _places = [];
  List<Place> _savedPlaces = [];
  bool _isLoading = false;
  bool _loadInProgress = false;
  String? _error;

  List<Place> get places => _places;
  List<Place> get savedPlaces => _savedPlaces;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PlacesProvider() {
    _loadFromDiskCache(); // non-blocking: fills _places from disk so UI can paint in msec
    loadPlaces();
    // Defer saved-places load to after first frame so initial paint is not delayed.
    SchedulerBinding.instance.addPostFrameCallback((_) => loadSavedPlaces());
  }

  /// Load places from disk cache immediately so UI can show in msec; then API refresh updates.
  Future<void> _loadFromDiskCache() async {
    try {
      final raw = await readLocaleScopedJson(
        legacyKey: _placesCachePrefix,
        scopedPrefix: _placesCachePrefix,
      );
      if (raw == null || raw.isEmpty) return;
      final list = json.decode(raw) as List<dynamic>?;
      if (list == null || list.isEmpty) return;
      _places = list
          .map((item) => _placeFromJson(item as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadPlaces(
      {String? authToken, bool forceRefresh = false, String? locale}) async {
    if (_loadInProgress && !forceRefresh) return;
    _loadInProgress = true;
    final hasCached = _places.isNotEmpty;
    if (!hasCached || forceRefresh) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final list = await ApiService.instance.getPlaces(
        authToken: authToken,
        locale: locale,
        forceRefresh: forceRefresh,
      );
      _places = list
          .map((item) => _placeFromJson(item as Map<String, dynamic>))
          .toList();

      try {
        await writeLocaleScopedJson(
          scopedPrefix: _placesCachePrefix,
          json: json.encode(list),
        );
      } catch (_) {}

      if (_places.any((p) => !p.hasMapCoordinates)) {
        _geocodePlacesInBackground();
      }
    } catch (e) {
      debugPrint('Error loading places: $e');
      if (hasCached) {
        _error = null;
      } else if (isLikelyNetworkError(e)) {
        _error =
            'Connection is slow or unavailable. Showing saved places if available.';
      } else {
        _error = e.toString();
      }
      if (!hasCached) _places = [];
    } finally {
      _isLoading = false;
      _loadInProgress = false;
      notifyListeners();
    }
  }

  Future<void> _geocodePlacesInBackground() async {
    final toGeocode = _places
        .where((p) => !p.hasMapCoordinates)
        .map((p) => (
              id: p.id,
              name: p.searchName ?? p.name,
              location: p.location,
            ))
        .toList();
    if (toGeocode.isEmpty) return;

    final results = await GeocodingService.geocodePlaces(toGeocode);
    if (results.isEmpty) return;

    _places = _places.map((p) {
      final coords = results[p.id];
      if (coords == null) return p;
      return Place(
        id: p.id,
        name: p.name,
        description: p.description,
        location: p.location,
        latitude: coords.lat,
        longitude: coords.lng,
        images: p.images,
        category: p.category,
        categoryId: p.categoryId,
        duration: p.duration,
        price: p.price,
        bestTime: p.bestTime,
        rating: p.rating,
        reviewCount: p.reviewCount,
        hours: p.hours,
        tags: p.tags,
        searchName: p.searchName,
      );
    }).toList();
    notifyListeners();
  }

  Place _placeFromJson(Map<String, dynamic> json) {
    final image = json['image'] as String?;
    final images = json['images'] as List<dynamic>?;
    final price = json['price'];
    final coords = json['coordinates'] as Map<String, dynamic>?;
    final lat = coords?['lat'] != null
        ? (coords!['lat'] as num).toDouble()
        : (json['latitude'] as num?)?.toDouble();
    final lng = coords?['lng'] != null
        ? (coords!['lng'] as num).toDouble()
        : (json['longitude'] as num?)?.toDouble();
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      latitude: lat,
      longitude: lng,
      searchName: json['searchName'] as String?,
      images: images != null
          ? List<String>.from(images)
          : (image != null ? [image] : <String>[]),
      category: json['category'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      duration: json['duration'] as String?,
      price: price?.toString(),
      bestTime: json['bestTime'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
      hours: json['hours'] as Map<String, dynamic>?,
      tags:
          json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
    );
  }

  Place? getPlaceById(String id) {
    try {
      return _places.firstWhere((place) => place.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Place> getPlacesByCategory(String category) {
    return _places.where((place) => place.category == category).toList();
  }

  Future<void> loadSavedPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('savedPlaces');
    if (s != null && s.isNotEmpty) {
      try {
        final List<dynamic> jsonData = json.decode(s);
        _savedPlaces = jsonData.map((json) => Place.fromJson(json)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading saved places: $e');
      }
    }
  }

  /// Toggles place in saved list (local only). Throws on storage failure.
  Future<void> toggleSavePlace(Place place) async {
    final prefs = await SharedPreferences.getInstance();
    final isSaved = _savedPlaces.any((p) => p.id == place.id);

    if (isSaved) {
      _savedPlaces.removeWhere((p) => p.id == place.id);
    } else {
      _savedPlaces.add(place);
    }

    final savedJson = json.encode(_savedPlaces.map((p) => p.toJson()).toList());
    await prefs.setString('savedPlaces', savedJson);
    notifyListeners();
  }

  bool isPlaceSaved(String placeId) {
    return _savedPlaces.any((p) => p.id == placeId);
  }
}
