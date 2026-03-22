import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

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
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppTheme.borderColor),
  );
}
