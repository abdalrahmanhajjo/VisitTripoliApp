import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

const String _keyProfile = 'profile';
const String _keyAvatarLocalPath = 'profileAvatarLocalPath';

class ProfileProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  String _name = '';
  String _username = '';
  String _email = '';
  String _avatarUrl = '';
  String _avatarLocalPath = '';
  String _city = '';
  String _bio = '';
  String _mood = 'mixed';
  String _pace = 'normal';
  bool _analytics = true;
  bool _showTips = true;
  int _appRating = 0;
  DateTime? _createdAt;
  bool _syncedFromApiThisSession = false;

  ProfileProvider(this._prefs) {
    _loadProfile();
  }

  /// Call when app starts or when user is logged in so profile (including avatar) is loaded from database.
  /// Safe to call repeatedly; only fetches once per app session.
  Future<void> syncFromApiIfNeeded(String? authToken) async {
    if (authToken == null || authToken.isEmpty) return;
    if (_syncedFromApiThisSession) return;
    final ok = await loadFromApi(authToken);
    if (ok) _syncedFromApiThisSession = true;
  }

  String get name => _name;
  String get username => _username;
  String get email => _email;
  String get avatarUrl => _avatarUrl;
  String get avatarLocalPath => _avatarLocalPath;
  String get city => _city;
  String get bio => _bio;
  String get mood => _mood;
  String get pace => _pace;
  bool get analytics => _analytics;
  bool get showTips => _showTips;
  int get appRating => _appRating;
  DateTime get createdAt => _createdAt ?? DateTime.now();
  String get memberSince => '${createdAt.year}';

  void _loadProfile() {
    final raw = _prefs.getString(_keyProfile);
    if (raw != null) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        _name = map['name'] as String? ?? _name;
        _username = map['username'] as String? ?? _username;
        _email = map['email'] as String? ?? _email;
        final savedAvatar = (map['avatarUrl']?.toString() ?? '').trim();
        if (savedAvatar.isNotEmpty) _avatarUrl = savedAvatar;
        _city = map['city'] as String? ?? _city;
        _bio = map['bio'] as String? ?? _bio;
        _mood = map['mood'] as String? ?? _mood;
        _pace = map['pace'] as String? ?? _pace;
        _analytics = map['analytics'] as bool? ?? _analytics;
        _showTips = map['showTips'] as bool? ?? _showTips;
        _appRating = map['appRating'] as int? ?? _appRating;
        final created = map['createdAt'] as String?;
        _createdAt = created != null ? DateTime.tryParse(created) : null;
      } catch (e) {
        debugPrint('Error loading profile: $e');
      }
    }
    _avatarLocalPath = _prefs.getString(_keyAvatarLocalPath) ?? '';
    notifyListeners();
  }

  Future<void> _saveProfile() async {
    final map = {
      'name': _name,
      'username': _username,
      'email': _email,
      'avatarUrl': _avatarUrl,
      'city': _city,
      'bio': _bio,
      'mood': _mood,
      'pace': _pace,
      'analytics': _analytics,
      'showTips': _showTips,
      'appRating': _appRating,
      'createdAt': createdAt.toIso8601String(),
    };
    await _prefs.setString(_keyProfile, json.encode(map));
    notifyListeners();
  }

  /// Saves the profile image to device storage. Call after successful upload.
  Future<void> setAvatarLocalPath(String? path) async {
    _avatarLocalPath = path ?? '';
    if (path != null) {
      await _prefs.setString(_keyAvatarLocalPath, path);
    } else {
      await _prefs.remove(_keyAvatarLocalPath);
    }
    notifyListeners();
  }

  void syncFromAuth(String? authName, String? authEmail) {
    if (_name.isEmpty && authName != null && authName.isNotEmpty) {
      _name = authName;
      _username = '@${authName.toLowerCase().replaceAll(' ', '')}';
    }
    if (_email.isEmpty && authEmail != null && authEmail.isNotEmpty) {
      _email = authEmail;
    }
    _saveProfile();
  }

  /// Load profile from API for logged-in users. Merges with local, saves to prefs.
  Future<bool> loadFromApi(String? authToken) async {
    if (authToken == null || authToken.isEmpty) return false;
    try {
      final data = await ApiService.instance.getProfile(authToken);
      if (data == null) return false;
      _name = data['name']?.toString() ?? _name;
      _username = data['username']?.toString() ?? _username;
      _email = data['email']?.toString() ?? _email;
      final apiAvatar = (data['avatarUrl']?.toString() ?? '').trim();
      if (apiAvatar.isNotEmpty) _avatarUrl = apiAvatar;
      _city = data['city']?.toString() ?? _city;
      _bio = data['bio']?.toString() ?? _bio;
      _mood = data['mood']?.toString() ?? _mood;
      _pace = data['pace']?.toString() ?? _pace;
      _analytics = data['analytics'] as bool? ?? _analytics;
      _showTips = data['showTips'] as bool? ?? _showTips;
      _appRating = (data['appRating'] as num?)?.toInt() ?? _appRating;
      final created = data['createdAt']?.toString();
      _createdAt = created != null ? DateTime.tryParse(created) : _createdAt;
      await _saveProfile();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error loading profile from API: $e');
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? username,
    String? email,
    String? avatarUrl,
    String? city,
    String? bio,
    String? mood,
    String? pace,
    String? authToken,
  }) async {
    if (name != null) _name = name;
    if (username != null) {
      _username = username.startsWith('@') ? username : '@$username';
    }
    if (email != null) _email = email;
    if (avatarUrl != null) _avatarUrl = avatarUrl;
    if (city != null) _city = city;
    if (bio != null) _bio = bio;
    if (mood != null) _mood = mood;
    if (pace != null) _pace = pace;

    if (authToken != null && authToken.isNotEmpty) {
      try {
        final data = await ApiService.instance.updateProfile(authToken, {
          'name': _name,
          'username': _username,
          'email': _email,
          'avatarUrl': _avatarUrl,
          'city': _city,
          'bio': _bio,
          'mood': _mood,
          'pace': _pace,
          'analytics': _analytics,
          'showTips': _showTips,
          'appRating': _appRating,
        });
        if (data == null) return false;
        _name = data['name']?.toString() ?? _name;
        _username = data['username']?.toString() ?? _username;
        _email = data['email']?.toString() ?? _email;
        final apiAvatar = (data['avatarUrl']?.toString() ?? '').trim();
        if (apiAvatar.isNotEmpty) _avatarUrl = apiAvatar;
        _city = data['city']?.toString() ?? _city;
        _bio = data['bio']?.toString() ?? _bio;
        _mood = data['mood']?.toString() ?? _mood;
        _pace = data['pace']?.toString() ?? _pace;
      } catch (e) {
        debugPrint('Error updating profile via API: $e');
        return false;
      }
    }
    await _saveProfile();
    return true;
  }

  Future<void> setAnalytics(bool value, {String? authToken}) async {
    _analytics = value;
    await _prefs.setBool('profileAnalytics', value);
    await _saveProfile();
    if (authToken != null && authToken.isNotEmpty) {
      await updateProfile(authToken: authToken);
    }
  }

  Future<void> setShowTips(bool value, {String? authToken}) async {
    _showTips = value;
    await _prefs.setBool('profileShowTips', value);
    await _saveProfile();
    if (authToken != null && authToken.isNotEmpty) {
      await updateProfile(authToken: authToken);
    }
  }

  Future<void> setAppRating(int value, {String? authToken}) async {
    _appRating = value.clamp(0, 5);
    await _saveProfile();
    if (authToken != null && authToken.isNotEmpty) {
      await updateProfile(authToken: authToken);
    }
  }

  String getInitials() {
    if (_name.isEmpty) return '?';
    final parts = _name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length == 1) {
      final len = parts.first.length;
      return parts.first.substring(0, len > 2 ? 2 : len).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> clearProfile() async {
    _avatarLocalPath = '';
    await _prefs.remove(_keyAvatarLocalPath);
    _name = '';
    _username = '';
    _email = '';
    _avatarUrl = '';
    _city = '';
    _bio = '';
    _mood = 'mixed';
    _pace = 'normal';
    _analytics = true;
    _showTips = true;
    _appRating = 0;
    _createdAt = null;
    await _prefs.remove(_keyProfile);
    notifyListeners();
  }
}
