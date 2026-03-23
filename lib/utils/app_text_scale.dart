import 'package:flutter/widgets.dart';

import 'responsive_utils.dart';

/// Wraps [child] with a [MediaQuery] that slightly reduces effective text size
/// on very narrow screens and clamps extreme system text scaling so layouts stay
/// within bounds while remaining readable.
Widget applyAppTextScale(BuildContext context, Widget child) {
  final mq = MediaQuery.of(context);
  final w = ResponsiveUtils.width(context);
  final widthFactor = w < 280
      ? 0.86
      : w < 320
          ? 0.90
          : w < 360
              ? 0.94
              : w < 400
                  ? 0.97
                  : 1.0;
  final raw = mq.textScaler.scale(14.0) / 14.0;
  final combined = (raw * widthFactor).clamp(0.78, 1.38);
  return MediaQuery(
    data: mq.copyWith(
      textScaler: TextScaler.linear(combined),
    ),
    child: child,
  );
}
