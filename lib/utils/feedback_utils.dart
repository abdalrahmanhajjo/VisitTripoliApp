import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'snackbar_utils.dart';

/// Central feedback for every user action: haptic + optional message.
/// Use so the user always feels the app responded.
class AppFeedback {
  AppFeedback._();

  /// Light haptic for any tap (buttons, list items, chips).
  static void tap() {
    HapticFeedback.lightImpact();
  }

  /// Selection-style haptic (e.g. tab change, picker).
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Success feedback: haptic + short success snackbar.
  static void success(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    AppSnackBars.showSuccess(context, message);
  }

  /// Error feedback: haptic + error snackbar.
  static void error(BuildContext context, String message, {SnackBarAction? action}) {
    HapticFeedback.mediumImpact();
    AppSnackBars.showError(context, message, action: action);
  }

  /// Info feedback: haptic + neutral snackbar (optional; use success/error when possible).
  static void info(BuildContext context, String message) {
    HapticFeedback.lightImpact();
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
