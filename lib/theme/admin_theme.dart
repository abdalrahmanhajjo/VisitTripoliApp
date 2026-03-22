import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional admin dashboard theme – distinct from app theme.
class AdminTheme {
  AdminTheme._();

  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0D5C56);
  static const Color surface = Color(0xFFFAFBFC);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color sidebarBg = Color(0xFF1A1D21);
  static const Color sidebarItem = Color(0xFF8B9198);
  static const Color sidebarItemActive = Color(0xFFFFFFFF);
  static const Color sidebarItemActiveBg = Color(0xFF0F766E);
  static const Color textPrimary = Color(0xFF1A1D21);
  static const Color textSecondary = Color(0xFF5C6370);
  static const Color border = Color(0xFFE8EAED);
  static const Color error = Color(0xFFDC3545);
  static const Color success = Color(0xFF28A745);

  static const double sidebarWidth = 260;
  static const double sidebarWidthCollapsed = 72;
  static const double contentMaxWidth = 1200;
  static const double cardRadius = 12;
  static const double inputRadius = 10;

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Shared input decoration for admin forms.
  static InputDecoration inputDecoration(String label, {String? helperText}) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      filled: true,
      fillColor: surfaceCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(inputRadius)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      labelStyle: AdminTheme.label,
    );
  }
}
