import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

/// Key-value chip matching the style used on [PlaceDetailsScreen] key info.
class DetailKeyInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool fullWidth;
  final bool isFree;
  final int maxLines;
  final Color? accentColor;

  const DetailKeyInfoChip({
    super.key,
    required this.icon,
    required this.label,
    this.fullWidth = false,
    this.isFree = false,
    this.maxLines = 1,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = ResponsiveUtils.isSmallPhone(context);
    final isVerySmall = ResponsiveUtils.isVerySmallPhone(context);
    final iconSize = isVerySmall ? 18.0 : (isSmall ? 20.0 : 22.0);
    final valueSize = isVerySmall ? 13.0 : (isSmall ? 14.0 : 15.0);
    final paddingH = isSmall ? 12.0 : 14.0;
    final paddingV = isSmall ? 10.0 : 12.0;
    final color =
        accentColor ?? (isFree ? AppTheme.successColor : AppTheme.primaryColor);

    return Container(
      width: fullWidth ? double.infinity : null,
      padding:
          EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: iconSize, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.2,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
