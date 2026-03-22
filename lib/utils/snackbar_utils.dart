import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Styled SnackBars for auth and general feedback.
class AppSnackBars {
  AppSnackBars._();

  static const _contentStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white);
  static const _margin = EdgeInsets.fromLTRB(16, 12, 16, 24);
  static const _padding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static final _shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  static SnackBar _snack(Widget content, Color bg, Duration duration, [SnackBarAction? action]) =>
      SnackBar(
        content: content,
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: _margin,
        padding: _padding,
        shape: _shape,
        duration: duration,
        action: action,
      );

  static Widget _row(IconData icon, String message) => Row(
    children: [
      Icon(icon, color: Colors.white, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Text(message, style: _contentStyle)),
    ],
  );

  /// Shows an error message in a prominent, floating SnackBar.
  static void showError(BuildContext context, String message, {SnackBarAction? action}) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(_snack(_row(Icons.error_outline_rounded, message), AppTheme.errorColor, const Duration(seconds: 4), action));
  }

  /// Shows a success message in a styled SnackBar.
  static void showSuccess(BuildContext context, String message) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(_snack(_row(Icons.check_circle_outline_rounded, message), AppTheme.successColor, const Duration(seconds: 3)));
  }
}
