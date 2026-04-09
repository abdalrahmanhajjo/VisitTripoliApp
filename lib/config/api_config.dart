import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';

/// API and third-party config. Default is the cloud API; override via --dart-define or Settings → API Server URL.
class ApiConfig {
  static const String _cloudBaseUrl = 'https://tripoli-explorer-api.onrender.com';
  static const String _localDevBaseUrl = 'http://localhost:3096';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _cloudBaseUrl,
  );
  static const String googleApiKey =
      String.fromEnvironment('GOOGLE_API_KEY', defaultValue: '');
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '242387458983-tskrr34n29hcrhom0ud5045aqd0s4dm0.apps.googleusercontent.com',
  );

  /// Apple Services ID (e.g. `com.company.app.signin`) — required for Sign in with Apple on **Android**.
  /// Create under Apple Developer → Identifiers → Services IDs; enable Sign in with Apple.
  static const String appleServiceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    defaultValue: '',
  );

  /// Optional. Must exactly match a Return URL in the Services ID (HTTPS).
  /// If empty on Android, `${effectiveBaseUrl}/api/auth/apple/android-return` is used.
  static const String appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: '',
  );

  static String? _override;

  /// Runtime override (e.g. http://192.168.1.5:3000) so the phone can reach your PC. Load with [loadOverride].
  static String? get apiBaseUrlOverride => _override;

  /// Load saved override from SharedPreferences. Call once at app startup (e.g. in main()).
  /// If a previous override was localhost, it is cleared so the app uses the cloud default.
  static Future<void> loadOverride(SharedPreferences prefs) async {
    final raw = prefs.getString('api_base_url_override');
    final s = raw?.trim();
    if (s == null || s.isEmpty) {
      _override = null;
      return;
    }

    // On web: if the override points to the same origin/port as the Flutter web server,
    // it's almost certainly the frontend static server (like `npx serve`), not the API.
    if (kIsWeb) {
      final baseUri = Uri.base;
      final baseHost = baseUri.host;
      final basePort = baseUri.hasPort ? baseUri.port : (baseUri.scheme == 'https' ? 443 : 80);

      final overrideUri = Uri.tryParse(s);
      final overrideHost = overrideUri?.host;
      final overridePort =
          overrideUri?.hasPort == true ? overrideUri!.port : (overrideUri?.scheme == 'https' ? 443 : 80);

      if (overrideHost != null &&
          overrideHost.isNotEmpty &&
          overrideHost == baseHost &&
          overridePort == basePort) {
        await prefs.remove('api_base_url_override');
        _override = null;
        return;
      }

      // Also clear old localhost-only overrides on web.
      if (s.contains('localhost') || s.contains('127.0.0.1')) {
        await prefs.remove('api_base_url_override');
        _override = null;
        return;
      }
    }

    _override = s;
  }

  /// Set and persist override. Pass null or empty to clear. Use from Settings so the app can reach your server on a physical device.
  static Future<void> setOverride(String? url, SharedPreferences prefs) async {
    final s = url?.trim();
    if (s == null || s.isEmpty) {
      await prefs.remove('api_base_url_override');
      _override = null;
    } else {
      await prefs.setString('api_base_url_override', s);
      _override = s;
    }
  }

  /// API base URL. Uses cloud default unless explicitly overridden.
  static String get effectiveBaseUrl {
    if (_override != null && _override!.isNotEmpty) return _override!;
    // Fastest dev path: use local backend (Mongo/ImageKit) by default.
    // Production builds still use cloud URL unless API_BASE_URL is provided.
    if (!kReleaseMode) return _localDevBaseUrl;
    return baseUrl;
  }

  /// App (frontend) base URL for share links and open-in-browser. On web at localhost, fixed to http://localhost:8080.
  static String get appBaseUrl {
    if (kIsWeb) {
      final uri = Uri.base;
      final host = uri.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
        return 'http://localhost:8080';
      }
      return uri.origin;
    }
    return effectiveBaseUrl;
  }

  /// True if baseUrl uses HTTPS. Use for production builds; never send auth tokens over HTTP in production.
  static bool get isSecureBaseUrl => baseUrl.startsWith('https:');
}
