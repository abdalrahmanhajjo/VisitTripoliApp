import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English'),
  arabic('ar', 'العربية'),
  french('fr', 'Français');

  final String code;
  final String displayName;
  const AppLanguage(this.code, this.displayName);
}

class LanguageProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  AppLanguage _currentLanguage = AppLanguage.english;

  LanguageProvider(this._prefs) {
    _loadLanguage();
  }

  AppLanguage get currentLanguage => _currentLanguage;
  Locale get locale => Locale(_currentLanguage.code);

  void _loadLanguage() {
    final languageCode = _prefs.getString('language') ?? 'en';
    _currentLanguage = AppLanguage.values.firstWhere(
      (lang) => lang.code == languageCode,
      orElse: () => AppLanguage.english,
    );
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    await _prefs.setString('language', language.code);
    notifyListeners();
  }

  String getText(String english, String arabic, String french) {
    switch (_currentLanguage) {
      case AppLanguage.arabic:
        return arabic;
      case AppLanguage.french:
        return french;
      case AppLanguage.english:
        return english;
    }
  }
}
