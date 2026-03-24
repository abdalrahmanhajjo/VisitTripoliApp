import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../theme/app_theme.dart';
import 'snackbar_utils.dart';

/// Central feedback for user actions: haptics, short vibration on Android, optional snackbars.
class AppFeedback {
  AppFeedback._();

  /// Light feedback for taps (buttons, list tiles, chips).
  static void tap() {
    if (kIsWeb) {
      HapticFeedback.lightImpact();
      return;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        Future(() async {
          final has = await Vibration.hasVibrator();
          if (has == true) {
            await Vibration.vibrate(duration: 12);
          } else {
            HapticFeedback.lightImpact();
          }
        });
        break;
      default:
        HapticFeedback.lightImpact();
    }
  }

  /// Selection / toggle (tabs, segments, pickers).
  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void _successHaptic() {
    HapticFeedback.mediumImpact();
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      Future(() async {
        final has = await Vibration.hasVibrator();
        if (has == true) {
          await Vibration.vibrate(duration: 38);
        }
      });
    }
  }

  static void _errorHaptic() {
    HapticFeedback.heavyImpact();
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      Future(() async {
        final has = await Vibration.hasVibrator();
        if (has == true) {
          await Vibration.vibrate(duration: 55);
        }
      });
    }
  }

  /// Success: haptic + short success snackbar.
  static void success(BuildContext context, String message) {
    _successHaptic();
    AppSnackBars.showSuccess(context, message);
  }

  /// Error: stronger haptic + error snackbar.
  static void error(BuildContext context, String message, {SnackBarAction? action}) {
    _errorHaptic();
    AppSnackBars.showError(context, message, action: action);
  }

  /// Info: light tap + neutral snackbar.
  static void info(BuildContext context, String message) {
    tap();
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
