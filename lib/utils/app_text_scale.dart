import 'package:flutter/widgets.dart';

import 'responsive_utils.dart';

/// Wraps [child] with a [MediaQuery] that slightly reduces effective text size
/// on very narrow screens and clamps extreme system text scaling so layouts stay
/// within bounds while remaining readable.
Widget applyAppTextScale(BuildContext context, Widget child) {
  final mq = MediaQuery.of(context);
  final w = ResponsiveUtils.width(context);
  // Slightly gentler downscaling on narrow phones so body copy stays readable;
  // still respect system accessibility scaling within a safe clamp.
  final widthFactor = w < 280
      ? 0.92
      : w < 320
          ? 0.95
          : w < 360
              ? 0.98
              : 1.0;
  final raw = mq.textScaler.scale(14.0) / 14.0;
  final combined = (raw * widthFactor).clamp(0.82, 1.42);
  return MediaQuery(
    data: mq.copyWith(
      textScaler: TextScaler.linear(combined),
    ),
    child: child,
  );
}
