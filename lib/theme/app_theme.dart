import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Web parity tokens from VisitTipoliWeb client/src/theme.css
  static const Color primaryColor = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0D5C55);
  static const Color primaryLight = Color(0xFFE8F4F2);
  static const Color accentColor = Color(0xFFD97706);
  static const Color accentMuted = Color(0xFFF3C48B);
  static const Color secondaryColor = Color(0xFF0EA5E9);

  static const Color backgroundColor = Color(0xFFFAFAF9);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F4);

  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textTertiary = Color(0xFFA8A29E);
  static const Color borderColor = Color(0xFFE7E5E4);

  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF059669);
  static const Color warningColor = Color(0xFFD97706);

  /// Coach-mark overlay (slightly on‑brand vs flat black).
  static const Color showcaseOverlay = primaryDark;
  static const double showcaseOverlayOpacity = 0.82;

  /// Web parity typography: Inter body + Playfair Display display.
  static TextStyle get _displayFont => GoogleFonts.playfairDisplay(
        textStyle: const TextStyle(
          fontFamilyFallback: ['Noto Naskh Arabic', 'Amiri'],
        ),
      );
  static TextStyle get _baseFont => GoogleFonts.inter(
        textStyle: const TextStyle(
          fontFamilyFallback: ['Cairo', 'Noto Sans Arabic', 'Tahoma'],
        ),
      );

  /// Public families for widgets that build [TextStyle] outside [ThemeData].
  static String? get displayFontFamily => _displayFont.fontFamily;
  static String? get uiFontFamily => _baseFont.fontFamily;

  /// Hero / marketing gradients (onboarding, headers).
  static LinearGradient get brandSkyGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withValues(alpha: 0.22),
          secondaryColor.withValues(alpha: 0.12),
          accentMuted.withValues(alpha: 0.08),
        ],
        stops: const [0.0, 0.45, 1.0],
      );

  /// Primary CTA wash (buttons, chips).
  static LinearGradient get ctaGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor,
          Color.lerp(primaryColor, primaryDark, 0.35)!,
        ],
      );

  /// Layered elevation for premium cards.
  static List<BoxShadow> get premiumCardShadow => [
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.08),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: textPrimary.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFD9F2EF),
        onPrimaryContainer: primaryDark,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFE8F6FD),
        onSecondaryContainer: const Color(0xFF075985),
        tertiary: accentColor,
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFFDF0DD),
        onTertiaryContainer: const Color(0xFF92400E),
        surface: surfaceColor,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceVariant,
        error: errorColor,
        onError: Colors.white,
        outline: borderColor,
        shadow: textPrimary.withValues(alpha: 0.08),
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: _baseFont.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: _baseFont.copyWith(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 24),
      ),
      textTheme: TextTheme(
        displayLarge: _displayFont.copyWith(
          color: textPrimary,
          fontSize: 38,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.6,
          height: 1.15,
        ),
        displayMedium: _displayFont.copyWith(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.45,
          height: 1.18,
        ),
        displaySmall: _displayFont.copyWith(
          color: textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.35,
          height: 1.22,
        ),
        headlineLarge: _displayFont.copyWith(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        headlineMedium: _baseFont.copyWith(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          height: 1.4,
        ),
        headlineSmall: _baseFont.copyWith(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
        titleLarge: _baseFont.copyWith(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          height: 1.45,
        ),
        titleMedium: _baseFont.copyWith(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
          height: 1.45,
        ),
        titleSmall: _baseFont.copyWith(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.08,
          height: 1.4,
        ),
        bodyLarge: _baseFont.copyWith(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          height: 1.65,
        ),
        bodyMedium: _baseFont.copyWith(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          height: 1.6,
        ),
        bodySmall: _baseFont.copyWith(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          height: 1.5,
        ),
        labelLarge: _baseFont.copyWith(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: textPrimary.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryColor.withValues(alpha: 0.15),
        labelStyle: _baseFont.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: _baseFont.copyWith(
          color: textTertiary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: _baseFont.copyWith(
          color: textSecondary,
          fontSize: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: _baseFont.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _baseFont.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: _baseFont.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: _baseFont.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: surfaceColor,
        elevation: 6,
        shadowColor: textPrimary.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryColor.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? primaryColor : textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _baseFont.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            );
          }
          return _baseFont.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: _baseFont.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: borderColor,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  /// Tooltip title style for ShowcaseView coach marks.
  static TextStyle showcaseTitleStyle(TextTheme t) =>
      (t.titleMedium ?? _baseFont).copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 18,
        height: 1.22,
        letterSpacing: -0.2,
      );

  static TextStyle showcaseDescStyle(TextTheme t) =>
      (t.bodyMedium ?? _baseFont).copyWith(
        color: textSecondary,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
      );
}
