import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../community_feed_sort.dart';

/// TikTok-style top tabs: bold active label + short underline; muted inactive labels.
/// Reels is the fourth tab (navigates out; never shows as selected on Discover).
class CommunityFeedHeader extends StatelessWidget {
  final CommunityFeedSort selectedMode;
  final int matchCount;
  final bool isSavedAvailable;
  final ValueChanged<CommunityFeedSort> onSelectedMode;
  final VoidCallback onReels;

  const CommunityFeedHeader({
    super.key,
    required this.selectedMode,
    required this.matchCount,
    required this.isSavedAvailable,
    required this.onSelectedMode,
    required this.onReels,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _TikTokFeedTab(
                  label: 'For You',
                  isSelected: selectedMode == CommunityFeedSort.newest,
                  showNewDot: matchCount > 0,
                  onTap: () => onSelectedMode(CommunityFeedSort.newest),
                ),
              ),
              Expanded(
                child: _TikTokFeedTab(
                  label: 'Trending',
                  isSelected: selectedMode == CommunityFeedSort.popular,
                  onTap: () => onSelectedMode(CommunityFeedSort.popular),
                ),
              ),
              Expanded(
                child: _TikTokFeedTab(
                  label: 'Saved',
                  isSelected: selectedMode == CommunityFeedSort.saved,
                  isDisabled: !isSavedAvailable,
                  disabledTap: () {
                    context.go(
                      '/login?redirect=${Uri.encodeComponent('/community')}',
                    );
                  },
                  onTap: () => onSelectedMode(CommunityFeedSort.saved),
                ),
              ),
              Expanded(
                child: _TikTokFeedTab(
                  label: 'Reels',
                  isSelected: false,
                  onTap: onReels,
                ),
              ),
            ],
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.borderColor.withValues(alpha: 0.65),
          ),
        ],
      ),
    );
  }
}

class _TikTokFeedTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool showNewDot;
  final bool isDisabled;
  final VoidCallback? disabledTap;
  final VoidCallback onTap;

  const _TikTokFeedTab({
    required this.label,
    required this.isSelected,
    this.showNewDot = false,
    this.isDisabled = false,
    this.disabledTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const inactiveColor = AppTheme.textTertiary;
    const activeColor = AppTheme.textPrimary;
    final disabledColor = inactiveColor.withValues(alpha: 0.55);

    final textColor = isDisabled
        ? disabledColor
        : (isSelected ? activeColor : inactiveColor);

    final fontWeight =
        isSelected ? FontWeight.w700 : FontWeight.w500;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isDisabled) {
            HapticFeedback.lightImpact();
            disabledTap?.call();
          } else {
            HapticFeedback.selectionClick();
            onTap();
          }
        },
        splashColor: Colors.black.withValues(alpha: 0.06),
        highlightColor: Colors.black.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.1,
                        letterSpacing: -0.35,
                        fontWeight: fontWeight,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (showNewDot && label == 'For You') ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 3,
                width: isSelected ? 28 : 0,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
