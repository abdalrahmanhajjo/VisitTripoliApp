import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  bool _isAuthenticated = false;
  bool _isGuest = false;
  bool _onboardingCompleted = false;
  bool _emailVerified = true;
  bool _isBusinessOwner = false;
  bool _isAdmin = false;
  String? _userId;
  String? _userEmail;
  String? _userName;
  /// Public handle (lowercase, no `@`), from profile.
  String? _profileUsername;
  String? _authToken;
  String? _lastError;

  AuthProvider(this._prefs) {
    _loadAuthState();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get isGuest => _isGuest;
  bool get isLoggedIn => _isAuthenticated && (_authToken != null || _isGuest);
  bool get emailVerified => _emailVerified;
  bool get isBusinessOwner => _isBusinessOwner;
  bool get isAdmin => _isAdmin;
  bool get needsEmailVerification =>
      _isAuthenticated && !_isGuest && !_emailVerified;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get profileUsername => _profileUsername;
  String? get authToken => _authToken;
  String? get lastError => _lastError;

  Future<void> _saveAuthState({
    required bool isAuthenticated,
    required bool isGuest,
    required bool onboardingCompleted,
    required bool emailVerified,
    required bool isBusinessOwner,
    required bool isAdmin,
    required String? userId,
    required String? userEmail,
    required String? userName,
    String? profileUsername,
    required String? authToken,
  }) async {
    await _prefs.setBool('isAuthenticated', isAuthenticated);
    await _prefs.setBool('isGuest', isGuest);
    await _prefs.setBool('onboardingCompleted', onboardingCompleted);
    await _prefs.setBool('emailVerified', emailVerified);
    await _prefs.setBool('isBusinessOwner', isBusinessOwner);
    await _prefs.setBool('isAdmin', isAdmin);
    await _prefs.setString('userId', userId ?? '');
    await _prefs.setString('userEmail', userEmail ?? '');
    await _prefs.setString('userName', userName ?? '');
    await _prefs.setString('profileUsername', profileUsername ?? '');
    await _prefs.setString('authToken', authToken ?? '');
  }

  void _loadAuthState() {
    _isAuthenticated = _prefs.getBool('isAuthenticated') ?? false;
    _isGuest = _prefs.getBool('isGuest') ?? false;
    _onboardingCompleted = _prefs.getBool('onboardingCompleted') ?? false;
    _emailVerified = _prefs.getBool('emailVerified') ?? true;
    _isBusinessOwner = _prefs.getBool('isBusinessOwner') ?? false;
    _isAdmin = _prefs.getBool('isAdmin') ?? false;
    _userId = _prefs.getString('userId');
    _userEmail = _prefs.getString('userEmail');
    _userName = _prefs.getString('userName');
    final pu = _prefs.getString('profileUsername');
    _profileUsername = (pu != null && pu.isNotEmpty) ? pu : null;
    _authToken = _prefs.getString('authToken');
    if (!_isGuest && (_authToken == null || _authToken!.isEmpty)) {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _lastError = null;
    try {
      final resp = await ApiService.instance.login(email, password);
      if (resp['token'] == null) {
        _lastError = 'Invalid response';
        notifyListeners();
        return false;
      }
      final user = resp['user'] as Map<String, dynamic>?;
      _isAuthenticated = true;
      _userId = user?['id']?.toString();
      _userEmail = user?['email']?.toString() ?? email;
      _userName = user?['name']?.toString() ?? email.split('@')[0];
      _profileUsername = user?['username']?.toString();
      if (_profileUsername != null && _profileUsername!.isEmpty) {
        _profileUsername = null;
      }
      _authToken = resp['token'] as String;
      _isGuest = false;
      _emailVerified = user?['emailVerified'] == true;
      _onboardingCompleted = user?['onboardingCompleted'] == true;
      _isBusinessOwner = user?['isBusinessOwner'] == true;
      _isAdmin = user?['isAdmin'] == true;

      await _saveAuthState(
        isAuthenticated: true,
        isGuest: false,
        onboardingCompleted: _onboardingCompleted,
        emailVerified: _emailVerified,
        isBusinessOwner: _isBusinessOwner,
        isAdmin: _isAdmin,
        userId: _userId,
        userEmail: _userEmail,
        userName: _userName,
        profileUsername: _profileUsername,
        authToken: _authToken,
      );
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lastError = e.body;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Login error: $e');
      _lastError = _toUserFriendlyError(e);
      notifyListeners();
      return false;
    }
  }

  static String _toUserFriendlyError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('failed to fetch') ||
        s.contains('connection') ||
        s.contains('socket') ||
        s.contains('network') ||
        s.contains('clientexception')) {
      return 'Cannot reach server. Check your connection and ensure the backend is running.';
    }
    return e.toString();
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String username,
  ) async {
    _lastError = null;
    try {
      final resp =
          await ApiService.instance.register(name, email, password, username);
      if (resp['token'] == null) {
        _lastError = 'Invalid response';
        notifyListeners();
        return false;
      }
      final user = resp['user'] as Map<String, dynamic>?;
      _isAuthenticated = true;
      _userId = user?['id']?.toString();
      _userEmail = user?['email']?.toString() ?? email;
      _userName = user?['name']?.toString() ??
          (name.trim().isEmpty ? email.split('@')[0] : name);
      _profileUsername = user?['username']?.toString();
      if (_profileUsername != null && _profileUsername!.isEmpty) {
        _profileUsername = null;
      }
      _authToken = resp['token'] as String;
      _isGuest = false;
      _onboardingCompleted = user?['onboardingCompleted'] == true;
      _isBusinessOwner = user?['isBusinessOwner'] == true;
      _emailVerified = user?['emailVerified'] == true;
      _isAdmin = user?['isAdmin'] == true;

      await _saveAuthState(
        isAuthenticated: true,
        isGuest: false,
        onboardingCompleted: _onboardingCompleted,
        emailVerified: _emailVerified,
        isBusinessOwner: _isBusinessOwner,
        isAdmin: _isAdmin,
        userId: _userId,
        userEmail: _userEmail,
        userName: _userName,
        profileUsername: _profileUsername,
        authToken: _authToken,
      );
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lastError = e.body;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Register error: $e');
      _lastError = _toUserFriendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> loginAsGuest() async {
    _isAuthenticated = true;
    _isGuest = true;
    _userId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    _userEmail = null;
    _userName = 'Guest';
    _profileUsername = null;
    _authToken = null;
    _onboardingCompleted = _prefs.getBool('guestOnboardingCompleted') ?? false;

    await _saveAuthState(
      isAuthenticated: true,
      isGuest: true,
      onboardingCompleted: _onboardingCompleted,
      emailVerified: true,
      isBusinessOwner: false,
      isAdmin: false,
      userId: _userId,
      userEmail: null,
      userName: _userName,
      profileUsername: null,
      authToken: null,
    );
    notifyListeners();
  }

  Future<bool> loginWithGoogle(String idToken) async {
    _lastError = null;
    try {
      final resp = await ApiService.instance.loginWithGoogle(idToken);
      if (resp['token'] == null) {
        _lastError = 'Invalid response';
        notifyListeners();
        return false;
      }
      final user = resp['user'] as Map<String, dynamic>?;
      _isAuthenticated = true;
      _userId = user?['id']?.toString();
      _userEmail = user?['email']?.toString();
      _userName =
          user?['name']?.toString() ?? _userEmail?.split('@')[0] ?? 'User';
      _profileUsername = user?['username']?.toString();
      if (_profileUsername != null && _profileUsername!.isEmpty) {
        _profileUsername = null;
      }
      _authToken = resp['token'] as String;
      _isGuest = false;
      _onboardingCompleted = user?['onboardingCompleted'] == true;
      _isBusinessOwner = user?['isBusinessOwner'] == true;
      _emailVerified = true;
      _isAdmin = user?['isAdmin'] == true;

      await _saveAuthState(
        isAuthenticated: true,
        isGuest: false,
        onboardingCompleted: _onboardingCompleted,
        emailVerified: _emailVerified,
        isBusinessOwner: _isBusinessOwner,
        isAdmin: _isAdmin,
        userId: _userId,
        userEmail: _userEmail,
        userName: _userName,
        profileUsername: _profileUsername,
        authToken: _authToken,
      );
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lastError = e.body;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Google login error: $e');
      _lastError = _toUserFriendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithApple(String idToken,
      {String? email, String? name}) async {
    _lastError = null;
    try {
      final resp = await ApiService.instance.loginWithApple(
        idToken,
        email: email,
        name: name,
      );
      if (resp['token'] == null) {
        _lastError = 'Invalid response';
        notifyListeners();
        return false;
      }
      final user = resp['user'] as Map<String, dynamic>?;
      _isAuthenticated = true;
      _userId = user?['id']?.toString();
      _userEmail = user?['email']?.toString() ?? email;
      _userName = user?['name']?.toString() ??
          name ??
          _userEmail?.split('@')[0] ??
          'User';
      _profileUsername = user?['username']?.toString();
      if (_profileUsername != null && _profileUsername!.isEmpty) {
        _profileUsername = null;
      }
      _authToken = resp['token'] as String;
      _isGuest = false;
      _onboardingCompleted = user?['onboardingCompleted'] == true;
      _isBusinessOwner = user?['isBusinessOwner'] == true;
      _emailVerified = true;
      _isAdmin = user?['isAdmin'] == true;

      await _saveAuthState(
        isAuthenticated: true,
        isGuest: false,
        onboardingCompleted: _onboardingCompleted,
        emailVerified: _emailVerified,
        isBusinessOwner: _isBusinessOwner,
        isAdmin: _isAdmin,
        userId: _userId,
        userEmail: _userEmail,
        userName: _userName,
        profileUsername: _profileUsername,
        authToken: _authToken,
      );
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lastError = e.body;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Apple login error: $e');
      _lastError = _toUserFriendlyError(e);
      notifyListeners();
      return false;
    }
  }

  /// Update session after email verification (called from verify-email flow)
  void replaceSessionFromVerify(String token, Map<String, dynamic> user) {
    _authToken = token;
    _emailVerified = true;
    _userId = user['id']?.toString();
    _userEmail = user['email']?.toString();
    _userName = user['name']?.toString() ?? _userEmail?.split('@')[0];
    _profileUsername = user['username']?.toString();
    if (_profileUsername != null && _profileUsername!.isEmpty) {
      _profileUsername = null;
    }
    _onboardingCompleted = user['onboardingCompleted'] == true;
    _isBusinessOwner = user['isBusinessOwner'] == true;
    _isAdmin = user['isAdmin'] == true;
    _prefs.setString('authToken', token);
    _prefs.setBool('emailVerified', true);
    _prefs.setBool('isBusinessOwner', _isBusinessOwner);
    _prefs.setBool('isAdmin', _isAdmin);
    _prefs.setString('userId', _userId ?? '');
    _prefs.setString('userEmail', _userEmail ?? '');
    _prefs.setString('userName', _userName ?? '');
    _prefs.setString('profileUsername', _profileUsername ?? '');
    _prefs.setBool('onboardingCompleted', _onboardingCompleted);
    notifyListeners();
  }

  void setOnboardingCompleted(bool value) {
    _onboardingCompleted = value;
    _prefs.setBool('onboardingCompleted', value);
    if (_isGuest) {
      _prefs.setBool('guestOnboardingCompleted', value);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _isGuest = false;
    _onboardingCompleted = false;
    _userId = null;
    _userEmail = null;
    _userName = null;
    _profileUsername = null;
    _authToken = null;
    _lastError = null;

    await _prefs.clear();
    notifyListeners();
  }
}
