import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../theme/app_theme.dart';

/// Consistent coach-mark styling (overlay + tooltip) across the app.
class ThemedShowcase extends StatelessWidget {
  const ThemedShowcase({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
  });

  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      overlayColor: AppTheme.showcaseOverlay,
      overlayOpacity: AppTheme.showcaseOverlayOpacity,
      tooltipBackgroundColor: AppTheme.surfaceColor,
      textColor: AppTheme.textPrimary,
      titleTextStyle: AppTheme.showcaseTitleStyle(textTheme),
      descTextStyle: AppTheme.showcaseDescStyle(textTheme),
      tooltipBorderRadius: BorderRadius.circular(22),
      tooltipPadding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      blurValue: 3,
      scaleAnimationCurve: Curves.easeOutCubic,
      scaleAnimationDuration: const Duration(milliseconds: 380),
      movingAnimationDuration: const Duration(milliseconds: 1600),
      targetShapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: AppTheme.primaryLight.withValues(alpha: 0.85),
          width: 2,
        ),
      ),
      targetPadding: const EdgeInsets.all(4),
      child: child,
    );
  }
}
