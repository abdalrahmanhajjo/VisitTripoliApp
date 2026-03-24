import 'package:shared_preferences/shared_preferences.dart';

/// First-launch app tour: opt-in dialog once; if accepted, full showcase once.
class AppTutorialPrefs {
  AppTutorialPrefs._();

  /// User completed or skipped the tour prompt — never show again.
  static const String resolvedKey = 'app_tutorial_resolved';

  /// Legacy key from older builds; migrated on read.
  static const String legacySeenKey = 'has_seen_tutorial';

  /// Whether we should show the "Take a tour?" prompt (and possibly the tour).
  static Future<bool> shouldOfferTutorial(SharedPreferences prefs) async {
    if (prefs.getBool(resolvedKey) == true) return false;
    if (prefs.getBool(legacySeenKey) == true) {
      await prefs.setBool(resolvedKey, true);
      await prefs.remove(legacySeenKey);
      return false;
    }
    return true;
  }

  static Future<void> markResolved(SharedPreferences prefs) async {
    await prefs.setBool(resolvedKey, true);
    await prefs.remove(legacySeenKey);
  }
}
