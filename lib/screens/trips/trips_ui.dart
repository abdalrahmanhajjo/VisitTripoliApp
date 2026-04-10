import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Shared geometry tokens for trip modals/sheets.
class TripsLayout {
  static const double sheetTopRadius = 24;
  static const double sectionRadius = 16;
  static const double controlRadius = 14;
  static const double cardRadius = 12;
  static const double sheetHorizontalPadding = 20;
  static const double sheetBottomPadding = 16;
}

/// Drag handle for bottom sheets / draggable modals.
Widget modalDragHandle() {
  return Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 6),
    child: Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.borderColor,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
  );
}

/// Consistent card style for trip detail panels.
BoxDecoration tripsPanelDecoration() {
  return BoxDecoration(
    color: AppTheme.surfaceColor,
    borderRadius: BorderRadius.circular(TripsLayout.controlRadius),
    border: Border.all(color: AppTheme.borderColor),
  );
}
