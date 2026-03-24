import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/api_config.dart';

/// Result of a social sign-in attempt.
class SocialAuthResult {
  const SocialAuthResult({
    this.idToken,
    this.email,
    this.name,
    this.error,
  });

  final String? idToken;
  final String? email;
  final String? name;
  final String? error;

  bool get isSuccess => idToken != null && idToken!.isNotEmpty;
}

/// Handles Google and Apple sign-in, returning ID tokens for backend verification.
class SocialAuthService {
  SocialAuthService._();
  static final SocialAuthService _instance = SocialAuthService._();
  static SocialAuthService get instance => _instance;

  static GoogleSignIn? _googleSignIn;
  static GoogleSignIn get _google {
    _googleSignIn ??= GoogleSignIn(
      scopes: ['email', 'profile'],
      // Web: use clientId only (serverClientId causes assertion failure).
      // Mobile: use serverClientId for ID token with backend-audience.
      clientId: kIsWeb && ApiConfig.googleServerClientId.isNotEmpty
          ? ApiConfig.googleServerClientId
          : null,
      serverClientId: kIsWeb
          ? null
          : (ApiConfig.googleServerClientId.isEmpty
              ? null
              : ApiConfig.googleServerClientId),
    );
    return _googleSignIn!;
  }

  /// Sign in with Google. Returns idToken for backend, or error.
  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      final account = await _google.signIn();
      if (account == null) {
        return const SocialAuthResult(error: 'Sign-in cancelled');
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const SocialAuthResult(
          error: 'Could not get ID token. '
              'Ensure GOOGLE_CLIENT_ID is set and matches your backend.',
        );
      }
      return SocialAuthResult(
        idToken: idToken,
        email: account.email,
        name: account.displayName,
      );
    } catch (e, st) {
      debugPrint('Google sign-in error: $e\n$st');
      final msg = _toUserMessage(e);
      return SocialAuthResult(error: msg);
    }
  }

  /// Android needs a [Services ID](https://developer.apple.com/account/resources/identifiers/list/serviceId)
  /// and HTTPS redirect URL registered in Apple Developer (see README_FLUTTER.md).
  WebAuthenticationOptions? _appleWebAuthOptionsForPlatform() {
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    final serviceId = ApiConfig.appleServiceId.trim();
    if (serviceId.isEmpty) return null;
    final rawRedirect = ApiConfig.appleRedirectUri.trim();
    final fallback = '${ApiConfig.effectiveBaseUrl}/api/auth/apple/android-return';
    final redirectStr = rawRedirect.isNotEmpty ? rawRedirect : fallback;
    final redirectUri = Uri.tryParse(redirectStr);
    if (redirectUri == null || redirectUri.scheme != 'https') {
      return null;
    }
    return WebAuthenticationOptions(
      clientId: serviceId,
      redirectUri: redirectUri,
    );
  }

  /// Sign in with Apple. Returns idToken for backend, or error.
  /// On iOS/macOS uses native flow; on Android uses web OAuth (requires [ApiConfig.appleServiceId]).
  Future<SocialAuthResult> signInWithApple() async {
    try {
      final webAuth = _appleWebAuthOptionsForPlatform();
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        if (webAuth == null) {
          return const SocialAuthResult(
            error: 'Apple Sign-In on Android needs APPLE_SERVICE_ID and an HTTPS '
                'redirect URL (see README_FLUTTER.md).',
          );
        }
      }
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: webAuth,
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        return const SocialAuthResult(
          error: 'Could not get Apple credentials. Try again.',
        );
      }
      final name = credential.givenName != null || credential.familyName != null
          ? '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
              .trim()
          : null;
      return SocialAuthResult(
        idToken: idToken,
        email: credential.email,
        name: name?.isNotEmpty == true ? name : null,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const SocialAuthResult(error: 'Sign-in cancelled');
      }
      return SocialAuthResult(error: e.message);
    } catch (e, st) {
      debugPrint('Apple sign-in error: $e\n$st');
      return SocialAuthResult(error: _toUserMessage(e));
    }
  }

  /// Whether Apple Sign-In is available on this platform.
  /// On Android, [ApiConfig.appleServiceId] and a valid HTTPS redirect are also required.
  static Future<bool> get isAppleSignInAvailable async {
    final native = await SignInWithApple.isAvailable();
    if (!native) return false;
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final serviceId = ApiConfig.appleServiceId.trim();
      if (serviceId.isEmpty) return false;
      final raw = ApiConfig.appleRedirectUri.trim();
      final url = raw.isNotEmpty
          ? raw
          : '${ApiConfig.effectiveBaseUrl}/api/auth/apple/android-return';
      if (!url.startsWith('https://')) return false;
    }
    return true;
  }

  static String _toUserMessage(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('network') ||
        s.contains('connection') ||
        s.contains('socket')) {
      return 'Check your connection. Ensure backend is running and use your PC IP for API_BASE_URL on device.';
    }
    if (s.contains('sign_in_failed') ||
        s.contains('developer_error') ||
        s.contains('api_not_enabled')) {
      return 'Google Sign-In not configured. Add SHA-1 and package name in Google Cloud Console.';
    }
    if (s.contains('invalid_grant') || s.contains('token')) {
      return 'Sign-in expired or invalid. Try again.';
    }
    if (s.contains('apple') && (s.contains('aud') || s.contains('audience'))) {
      return 'Apple Sign-In audience mismatch. Set APPLE_CLIENT_IDS on the server to your iOS bundle ID and Android Services ID (comma-separated).';
    }
    // Include actual error for debugging (truncate if long)
    final detail = e
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Error: ', '');
    if (detail.length > 100 && !detail.contains('instance of')) {
      return 'Sign-in failed: ${detail.substring(0, 97)}...';
    }
    if (detail.isNotEmpty && !detail.contains('instance of')) {
      return 'Sign-in failed: $detail';
    }
    return 'Sign-in failed. Check backend logs and Google Cloud setup.';
  }
}
