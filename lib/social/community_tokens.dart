import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared layout and surface styles for Discover / community screens.
abstract final class CommunityTokens {
  static const Color pageBackground = AppTheme.backgroundColor;

  static const double cardRadius = 20;

  static const EdgeInsets cardMargin =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 22,
          offset: const Offset(0, 5),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: cardShadow,
      );

  /// White form sections (create post, filters).
  static BoxDecoration get surfaceSectionDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      );
}
