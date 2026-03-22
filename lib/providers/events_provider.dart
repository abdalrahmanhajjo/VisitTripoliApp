import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../services/api_service.dart';

const String _eventsCacheKey = 'events_list_cache';

class EventsProvider extends ChangeNotifier {
  List<Event> _events = [];
  final Set<String> _savedEventIds = {};
  bool _isLoading = false;
  bool _loadInProgress = false;
  String? _error;

  List<Event> get events => _events;
  List<Event> get savedEvents =>
      _events.where((e) => _savedEventIds.contains(e.id)).toList();
  Set<String> get savedEventIds => Set.unmodifiable(_savedEventIds);
  bool get isLoading => _isLoading;
  String? get error => _error;

  EventsProvider() {
    _loadFromDiskCache();
    loadEvents();
    loadSavedEvents();
  }

  /// Load events from disk so Explore works offline after first load.
  Future<void> _loadFromDiskCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_eventsCacheKey);
      if (raw == null || raw.isEmpty) return;
      final list = json.decode(raw) as List<dynamic>?;
      if (list == null || list.isEmpty) return;
      _events =
          list.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadEvents(
      {String? authToken, bool forceRefresh = false, String? locale}) async {
    if (_loadInProgress && !forceRefresh) return;
    _loadInProgress = true;
    final hasCached = _events.isNotEmpty;
    if (!hasCached || forceRefresh) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final list = await ApiService.instance.getEvents(
        authToken: authToken,
        locale: locale,
      );
      _events =
          list.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_eventsCacheKey, json.encode(list));
      } catch (_) {}
    } catch (e, st) {
      debugPrint('Error loading events: $e');
      debugPrint('Stack trace: $st');
      _error = hasCached ? null : e.toString();
      if (!hasCached) _events = [];
    } finally {
      _isLoading = false;
      _loadInProgress = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('savedEventIds');
      if (raw == null || raw.isEmpty) return;
      final decoded = json.decode(raw);
      if (decoded is List) {
        _savedEventIds
          ..clear()
          ..addAll(decoded.whereType<String>());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved events: $e');
    }
  }

  bool isEventSaved(String id) => _savedEventIds.contains(id);

  Future<void> toggleSaveEvent(Event event) async {
    final id = event.id;
    if (_savedEventIds.contains(id)) {
      _savedEventIds.remove(id);
    } else {
      _savedEventIds.add(id);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'savedEventIds', json.encode(_savedEventIds.toList()));
    } catch (e) {
      debugPrint('Error saving events: $e');
    }
  }

  Event? getEventById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
