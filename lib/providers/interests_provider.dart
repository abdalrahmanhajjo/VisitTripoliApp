import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interest.dart';
import '../services/api_service.dart';
import '../utils/locale_data_cache.dart';

const String _interestsCachePrefix = 'interests_list_cache';
const String _prefsKeySelectedInterestIds = 'selected_interest_ids';

class InterestsProvider extends ChangeNotifier {
  List<Interest> _interests = [];
  final List<String> _selectedIds = [];
  bool _isLoading = false;
  bool _loadInProgress = false;
  String? _error;

  List<Interest> get interests => _interests;
  List<String> get selectedIds => List.unmodifiable(_selectedIds);
  bool get isLoading => _isLoading;
  String? get error => _error;

  InterestsProvider() {
    _loadFromDiskCache();
    _loadSelectedIdsFromPrefs();
    loadInterests();
  }

  Future<void> _loadSelectedIdsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeySelectedInterestIds);
      if (raw == null || raw.isEmpty) return;
      final list = json.decode(raw) as List<dynamic>?;
      if (list == null) return;
      _selectedIds
        ..clear()
        ..addAll(list.map((e) => e.toString()));
      notifyListeners();
    } catch (_) {}
  }

  void _persistSelectedIds() {
    Future(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _prefsKeySelectedInterestIds,
          json.encode(List<String>.from(_selectedIds)),
        );
      } catch (_) {}
    });
  }

  void _pruneSelectedToKnownInterests() {
    if (_interests.isEmpty) return;
    final valid = _interests.map((e) => e.id).toSet();
    final before = _selectedIds.length;
    _selectedIds.removeWhere((id) => !valid.contains(id));
    if (before != _selectedIds.length) {
      notifyListeners();
      _persistSelectedIds();
    }
  }

  /// Load interests from disk so Explore works offline after first load.
  Future<void> _loadFromDiskCache() async {
    try {
      final raw = await readLocaleScopedJson(
        legacyKey: _interestsCachePrefix,
        scopedPrefix: _interestsCachePrefix,
      );
      if (raw == null || raw.isEmpty) return;
      final list = json.decode(raw) as List<dynamic>?;
      if (list == null || list.isEmpty) return;
      _interests = list
          .map((e) => Interest.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadInterests(
      {String? authToken, bool forceRefresh = false, String? locale}) async {
    if (_loadInProgress && !forceRefresh) return;
    _loadInProgress = true;
    final hasCached = _interests.isNotEmpty;
    if (!hasCached || forceRefresh) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final list = await ApiService.instance.getInterests(
        authToken: authToken,
        locale: locale,
      );
      _interests = list
          .map((e) => Interest.fromJson(e as Map<String, dynamic>))
          .toList();
      try {
        await writeLocaleScopedJson(
          scopedPrefix: _interestsCachePrefix,
          json: json.encode(list),
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('Error loading interests: $e');
      _error = hasCached ? null : e.toString();
      if (!hasCached) _interests = [];
    } finally {
      _isLoading = false;
      _loadInProgress = false;
      _pruneSelectedToKnownInterests();
      notifyListeners();
    }
  }

  void toggleInterest(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
    _persistSelectedIds();
  }

  void setSelected(List<String> ids) {
    _selectedIds.clear();
    _selectedIds.addAll(ids);
    notifyListeners();
    _persistSelectedIds();
  }

  bool isSelected(String id) => _selectedIds.contains(id);
}
