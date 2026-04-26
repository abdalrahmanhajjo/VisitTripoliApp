import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/perf_trace.dart';

class ApiException implements Exception {
  final int statusCode;
  final String body;
  final int? retryAfter;
  ApiException(this.statusCode, this.body, [this.retryAfter]);
  @override
  String toString() => 'API $statusCode: $body';
}

/// Resilient HTTP config: retries, timeouts, connection reuse.
/// 60s timeout so first request can succeed when Render free tier is waking from sleep.
const _defaultTimeout = Duration(seconds: 60);
const _maxRetries = 3;
const _maxRetriesListGet = 4;
const _retryDelays = [700, 1800, 4000, 8000]; // Backoff for flaky / slow Wi‑Fi (ms)

/// In-memory cache TTL for list endpoints (reduces repeat traffic on slow links).
const _cacheTtl = Duration(minutes: 45);

class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;
  _CacheEntry(this.data, this.expiresAt);
  bool get isFresh => DateTime.now().isBefore(expiresAt);
}

bool _isRetryable(Object e) {
  final s = e.toString().toLowerCase();
  return s.contains('connection') ||
      s.contains('timeout') ||
      s.contains('failed host lookup') ||
      s.contains('failed to fetch') ||
      s.contains('clientexception') ||
      s.contains('socket') ||
      s.contains('handshake') ||
      s.contains('network') ||
      s.contains('os error');
}

/// Central API service for backend communication.
/// Uses persistent client, retries on network failures, strict timeouts.
class ApiService {
  ApiService._();
  static final ApiService _instance = ApiService._();
  static ApiService get instance => _instance;

  final http.Client _client = http.Client();
  Map<String, String>? _lastHeaders;
  String? _lastAuthToken;
  /// Current app language code (en, ar, fr). When set, API requests send Accept-Language and ?lang= for translation.
  String? _locale;

  /// Exposed so [FeedService] and other helpers can align read requests with the same locale as [ApiService].
  String? get currentLocale => _locale;

  final Map<String, _CacheEntry<List<dynamic>>> _listCache = {};
  void _invalidateListCache() {
    _listCache.clear();
  }

  /// Set app locale so backend can return translated content (places, categories, events, tours, interests).
  void setLocale(String? languageCode) {
    final code = languageCode?.trim().toLowerCase();
    if (code == _locale) return;
    _locale = (code != null && code.isNotEmpty) ? code : null;
    _lastHeaders = null;
    _invalidateListCache();
  }

  String get _baseUrl {
    var url = ApiConfig.effectiveBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      url = url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  Map<String, String> _headers({String? authToken}) {
    if (_lastHeaders != null && _lastAuthToken == authToken) {
      return _lastHeaders!;
    }
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip',
      'Connection': 'keep-alive',
    };
    if (_locale != null && _locale!.isNotEmpty) {
      headers['Accept-Language'] = _locale!;
    }
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    _lastHeaders = headers;
    _lastAuthToken = authToken;
    return headers;
  }

