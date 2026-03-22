import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interest.dart';
import '../services/api_service.dart';

const String _interestsCacheKey = 'interests_list_cache';

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
    loadInterests();
  }

  /// Load interests from disk so Explore works offline after first load.
  Future<void> _loadFromDiskCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_interestsCacheKey);
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_interestsCacheKey, json.encode(list));
      } catch (_) {}
    } catch (e) {
      debugPrint('Error loading interests: $e');
      _error = hasCached ? null : e.toString();
      if (!hasCached) _interests = [];
    } finally {
      _isLoading = false;
      _loadInProgress = false;
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
  }

  void setSelected(List<String> ids) {
    _selectedIds.clear();
    _selectedIds.addAll(ids);
    notifyListeners();
  }

  bool isSelected(String id) => _selectedIds.contains(id);
}
