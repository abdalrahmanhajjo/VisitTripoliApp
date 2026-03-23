import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../services/api_service.dart';
import '../utils/locale_data_cache.dart';
import '../utils/network_error.dart';

const String _categoriesCachePrefix = 'categories_list_cache';

class CategoriesProvider extends ChangeNotifier {
  List<models.Category> _categories = [];
  bool _isLoading = false;
  bool _loadInProgress = false;
  String? _error;

  List<models.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CategoriesProvider() {
    _loadFromDiskCache();
    loadCategories();
  }

  /// Load categories from disk so Explore works offline after first load.
  Future<void> _loadFromDiskCache() async {
    try {
      final raw = await readLocaleScopedJson(
        legacyKey: _categoriesCachePrefix,
        scopedPrefix: _categoriesCachePrefix,
      );
      if (raw == null || raw.isEmpty) return;
      final list = json.decode(raw) as List<dynamic>?;
      if (list == null || list.isEmpty) return;
      _categories = list
          .map((e) => models.Category.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadCategories(
      {String? authToken, bool forceRefresh = false, String? locale}) async {
    if (_loadInProgress && !forceRefresh) return;
    _loadInProgress = true;
    final hasCached = _categories.isNotEmpty;
    if (!hasCached || forceRefresh) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final list = await ApiService.instance.getCategories(
        authToken: authToken,
        locale: locale,
        forceRefresh: forceRefresh,
      );
      _categories = list
          .map((e) => models.Category.fromJson(e as Map<String, dynamic>))
          .toList();
      try {
        await writeLocaleScopedJson(
          scopedPrefix: _categoriesCachePrefix,
          json: json.encode(list),
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (hasCached) {
        _error = null;
      } else if (isLikelyNetworkError(e)) {
        _error =
            'Connection is slow or unavailable. Showing saved categories if available.';
      } else {
        _error = e.toString();
      }
      if (!hasCached) _categories = [];
    } finally {
      _isLoading = false;
      _loadInProgress = false;
      notifyListeners();
    }
  }

  models.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
