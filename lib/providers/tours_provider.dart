import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tour.dart';
import '../services/api_service.dart';
import '../utils/network_error.dart';

const String _toursCacheKey = 'tours_list_cache';

class ToursProvider extends ChangeNotifier {
  List<Tour> _tours = [];
  final Set<String> _savedTourIds = {};
  bool _isLoading = false;
  bool _loadInProgress = false;
  String? _error;

  List<Tour> get tours => _tours;
  List<Tour> get savedTours =>
      _tours.where((t) => _savedTourIds.contains(t.id)).toList();
  Set<String> get savedTourIds => Set.unmodifiable(_savedTourIds);
  bool get isLoading => _isLoading;
  String? get error => _error;

  ToursProvider() {
    _loadFromDiskCache();
    loadTours();
    SchedulerBinding.instance.addPostFrameCallback((_) => loadSavedTours());
  }

  /// Load tours from disk so Explore works offline after first load.
  Future<void> _loadFromDiskCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_toursCacheKey);
      if (raw == null || raw.isEmpty) return;
      final list = json.decode(raw) as List<dynamic>?;
      if (list == null || list.isEmpty) return;
      _tours =
          list.map((e) => Tour.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadTours(
      {String? authToken, bool forceRefresh = false, String? locale}) async {
    if (_loadInProgress && !forceRefresh) return;
    _loadInProgress = true;
    final hasCached = _tours.isNotEmpty;
    if (!hasCached || forceRefresh) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final list = await ApiService.instance.getTours(
        authToken: authToken,
        locale: locale,
        forceRefresh: forceRefresh,
      );
      _tours =
          list.map((e) => Tour.fromJson(e as Map<String, dynamic>)).toList();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_toursCacheKey, json.encode(list));
      } catch (_) {}
    } catch (e, st) {
      debugPrint('Error loading tours: $e');
      debugPrint('Stack trace: $st');
      if (hasCached) {
        _error = null;
      } else if (isLikelyNetworkError(e)) {
        _error =
            'Connection is slow or unavailable. Showing saved tours if available.';
      } else {
        _error = e.toString();
      }
      if (!hasCached) _tours = [];
    } finally {
      _isLoading = false;
      _loadInProgress = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedTours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('savedTourIds');
      if (raw == null || raw.isEmpty) return;
      final decoded = json.decode(raw);
      if (decoded is List) {
        _savedTourIds
          ..clear()
          ..addAll(decoded.whereType<String>());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved tours: $e');
    }
  }

  bool isTourSaved(String id) => _savedTourIds.contains(id);

  Future<void> toggleSaveTour(Tour tour) async {
    final id = tour.id;
    if (_savedTourIds.contains(id)) {
      _savedTourIds.remove(id);
    } else {
      _savedTourIds.add(id);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'savedTourIds', json.encode(_savedTourIds.toList()));
    } catch (e) {
      debugPrint('Error saving tours: $e');
    }
  }

  Tour? getTourById(String id) {
    try {
      return _tours.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
