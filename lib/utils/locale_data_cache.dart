import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

/// Normalizes app language codes for disk cache keys (matches [LanguageProvider]).
String normalizeAppLocale(String? code) {
  final c = (code ?? 'en').trim().toLowerCase();
  if (c == 'ar' || c == 'fr') return c;
  return 'en';
}

/// Language from SharedPreferences (`language` key), same as [LanguageProvider].
Future<String> _readSavedLanguageCode() async {
  final prefs = await SharedPreferences.getInstance();
  return normalizeAppLocale(prefs.getString('language'));
}

/// Per-locale disk key. Falls back to [legacyKey] if missing (pre-localized cache).
Future<String?> readLocaleScopedJson({
  required String legacyKey,
  required String scopedPrefix,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final lang = await _readSavedLanguageCode();
  final scoped = '${scopedPrefix}_$lang';
  return prefs.getString(scoped) ?? prefs.getString(legacyKey);
}

/// Writes JSON for the current API locale so cache matches translated API responses.
Future<void> writeLocaleScopedJson({
  required String scopedPrefix,
  required String json,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final lang = normalizeAppLocale(ApiService.instance.currentLocale);
  await prefs.setString('${scopedPrefix}_$lang', json);
}