  /// Append ?lang= to URL for backend translation. Uses [overrideLang] for this request or [_locale].
  String _urlWithLang(String path, [String? overrideLang]) {
    final code = overrideLang ?? _locale;
    if (code == null || code.isEmpty) return path;
    final sep = path.contains('?') ? '&' : '?';
    return '$path${sep}lang=$code';
  }

  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() request, {
    int maxRetries = _maxRetries,
    String traceLabel = 'api.request',
  }) async {
    final sw = Stopwatch()..start();
    Object? lastError;
    for (var i = 0; i < maxRetries; i++) {
      try {
        final response = await request().timeout(_defaultTimeout);
        sw.stop();
        PerfTrace.mark(traceLabel, extras: {
          'status': response.statusCode,
          'attempt': i + 1,
          'ms': sw.elapsedMilliseconds,
        });
        return response;
      } on TimeoutException catch (e) {
        lastError = e;
        if (i < maxRetries - 1) {
          await Future<void>.delayed(
            Duration(milliseconds: _retryDelays[i % _retryDelays.length]),
          );
        }
      } catch (e) {
        lastError = e;
        if (!_isRetryable(e) || i >= maxRetries - 1) rethrow;
        await Future<void>.delayed(
          Duration(milliseconds: _retryDelays[i % _retryDelays.length]),
        );
      }
    }
    sw.stop();
    PerfTrace.mark(traceLabel, extras: {
      'failed': true,
      'ms': sw.elapsedMilliseconds,
      'retries': maxRetries,
    });
    throw lastError is Exception
        ? lastError
        : Exception(lastError?.toString() ?? 'Request failed after retries');
  }

  /// GET /api/places - Returns list of places (popular/locations). Sends lang for translation.
  /// Cached in memory for [_cacheTtl] for instant repeat loads.
  Future<List<dynamic>> getPlaces({
    String? authToken,
    String? locale,
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'places:${locale ?? _locale}:$categoryId';
    if (!forceRefresh) {
      final cached = _listCache[cacheKey];
      if (cached != null && cached.isFresh) return cached.data;
    }

    final headers = Map<String, String>.from(_headers(authToken: authToken));
    if (locale != null && locale.isNotEmpty) {
      headers['Accept-Language'] = locale;
    }
    var url = _urlWithLang('$_baseUrl/api/places', locale);
    if (categoryId != null && categoryId.isNotEmpty) {
      url += '${url.contains('?') ? '&' : '?'}category_id=$categoryId';
    }
    try {
      final response = await _requestWithRetry(
        () => _client.get(
          Uri.parse(url),
          headers: headers,
        ),
        maxRetries: _maxRetriesListGet,
        traceLabel: 'api.getPlaces',
      );
      if (response.statusCode != 200) {
        throw ApiException(response.statusCode, response.body);
      }
      final decoded = json.decode(response.body);
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map) {
        list = (decoded['popular'] ?? decoded['locations'] ?? []) as List;
      } else {
        list = [];
      }
      _listCache[cacheKey] = _CacheEntry(list, DateTime.now().add(_cacheTtl));
      return list;
    } catch (e) {
      final stale = _listCache[cacheKey];
      if (stale != null) return stale.data;
      rethrow;
    }
  }

  /// GET /api/places/:id - Returns single place by id
  Future<Map<String, dynamic>?> getPlaceById(
    String id, {
    String? authToken,
  }) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse(_urlWithLang('$_baseUrl/api/places/$id')),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200) return null;
    return json.decode(response.body) as Map<String, dynamic>?;
  }

  /// GET /api/user/saved-places — requires auth; returns same shape as places list items.
  Future<List<dynamic>> getSavedPlaces({
    required String authToken,
    String? locale,
  }) async {
    final headers = Map<String, String>.from(_headers(authToken: authToken));
    if (locale != null && locale.isNotEmpty) {
      headers['Accept-Language'] = locale;
    }
    final response = await _requestWithRetry(
      () => _client.get(
        Uri.parse(_urlWithLang('$_baseUrl/api/user/saved-places', locale)),
        headers: headers,
      ),
      maxRetries: _maxRetriesListGet,
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) return [];
    return (decoded['places'] as List<dynamic>?) ?? [];
  }

  /// PUT /api/user/saved-places/:placeId — idempotent save
  Future<void> saveUserPlace(String authToken, String placeId) async {
    final encoded = Uri.encodeComponent(placeId);
    final response = await _requestWithRetry(
      () => _client.put(
        Uri.parse('$_baseUrl/api/user/saved-places/$encoded'),
        headers: _headers(authToken: authToken),
      ),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  /// DELETE /api/user/saved-places/:placeId
  Future<void> unsaveUserPlace(String authToken, String placeId) async {
    final encoded = Uri.encodeComponent(placeId);
    final response = await _requestWithRetry(
      () => _client.delete(
        Uri.parse('$_baseUrl/api/user/saved-places/$encoded'),
        headers: _headers(authToken: authToken),
      ),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  /// GET /api/categories - Returns categories (translated when lang set). Cached in memory.
  Future<List<dynamic>> getCategories({
    String? authToken,
    String? locale,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'categories:${locale ?? _locale}';
    if (!forceRefresh) {
      final cached = _listCache[cacheKey];
      if (cached != null && cached.isFresh) return cached.data;
    }

    final headers = Map<String, String>.from(_headers(authToken: authToken));
    if (locale != null && locale.isNotEmpty) headers['Accept-Language'] = locale;
    try {
      final response = await _requestWithRetry(
        () => _client.get(
          Uri.parse(_urlWithLang('$_baseUrl/api/categories', locale)),
          headers: headers,
        ),
        maxRetries: _maxRetriesListGet,
      );
      if (response.statusCode != 200) {
        throw ApiException(response.statusCode, response.body);
      }
      final decoded = json.decode(response.body);
      List<dynamic> list;
      if (decoded is Map && decoded['categories'] != null) {
        list = decoded['categories'] as List;
      } else if (decoded is List) {
        list = decoded;
      } else {
        list = [];
      }
      _listCache[cacheKey] = _CacheEntry(list, DateTime.now().add(_cacheTtl));
      return list;
    } catch (e) {
      final stale = _listCache[cacheKey];
      if (stale != null) return stale.data;
      rethrow;
    }
  }

  /// GET /api/tours - Returns featured tours (translated when lang set). Cached in memory.
  Future<List<dynamic>> getTours({
    String? authToken,
    String? locale,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'tours:${locale ?? _locale}';
    if (!forceRefresh) {
      final cached = _listCache[cacheKey];
      if (cached != null && cached.isFresh) return cached.data;
    }

    final headers = Map<String, String>.from(_headers(authToken: authToken));
    if (locale != null && locale.isNotEmpty) headers['Accept-Language'] = locale;
    try {
      final response = await _requestWithRetry(
        () => _client.get(
          Uri.parse(_urlWithLang('$_baseUrl/api/tours', locale)),
          headers: headers,
        ),
        maxRetries: _maxRetriesListGet,
      );
      if (response.statusCode != 200) {
        throw ApiException(response.statusCode, response.body);
      }
      final decoded = json.decode(response.body);
      List<dynamic> list;
      if (decoded is Map && decoded['featured'] != null) {
        list = decoded['featured'] as List;
      } else if (decoded is List) {
        list = decoded;
      } else {
        list = [];
      }
      _listCache[cacheKey] = _CacheEntry(list, DateTime.now().add(_cacheTtl));
      return list;
    } catch (e) {
      final stale = _listCache[cacheKey];
      if (stale != null) return stale.data;
      rethrow;
    }
  }

  /// GET /api/tours/:id - Returns single tour (translated when lang set).
  Future<Map<String, dynamic>?> getTourById(
    String id, {
    String? authToken,
  }) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse(_urlWithLang('$_baseUrl/api/tours/$id')),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200) return null;
    return json.decode(response.body) as Map<String, dynamic>?;
  }

  /// GET /api/events - Returns events (translated when lang set).
  Future<List<dynamic>> getEvents({String? authToken, String? locale}) async {
    final headers = Map<String, String>.from(_headers(authToken: authToken));
    if (locale != null && locale.isNotEmpty) headers['Accept-Language'] = locale;
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse(_urlWithLang('$_baseUrl/api/events', locale)),
          headers: headers,
        ), traceLabel: 'api.getEvents');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final decoded = json.decode(response.body);
    if (decoded is Map && decoded['events'] != null) {
      return decoded['events'] as List;
    }
    if (decoded is List) return decoded;
    return [];
  }

  /// GET /api/events/:id - Returns single event (translated when lang set).
  Future<Map<String, dynamic>?> getEventById(
    String id, {
    String? authToken,
  }) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse(_urlWithLang('$_baseUrl/api/events/$id')),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200) return null;
    return json.decode(response.body) as Map<String, dynamic>?;
  }

  /// GET /api/interests - Returns interests (translated when lang set).
  Future<List<dynamic>> getInterests({String? authToken, String? locale}) async {
    final headers = Map<String, String>.from(_headers(authToken: authToken));
    if (locale != null && locale.isNotEmpty) headers['Accept-Language'] = locale;
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse(_urlWithLang('$_baseUrl/api/interests', locale)),
          headers: headers,
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final decoded = json.decode(response.body);
    if (decoded is Map && decoded['interests'] != null) {
      return decoded['interests'] as List;
    }
    if (decoded is List) return decoded;
    return [];
  }

  /// POST /api/auth/login - Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _requestWithRetry(
      () => _client.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: _headers(),
        body: json.encode({'email': email, 'password': password}),
      ),
      maxRetries: 2,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _parseError(response.body);
      throw ApiException(response.statusCode, msg);
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// POST /api/auth/google - Sign in/up with Google ID token
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await _requestWithRetry(
      () => _client.post(
        Uri.parse('$_baseUrl/api/auth/google'),
        headers: _headers(),
        body: json.encode({'idToken': idToken}),
      ),
      maxRetries: 2,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _parseError(response.body);
      throw ApiException(response.statusCode, msg);
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// POST /api/auth/apple - Sign in/up with Apple ID token
  Future<Map<String, dynamic>> loginWithApple(
    String idToken, {
    String? email,
    String? name,
  }) async {
    final response = await _requestWithRetry(
      () => _client.post(
        Uri.parse('$_baseUrl/api/auth/apple'),
        headers: _headers(),
        body: json.encode({
          'idToken': idToken,
          if (email != null) 'email': email,
          if (name != null) 'name': name,
        }),
      ),
      maxRetries: 2,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _parseError(response.body);
      throw ApiException(response.statusCode, msg);
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// POST /api/auth/verify-email - Verify email with 6-digit code
  Future<Map<String, dynamic>> verifyEmail(String code) async {
    final response = await _requestWithRetry(
      () => _client.post(
        Uri.parse('$_baseUrl/api/auth/verify-email'),
        headers: _headers(),
        body: json.encode({'code': code}),
      ),
      maxRetries: 2,
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// POST /api/auth/request-verification-email - Request verification (public, for unverified users)
  Future<void> requestVerificationEmail(String email) async {
    final response = await _requestWithRetry(
      () => _client.post(
        Uri.parse('$_baseUrl/api/auth/request-verification-email'),
        headers: _headers(),
        body: json.encode({'email': email}),
      ),
      maxRetries: 2,
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  /// POST /api/auth/resend-verification - Resend verification code (requires auth)
  /// Returns resendCooldownSeconds for next allowed resend.
  Future<int> resendVerification(String authToken) async {
    final response = await _requestWithRetry(
      () => _client.post(
        Uri.parse('$_baseUrl/api/auth/resend-verification'),
        headers: _headers(authToken: authToken),
        body: json.encode({}),
      ),
      maxRetries: 2,
    );
    if (response.statusCode != 200) {
      int? retryAfter;
      try {
        final m = json.decode(response.body) as Map<String, dynamic>?;
        final r = m?['retryAfter'];
        retryAfter = r is num ? r.toInt() : null;
      } catch (_) {}
      throw ApiException(
          response.statusCode, _parseError(response.body), retryAfter);
    }
    final body = json.decode(response.body) as Map<String, dynamic>?;
    return (body?['resendCooldownSeconds'] as num?)?.toInt() ?? 30;
  }

  /// GET /api/auth/email-config - Get SMTP config
  Future<Map<String, dynamic>> getEmailConfig() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/auth/email-config'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// PUT /api/auth/email-config - Save SMTP config
  Future<void> saveEmailConfig({
    required String host,
    required String port,
    required String user,
    required String pass,
  }) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/api/auth/email-config'),
      headers: _headers(),
      body:
          json.encode({'host': host, 'port': port, 'user': user, 'pass': pass}),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  /// POST /api/auth/forgot-password - Request password reset.
  /// Production: code by email only. Dev: server may return `devResetCode` when ENABLE_DEV_CODE=true.
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _requestWithRetry(
      () => _client.post(
        Uri.parse('$_baseUrl/api/auth/forgot-password'),
        headers: _headers(),
        body: json.encode({'email': email}),
      ),
      maxRetries: 2,
    );
    if (response.statusCode != 200) {
      final msg = _parseError(response.body);
      throw ApiException(response.statusCode, msg);
    }
    try {
      return json.decode(response.body) as Map<String, dynamic>? ?? {};
    } catch (_) {
      return {};
    }
  }

  /// POST /api/auth/reset-password - Reset password with 6-digit code
  Future<void> resetPassword(String code, String password) async {
    final response = await _requestWithRetry(
      () => _client.post(
        Uri.parse('$_baseUrl/api/auth/reset-password'),
        headers: _headers(),
        body: json.encode({'code': code, 'password': password}),
      ),
      maxRetries: 2,
    );
    if (response.statusCode != 200) {
      final msg = _parseError(response.body);
      throw ApiException(response.statusCode, msg);
    }
  }

  /// POST /api/auth/register - Register
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String username,
  ) async {
    final response = await _requestWithRetry(
      () => _client.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: _headers(),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'username': username,
        }),
      ),
      maxRetries: 2,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _parseError(response.body);
      throw ApiException(response.statusCode, msg);
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// GET /api/coupons - List coupons (pass authToken for used_by_me)
  Future<Map<String, dynamic>> getCoupons({String? authToken}) async {
    final paths = <String>['/api/coupons', '/api/deals/coupons'];
    ApiException? lastError;
    for (final path in paths) {
      final response = await _requestWithRetry(() => _client.get(
            Uri.parse('$_baseUrl${_urlWithLang(path)}'),
            headers: _headers(authToken: authToken),
          ));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List) return {'coupons': decoded};
        return {'coupons': const <dynamic>[]};
      }
      if (response.statusCode == 404) continue;
      lastError = ApiException(response.statusCode, _parseError(response.body));
      break;
    }
    if (lastError != null) throw lastError;
    return {'coupons': const <dynamic>[]};
  }

  /// POST /api/coupons/validate
  Future<Map<String, dynamic>> validateCoupon(String code, {String? authToken}) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/coupons/validate'),
          headers: _headers(authToken: authToken),
          body: json.encode({'code': code.toUpperCase()}),
        ));
    if (response.statusCode != 200 && response.statusCode != 404) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// POST /api/coupons/redeem - Returns redemption_id, coupon, code for QR
  Future<Map<String, dynamic>> redeemCoupon(String code, String authToken) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/coupons/redeem'),
          headers: _headers(authToken: authToken),
          body: json.encode({'code': code.toUpperCase()}),
        ));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// GET /api/offers - List place offers
  Future<Map<String, dynamic>> getOffers() async {
    final paths = <String>['/api/offers', '/api/deals/offers'];
    ApiException? lastError;
    for (final path in paths) {
      final response = await _requestWithRetry(() => _client.get(
            Uri.parse('$_baseUrl${_urlWithLang(path)}'),
            headers: _headers(),
          ));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List) return {'offers': decoded};
        return {'offers': const <dynamic>[]};
      }
      if (response.statusCode == 404) continue;
      lastError = ApiException(response.statusCode, _parseError(response.body));
      break;
    }
    if (lastError != null) throw lastError;
    return {'offers': const <dynamic>[]};
  }

  /// POST /api/offers/propose - Send offer proposal to restaurant
  Future<void> proposeOfferToRestaurant(String authToken, String placeId, String message, String phone, {String? discountType, num? discountValue}) async {
    final body = <String, dynamic>{
      'place_id': placeId,
      'message': message,
      'phone': phone,
    };
    if (discountType != null) body['suggested_discount_type'] = discountType;
    if (discountValue != null) body['suggested_discount_value'] = discountValue;
    final paths = <String>[
      '/api/offers/propose',
      '/api/messages/propose',
      '/api/proposals/propose',
    ];
    ApiException? lastError;
    for (final path in paths) {
      final response = await _requestWithRetry(() => _client.post(
            Uri.parse('$_baseUrl$path'),
            headers: _headers(authToken: authToken),
            body: json.encode(body),
          ));
      if (response.statusCode == 200 || response.statusCode == 201) return;
      if (response.statusCode == 404) continue;
      lastError = ApiException(response.statusCode, _parseError(response.body));
      break;
    }
    throw lastError ?? ApiException(404, 'Offer proposal endpoint not found');
  }

  /// GET /api/offers/place-proposals - Proposals for places owned by business owner
  Future<Map<String, dynamic>> getPlaceProposals(String authToken) async {
    final paths = <String>[
      '/api/offers/place-proposals',
      '/api/messages/place-proposals',
      '/api/proposals/place-proposals',
    ];
    ApiException? lastError;
    for (final path in paths) {
      final response = await _requestWithRetry(() => _client.get(
            Uri.parse('$_baseUrl${_urlWithLang(path)}'),
            headers: _headers(authToken: authToken),
          ));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List) return {'proposals': decoded};
        return {'proposals': const <dynamic>[]};
      }
      if (response.statusCode == 404) continue;
      lastError = ApiException(response.statusCode, _parseError(response.body));
      break;
    }
    if (lastError != null) throw lastError;
    return {'proposals': const <dynamic>[]};
  }

  /// PUT /api/offers/proposals/:id/respond - Restaurant owner responds to proposal
  Future<void> respondToProposal(String authToken, String proposalId, String response) async {
    final paths = <String>[
      '/api/offers/proposals/$proposalId/respond',
      '/api/messages/proposals/$proposalId/respond',
      '/api/proposals/$proposalId/respond',
    ];
    ApiException? lastError;
    for (final path in paths) {
      final res = await _requestWithRetry(() => _client.put(
            Uri.parse('$_baseUrl$path'),
            headers: _headers(authToken: authToken),
            body: json.encode({'response': response}),
          ));
      if (res.statusCode == 200) return;
      if (res.statusCode == 404) continue;
      lastError = ApiException(res.statusCode, _parseError(res.body));
      break;
    }
    throw lastError ?? ApiException(404, 'Proposal response endpoint not found');
  }

  /// GET /api/offers/my-proposals - User's proposals with restaurant responses
  Future<Map<String, dynamic>> getMyProposals(String authToken) async {
    final paths = <String>[
      '/api/offers/my-proposals',
      '/api/messages/my-proposals',
      '/api/proposals/my-proposals',
    ];
    ApiException? lastError;
    for (final path in paths) {
      final response = await _requestWithRetry(() => _client.get(
            Uri.parse('$_baseUrl${_urlWithLang(path)}'),
            headers: _headers(authToken: authToken),
          ));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List) return {'proposals': decoded};
        return {'proposals': const <dynamic>[]};
      }
      if (response.statusCode == 404) continue;
      lastError = ApiException(response.statusCode, _parseError(response.body));
      break;
    }
    if (lastError != null) throw lastError;
    return {'proposals': const <dynamic>[]};
  }

  /// GET /api/offers/place/:id
  Future<Map<String, dynamic>> getOffersForPlace(String placeId) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl${_urlWithLang('/api/offers/place/$placeId')}'),
          headers: _headers(),
        ));
    if (response.statusCode != 200) throw ApiException(response.statusCode, _parseError(response.body));
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// GET /api/bookings - User bookings
  Future<List<dynamic>> getBookings(String authToken) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl${_urlWithLang('/api/bookings')}'),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200) return [];
    final decoded = json.decode(response.body);
    return (decoded is Map && decoded['bookings'] != null) ? decoded['bookings'] as List : [];
  }

  /// POST /api/bookings
  Future<void> createBooking(String authToken, Map<String, dynamic> data) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/bookings'),
          headers: _headers(authToken: authToken),
          body: json.encode(data),
        ));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  /// DELETE /api/bookings/:id
  Future<void> cancelBooking(String authToken, String id) async {
    final response = await _requestWithRetry(() => _client.delete(
          Uri.parse('$_baseUrl/api/bookings/$id'),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  /// GET /api/reviews?placeId=... - Place reviews (public)
  Future<List<dynamic>> getPlaceReviews(String placeId) async {
    if (placeId.isEmpty) return [];
    final qp = <String, String>{'placeId': placeId};
    final loc = _locale;
    if (loc != null && loc.isNotEmpty) qp['lang'] = loc;
    final uri = Uri.parse('$_baseUrl/api/reviews').replace(queryParameters: qp);
    final response = await _requestWithRetry(() => _client.get(uri, headers: _headers()));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    final decoded = json.decode(response.body);
    if (decoded is Map && decoded['reviews'] is List) {
      return decoded['reviews'] as List;
    }
    return [];
  }

  /// POST /api/reviews - Create a review for a place (auth required)
  Future<void> createPlaceReview(String authToken, Map<String, dynamic> data) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/reviews'),
          headers: _headers(authToken: authToken),
          body: json.encode(data),
        ));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  /// PATCH /api/reviews/:id - Update own review (auth required)
  Future<void> updatePlaceReview(String authToken, String reviewId, Map<String, dynamic> data) async {
    final response = await _requestWithRetry(() => _client.patch(
          Uri.parse('$_baseUrl/api/reviews/$reviewId'),
          headers: _headers(authToken: authToken),
          body: json.encode(data),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  /// DELETE /api/reviews/:id - Delete own review (auth required)
  Future<void> deletePlaceReview(String authToken, String reviewId) async {
    final response = await _requestWithRetry(() => _client.delete(
          Uri.parse('$_baseUrl/api/reviews/$reviewId'),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  /// GET /api/badges/me
  Future<Map<String, dynamic>> getMyBadges(String authToken) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl${_urlWithLang('/api/badges/me')}'),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200) return {};
    return json.decode(response.body) as Map<String, dynamic>? ?? {};
  }

  /// POST /api/trip-shares - Create share link for trip
  Future<Map<String, dynamic>> createTripShare(String authToken, String tripId, {bool canEdit = false, int? expiresInHours}) async {
    final body = <String, dynamic>{'tripId': tripId, 'canEdit': canEdit};
    if (expiresInHours != null) body['expiresInHours'] = expiresInHours;
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/trip-shares'),
          headers: _headers(authToken: authToken),
          body: json.encode(body),
        ));
    if (response.statusCode != 201) throw ApiException(response.statusCode, _parseError(response.body));
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// GET /api/audio-guides - List by place or tour
  Future<List<dynamic>> getAudioGuides({String? placeId, String? tourId}) async {
    if (placeId == null && tourId == null) return [];
    final q = placeId != null ? 'placeId=$placeId' : 'tourId=$tourId';
    final path = _urlWithLang('/api/audio-guides?$q');
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl$path'),
          headers: _headers(),
        ));
    if (response.statusCode != 200) return [];
    final decoded = json.decode(response.body);
    return (decoded is Map && decoded['audioGuides'] != null) ? decoded['audioGuides'] as List : [];
  }

  /// POST /api/badges/check-in — [checkinToken] comes from the official door QR only (not public APIs).
  Future<Map<String, dynamic>> checkIn(
    String authToken,
    String placeId, {
    required String checkinToken,
  }) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/badges/check-in'),
          headers: _headers(authToken: authToken),
          body: json.encode({'placeId': placeId, 'checkinToken': checkinToken}),
        ));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  static String _parseError(String body) {
    try {
      final m = json.decode(body) as Map<String, dynamic>?;
      return m?['error']?.toString() ?? body;
    } catch (_) {
      return body;
    }
  }

  /// POST /api/user/push-token — register FCM token (logged-in users)
  Future<void> registerPushToken(
    String authToken,
    String fcmToken, {
    String platform = 'android',
  }) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/user/push-token'),
          headers: _headers(authToken: authToken),
          body: json.encode({'token': fcmToken, 'platform': platform}),
        ));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  /// GET /api/user/profile - Get user profile (requires auth)
  Future<Map<String, dynamic>?> getProfile(String authToken) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/user/profile'),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200) return null;
    return json.decode(response.body) as Map<String, dynamic>?;
  }

  /// PUT /api/user/profile - Update user profile (requires auth)
  Future<Map<String, dynamic>?> updateProfile(
    String authToken,
    Map<String, dynamic> data,
  ) async {
    final response = await _requestWithRetry(() => _client.put(
          Uri.parse('$_baseUrl/api/user/profile'),
          headers: _headers(authToken: authToken),
          body: json.encode(data),
        ));
    if (response.statusCode != 200 && response.statusCode != 201) return null;
    return json.decode(response.body) as Map<String, dynamic>?;
  }

  /// POST /api/user/profile/avatar - Upload profile image to Supabase bucket (requires auth)
  /// Returns avatar URL or null on failure.
  Future<String?> uploadProfileAvatar(String authToken, {String? filePath, List<int>? bytes}) async {
    final uri = Uri.parse('$_baseUrl/api/user/profile/avatar');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $authToken';
    request.headers['Accept'] = 'application/json';
    if (bytes != null && bytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'avatar.jpg'));
    } else if (filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
    } else {
      return null;
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    final body = json.decode(response.body) as Map<String, dynamic>?;
    return body?['avatarUrl'] as String?;
  }

  /// GET /api/user/trips - Get user trips (requires auth)
  /// Throws [ApiException] when status is not 200 so caller can set error and fall back to cache.
  Future<List<dynamic>> getTrips(String authToken) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/user/trips'),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final decoded = json.decode(response.body);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['trips'] != null) {
      final list = decoded['trips'];
      return list is List ? list : [];
    }
    return [];
  }

  /// POST /api/user/trips - Create trip (requires auth)
  Future<Map<String, dynamic>?> createTrip(
    String authToken,
    Map<String, dynamic> trip,
  ) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/user/trips'),
          headers: _headers(authToken: authToken),
          body: json.encode(trip),
        ));
    if (response.statusCode != 200 && response.statusCode != 201) return null;
    return json.decode(response.body) as Map<String, dynamic>?;
  }

  /// PUT /api/user/trips/:id - Update trip (requires auth)
  Future<Map<String, dynamic>?> updateTrip(
    String authToken,
    String id,
    Map<String, dynamic> trip,
  ) async {
    final response = await _requestWithRetry(() => _client.put(
          Uri.parse('$_baseUrl/api/user/trips/$id'),
          headers: _headers(authToken: authToken),
          body: json.encode(trip),
        ));
    if (response.statusCode != 200 && response.statusCode != 201) return null;
    return json.decode(response.body) as Map<String, dynamic>?;
  }

  /// DELETE /api/user/trips/:id - Delete trip (requires auth)
  Future<bool> deleteTrip(String authToken, String id) async {
    final response = await _requestWithRetry(() => _client.delete(
          Uri.parse('$_baseUrl/api/user/trips/$id'),
          headers: _headers(authToken: authToken),
        ));
    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// GET /api/user/trip-share-requests - collaborative trip requests.
  Future<Map<String, dynamic>> getTripShareRequests(String authToken) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/user/trip-share-requests'),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    final decoded = json.decode(response.body);
    return decoded is Map<String, dynamic>
        ? decoded
        : const <String, dynamic>{'incoming': <dynamic>[], 'sent': <dynamic>[]};
  }

  /// GET /api/user/trip-share-users - invite candidates for trip collaboration.
  Future<List<Map<String, dynamic>>> getTripShareUsers(String authToken) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/user/trip-share-users'),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    final decoded = json.decode(response.body);
    final list = (decoded is Map ? decoded['users'] : null);
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  /// POST /api/user/trip-share-requests - host sends invite request.
  Future<void> createTripShareRequest(
    String authToken, {
    required String tripId,
    required String toUserId,
  }) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/user/trip-share-requests'),
          headers: _headers(authToken: authToken),
          body: json.encode({'tripId': tripId, 'toUserId': toUserId}),
        ));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  /// GET /api/user/trip-share-requests/:id/trip - preview invited trip details.
  Future<Map<String, dynamic>> getTripShareRequestTrip(
    String authToken,
    String requestId,
  ) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/user/trip-share-requests/$requestId/trip'),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    final decoded = json.decode(response.body);
    return decoded is Map<String, dynamic>
        ? decoded
        : const <String, dynamic>{};
  }

  /// GET /api/user/trips/:id/members - all users in a shared trip.
  Future<List<Map<String, dynamic>>> getTripMembers(
    String authToken,
    String tripId,
  ) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/user/trips/$tripId/members'),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    final decoded = json.decode(response.body);
    final rows = (decoded is Map ? decoded['members'] : null);
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  /// POST /api/user/trip-share-requests/:id/respond - accept/reject.
  Future<void> respondTripShareRequest(
    String authToken,
    String requestId,
    String action,
  ) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/user/trip-share-requests/$requestId/respond'),
          headers: _headers(authToken: authToken),
          body: json.encode({'action': action}),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  /// POST /api/upload/image - Upload image (same storage as places).
  /// Use adminKey for admin dashboard or authToken for any logged-in user.
  /// Provide either filePath (mobile) or bytes+filename (web or when path not available).
  /// Returns the image URL to store (e.g. /uploads/images/xxx.jpg).
  Future<String?> uploadImage({
    String? adminKey,
    String? authToken,
    String? filePath,
    List<int>? bytes,
    String? filename,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/upload/image');
    final request = http.MultipartRequest('POST', uri);
    final headers = <String, String>{'Accept': 'application/json'};
    if (adminKey != null && adminKey.isNotEmpty) {
      headers['X-Admin-Key'] = adminKey;
    } else if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    request.headers.addAll(headers);
    if (bytes != null && bytes.isNotEmpty) {
      final name = filename ?? 'image.jpg';
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: name,
      ));
    } else if (filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
    } else {
      return null;
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    final body = json.decode(response.body) as Map<String, dynamic>?;
    final url = body?['url'] as String?;
    if (url != null && url.isNotEmpty) {
      return url.startsWith('http') ? url : '$_baseUrl$url';
    }
    return null;
  }

  // ========== ADMIN API METHODS ==========

  /// POST /api/admin/login - Admin dashboard login
  Future<Map<String, dynamic>> adminLogin(String key) async {
    final response = await _requestWithRetry(
      () => _client.post(
        Uri.parse('$_baseUrl/api/admin/login'),
        headers: _headers(),
        body: json.encode({'key': key}),
      ),
      maxRetries: 2,
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// GET /api/admin/stats - Get dashboard stats
  Future<Map<String, dynamic>> getAdminStats({required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/admin/stats'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // --- Places Admin ---
  Future<List<dynamic>> adminGetPlacesQrCodes({required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/admin/places-qr-codes'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final decoded = json.decode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<void> adminGenerateAllPlacesQrCodes({required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/admin/places-generate-all-qrs'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<Map<String, dynamic>> adminRegeneratePlaceQrCode(String id, {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/admin/places/$id/regenerate-checkin-token'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> adminGetPlaces({required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/admin/places'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final decoded = json.decode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>> adminCreatePlace(
      Map<String, dynamic> place, {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/admin/places'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
          body: json.encode(place),
        ));
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<void> adminUpdatePlace(String id, Map<String, dynamic> place,
      {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.put(
          Uri.parse('$_baseUrl/api/admin/places/$id'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
          body: json.encode(place),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  Future<void> adminDeletePlace(String id, {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.delete(
          Uri.parse('$_baseUrl/api/admin/places/$id'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  /// POST /api/admin/places/:id/ensure-checkin-token — creates a token if the place had none.
  Future<Map<String, dynamic>> adminEnsurePlaceCheckinToken(String placeId,
      {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse(
              '$_baseUrl/api/admin/places/${Uri.encodeComponent(placeId)}/ensure-checkin-token'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// POST /api/admin/places/:id/regenerate-checkin-token — invalidates previous door QR prints.
  Future<Map<String, dynamic>> adminRegeneratePlaceCheckinToken(String placeId,
      {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse(
              '$_baseUrl/api/admin/places/${Uri.encodeComponent(placeId)}/regenerate-checkin-token'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // --- Tours Admin ---
  Future<List<dynamic>> adminGetTours({required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/admin/tours'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final decoded = json.decode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>> adminCreateTour(
      Map<String, dynamic> tour, {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/admin/tours'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
          body: json.encode(tour),
        ));
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<void> adminUpdateTour(String id, Map<String, dynamic> tour,
      {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.put(
          Uri.parse('$_baseUrl/api/admin/tours/$id'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
          body: json.encode(tour),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  Future<void> adminDeleteTour(String id, {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.delete(
          Uri.parse('$_baseUrl/api/admin/tours/$id'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  // --- Events Admin ---
  Future<List<dynamic>> adminGetEvents({required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/admin/events'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final decoded = json.decode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>> adminCreateEvent(
      Map<String, dynamic> event, {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/admin/events'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
          body: json.encode(event),
        ));
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<void> adminUpdateEvent(String id, Map<String, dynamic> event,
      {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.put(
          Uri.parse('$_baseUrl/api/admin/events/$id'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
          body: json.encode(event),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  Future<void> adminDeleteEvent(String id, {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.delete(
          Uri.parse('$_baseUrl/api/admin/events/$id'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  // --- Categories Admin ---
  Future<List<dynamic>> adminGetCategories({required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/admin/categories'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final decoded = json.decode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>> adminCreateCategory(
      Map<String, dynamic> category, {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/admin/categories'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
          body: json.encode(category),
        ));
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<void> adminUpdateCategory(String id, Map<String, dynamic> category,
      {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.put(
          Uri.parse('$_baseUrl/api/admin/categories/$id'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
          body: json.encode(category),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  Future<void> adminDeleteCategory(String id, {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.delete(
          Uri.parse('$_baseUrl/api/admin/categories/$id'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  // --- Interests Admin ---
  Future<List<dynamic>> adminGetInterests({required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/admin/interests'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final decoded = json.decode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>> adminCreateInterest(
      Map<String, dynamic> interest, {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/admin/interests'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
          body: json.encode(interest),
        ));
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<void> adminUpdateInterest(String id, Map<String, dynamic> interest,
      {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.put(
          Uri.parse('$_baseUrl/api/admin/interests/$id'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
          body: json.encode(interest),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  Future<void> adminDeleteInterest(String id, {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.delete(
          Uri.parse('$_baseUrl/api/admin/interests/$id'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  // --- Users Admin ---
  Future<List<dynamic>> adminGetUsers({required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/admin/users'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final decoded = json.decode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>> adminCreateUser(
      Map<String, dynamic> user, {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('$_baseUrl/api/admin/users'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
          body: json.encode(user),
        ));
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<void> adminUpdateUser(String id, Map<String, dynamic> user,
      {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.put(
          Uri.parse('$_baseUrl/api/admin/users/$id'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
          body: json.encode(user),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  Future<void> adminDeleteUser(String id, {required String adminKey}) async {
    final response = await _requestWithRetry(() => _client.delete(
          Uri.parse('$_baseUrl/api/admin/users/$id'),
          headers: {..._headers(), 'X-Admin-Key': adminKey},
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  // ========== BUSINESS OWNER API METHODS ==========

  /// GET /api/business/places - Get places owned by business owner
  Future<List<dynamic>> businessGetPlaces({required String authToken}) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/business/places'),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final decoded = json.decode(response.body);
    return decoded is List ? decoded : [];
  }

  /// GET /api/business/places/:id - Get single owned place
  Future<Map<String, dynamic>?> businessGetPlaceById(
      String id, {required String authToken}) async {
    final response = await _requestWithRetry(() => _client.get(
          Uri.parse('$_baseUrl/api/business/places/$id'),
          headers: _headers(authToken: authToken),
        ));
    if (response.statusCode != 200) return null;
    return json.decode(response.body) as Map<String, dynamic>?;
  }

  /// PUT /api/business/places/:id - Update owned place
  Future<void> businessUpdatePlace(String id, Map<String, dynamic> place,
      {required String authToken}) async {
    final response = await _requestWithRetry(() => _client.put(
          Uri.parse('$_baseUrl/api/business/places/$id'),
          headers: _headers(authToken: authToken),
          body: json.encode(place),
        ));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }
}
