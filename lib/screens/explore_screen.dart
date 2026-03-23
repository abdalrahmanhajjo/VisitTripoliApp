import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import '../constants/app_images.dart';
import '../widgets/app_image.dart';
import '../providers/places_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/tours_provider.dart';
import '../providers/events_provider.dart';
import '../providers/interests_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/activity_log_provider.dart';
import '../providers/trips_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_profile_icon_button.dart';
import '../models/category.dart' as models;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/place.dart';
import '../models/tour.dart';
import '../models/event.dart';
import '../models/trip.dart';
import '../l10n/app_localizations.dart';
import '../utils/feedback_utils.dart';
import '../utils/responsive_utils.dart';
import '../utils/snackbar_utils.dart';

String _formatApiError(String? err) {
  if (err == null || err.isEmpty) return 'Unknown error';
  // Try to extract detail from "API 500: {\"error\":\"...\",\"detail\":\"...\"}"
  if (err.contains('"detail":')) {
    try {
      final start = err.indexOf('"detail":"') + 9;
      final end = err.indexOf('"', start);
      if (start > 8 && end > start) {
        return err.substring(start, end).replaceAll(r'\"', '"');
      }
    } catch (_) {}
  }
  if (err.contains('Connection refused')) {
    return 'Backend not reachable. Run: cd backend && npm run dev';
  }
  if (err.contains('timeout') || err.contains('TimeoutException')) {
    return 'Request timeout. Is backend running?';
  }
  return err.length > 120 ? '${err.substring(0, 117)}...' : err;
}

bool _isRtl(BuildContext context) => Directionality.of(context).name == 'rtl';

/// Parse "HH:mm" to minutes since midnight. Returns null if invalid.
int? _timeToMinutes(String? s) {
  if (s == null || s.isEmpty) return null;
  final parts = s.trim().split(RegExp(r'[:\s]'));
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

String _minutesToTime(int minutes) {
  final h = (minutes ~/ 60).clamp(0, 23);
  final m = (minutes % 60).clamp(0, 59);
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

List<TripSlot> _getSlotsForDay(Trip trip, String date) {
  final days = trip.days.where((d) => d.date == date).toList();
  return days.isEmpty ? [] : days.first.slots;
}

/// Check if [startMin, endMin] overlaps any existing slot. Uses 1h default if slot has no end.
bool _hasTimeConflict(int startMin, int endMin, List<TripSlot> slots) {
  for (final slot in slots) {
    int s = _timeToMinutes(slot.startTime) ?? 0;
    int e = _timeToMinutes(slot.endTime) ?? s + 60;
    if (startMin < e && s < endMin) return true;
  }
  return false;
}

/// First free slot (start minute) that fits [durationMinutes] in the given day. Returns minutes or null.
int? _findNextFreeMinute(List<TripSlot> slots, int durationMinutes) {
  final ranges = <List<int>>[];
  for (final slot in slots) {
    final s = _timeToMinutes(slot.startTime);
    final e = _timeToMinutes(slot.endTime);
    if (s != null) ranges.add([s, e ?? s + 60]);
  }
  ranges.sort((a, b) => a[0].compareTo(b[0]));
  const dayStart = 8 * 60; // 08:00
  const dayEnd = 22 * 60; // 22:00
  int cursor = dayStart;
  for (final r in ranges) {
    if (cursor + durationMinutes <= r[0]) return cursor;
    if (r[1] > cursor) cursor = r[1];
  }
  if (cursor + durationMinutes <= dayEnd) return cursor;
  return null;
}

/// Subtle dot-pattern background for Explore (fallback when image fails).
class _ExploreBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 28.0;
    const dotRadius = 1.0;
    final paint = Paint()
      ..color = AppTheme.textTertiary.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    for (var x = 0.0; x < size.width + spacing; x += spacing) {
      for (var y = 0.0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Explore page background: clock tower sketch image with gradient overlay for readability.
class _ExploreBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppImages.exploreBackground,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame == null) {
              return const ColoredBox(color: AppTheme.backgroundColor);
            }
            return child;
          },
          errorBuilder: (_, __, ___) => CustomPaint(
            painter: _ExploreBackgroundPainter(),
          ),
        ),
        // Gradient overlay so content remains readable
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.backgroundColor.withValues(alpha: 0.75),
                  AppTheme.backgroundColor.withValues(alpha: 0.88),
                  AppTheme.backgroundColor.withValues(alpha: 0.94),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Responsive breakpoints and scaling for all phone sizes (including very small phones).
class _Responsive {
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static bool isVerySmallPhone(BuildContext context) => width(context) < 300;
  static bool isSmallPhone(BuildContext context) => width(context) < 340;
  static bool isCompact(BuildContext context) => width(context) < 360;
  static double cardWidth(BuildContext context, {double base = 290}) {
    final w = width(context);
    if (w < 280) return w * 0.84;
    if (w < 320) return w * 0.86;
    if (w < 360) return w * 0.88;
    if (w < 400) return w * 0.84;
    return base;
  }

  static double horizontalPadding(BuildContext context) {
    return ResponsiveUtils.contentPadding(context);
  }
}

/// Consistent spacing and layout for the Explore page. Scales down on small phones.
class _ExploreLayout {
  static double sectionTitleSize(BuildContext context) {
    if (_Responsive.isSmallPhone(context)) return 16;
    if (_Responsive.isCompact(context)) return 17;
    return 19;
  }

  static double horizontalListHeight(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 280) return 172;
    if (w < 320) return 188;
    if (w < 340) return 208;
    if (w < 360) return 228;
    return 258;
  }

  /// Height for "More to explore" vertical cards.
  static double recommendedCardHeight(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 280) return 162;
    if (w < 320) return 178;
    if (w < 340) return 198;
    if (w < 360) return 212;
    return 238;
  }

  /// Height for tour cards.
  static double tourCardHeight(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 280) return 232;
    if (w < 320) return 252;
    if (w < 340) return 268;
    if (w < 380) return 288;
    return 320;
  }

  static double cardGap(BuildContext context) {
    if (_Responsive.isVerySmallPhone(context)) return 6;
    return _Responsive.isSmallPhone(context) ? 8 : 12;
  }

  static double bottomPadding(BuildContext context) =>
      _Responsive.isSmallPhone(context) ? 24 : 32;
  static double panelPadding(BuildContext context) {
    if (_Responsive.isVerySmallPhone(context)) return 10;
    return _Responsive.isSmallPhone(context) ? 12 : 16;
  }

  static double sectionGap(BuildContext context) {
    if (_Responsive.isVerySmallPhone(context)) return 10;
    return _Responsive.isSmallPhone(context) ? 12 : 18;
  }
}

/// Shared visual styles so all Explore sections feel identical.
class _ExploreStyles {
  static ButtonStyle linkButtonStyle() {
    return TextButton.styleFrom(
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static Widget actionLink(String label, [Color? color]) {
    final c = color ?? AppTheme.primaryColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style:
                TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.arrow_forward_rounded, size: 14, color: c),
      ],
    );
  }

  static BoxDecoration panelDecoration() {
    return BoxDecoration(
      color: AppTheme.backgroundColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppTheme.textPrimary.withValues(alpha: 0.06),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.textPrimary.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: AppTheme.textPrimary.withValues(alpha: 0.03),
          blurRadius: 32,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

/// Lightweight skeleton card for instant paint while data loads (HCI: immediate feedback).
class _ExploreSkeletonCard extends StatelessWidget {
  const _ExploreSkeletonCard({
    required this.width,
    required this.height,
    this.compact = false,
  });

  final double width;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageHeight = compact ? height * 0.5 : height * 0.6;
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: imageHeight,
                color: AppTheme.surfaceVariant.withValues(alpha: 0.6),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: width * 0.6,
                      decoration: BoxDecoration(
                        color: AppTheme.textTertiary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: width * 0.4,
                      decoration: BoxDecoration(
                        color: AppTheme.textTertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category filter: optional title row with filter icon + close arrow; tap to expand and show filter pills.
class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selectedId,
    this.expanded = false,
    required this.onExpandChanged,
    required this.onSelected,
    required this.getIcon,
    this.titleWidget,
  });

  final List<models.Category> categories;
  final String? selectedId;
  final bool expanded;
  final void Function(bool) onExpandChanged;
  final void Function(String? id) onSelected;
  final IconData Function(String id) getIcon;

  /// When set, filter icon and close arrow are placed in the same row behind this widget (e.g. Places by Category title).
  final Widget? titleWidget;

  static const double _buttonSize = 44;
  static const double _buttonRadius = 12;
  static const double _chipHeight = 44;
  static const double _chipGap = 10;

  Widget _buildFilterButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.filters,
      toggled: expanded,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onExpandChanged(!expanded),
          borderRadius: BorderRadius.circular(_buttonRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: _buttonSize,
            height: _buttonSize,
            decoration: BoxDecoration(
              color: expanded
                  ? AppTheme.primaryColor.withValues(alpha: 0.12)
                  : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(_buttonRadius),
              border: Border.all(
                color: expanded
                    ? AppTheme.primaryColor.withValues(alpha: 0.4)
                    : AppTheme.borderColor,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 22,
              color: expanded ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// Reset: clear category to All and collapse the filter panel.
  Widget _buildResetButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.reset,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onSelected(null);
            onExpandChanged(false);
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              l10n.reset,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = _Responsive.horizontalPadding(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header: optional title (e.g. Places by Category) with filter icon and close arrow behind it.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: titleWidget != null
              ? Row(
                  children: [
                    Expanded(child: titleWidget!),
                    const SizedBox(width: 8),
                    _buildFilterButton(context),
                    if (expanded) ...[
                      const SizedBox(width: 4),
                      _buildResetButton(context),
                    ],
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterButton(context),
                    if (expanded) ...[
                      const SizedBox(width: 8),
                      _buildResetButton(context),
                    ],
                  ],
                ),
        ),
        // Expanded: filter pills (All + categories). Tap category = select only, no reload.
        if (expanded) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: _chipHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: pad),
              clipBehavior: Clip.none,
              children: [
                _FilterChipPill(
                  label: l10n.all,
                  icon: Icons.grid_view_rounded,
                  selected: selectedId == null,
                  onTap: () => onSelected(null),
                ),
                const SizedBox(width: _chipGap),
                ...categories.map((category) {
                  final selected = selectedId == category.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: _chipGap),
                    child: _FilterChipPill(
                      label: category.name,
                      icon: getIcon(category.id),
                      selected: selected,
                      onTap: () => onSelected(category.id),
                    ),
                  );
                }),
              ],
            ),
          ),
          // When titleWidget is null, show Reset below pills
          if (titleWidget == null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: pad),
              child: _buildResetButton(context),
            ),
          ],
        ],
      ],
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  static const double _height = 44;
  static const double _paddingH = 16;
  static const double _iconSize = 18;
  static const double _radius = 22;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Filter: $label',
      toggled: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: _height,
            padding: const EdgeInsets.symmetric(horizontal: _paddingH),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primaryColor
                  : AppTheme.surfaceVariant.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: selected
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor.withValues(alpha: 0.35),
                width: selected ? 0 : 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: _iconSize,
                  color: selected
                      ? Colors.white
                      : AppTheme.primaryColor.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : AppTheme.textPrimary.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable section header: icon + title, optional subtitle, optional action.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _Responsive.horizontalPadding(context),
        0,
        _Responsive.horizontalPadding(context),
        subtitle != null ? 6 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, size: 20, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: _ExploreLayout.sectionTitleSize(context) + 1,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.2,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: _ExploreStyles.linkButtonStyle(),
                  child: _ExploreStyles.actionLink(actionLabel!),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    this.showWelcome = false,
    this.openEventsSheet = false,
  });

  final bool showWelcome;
  final bool openEventsSheet;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _filterId = 'all';
  String _placeSortOrder = 'default'; // default, topRated, freeFirst
  bool _freeOnly = false;
  String?
      _categoryFilterId; // null = all categories, else filter Places by category
  bool _categoryFilterExpanded = false; // tap icon to show filter pills
  bool _profileSyncScheduled = false;
  bool _searchBarVisible = false;
  Timer? _searchLogTimer;
  bool _showGoToTop = false;

  /// Staggered below-fold: 0=placeholder, 1=+Recommended, 2=+Tours, 3=+Categories (minimal TBT per frame).
  int _belowFoldPhase = 0;

  late final AnimationController _heroFadeController;
  late final Animation<double> _heroFade;
  late final Animation<double> _sectionFade;

  @override
  void initState() {
    super.initState();
    _heroFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _heroFade = CurvedAnimation(
      parent: _heroFadeController,
      curve: Curves.easeOutCubic,
    );
    // Staggered fade: sections appear after hero (same controller, zero extra cost).
    _sectionFade = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1),
        weight: 2,
      ),
    ]).animate(CurvedAnimation(
      parent: _heroFadeController,
      curve: Curves.easeOutCubic,
    ));
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(() {
      if (!mounted) return;
      if (!_searchFocusNode.hasFocus && _searchBarVisible) {
        setState(() => _searchBarVisible = false);
      } else {
        setState(() {});
      }
    });
    // Defer non-critical work so first paint happens in ms (minimal TBT per frame).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _heroFadeController.forward();
      // Stagger below-fold: one section per frame to keep each frame under ~50ms (TBT).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _belowFoldPhase = 1);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _belowFoldPhase = 2);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _belowFoldPhase = 3);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _belowFoldPhase = 4);
            });
          });
        });
      });
      // Defer welcome + precache so they don't add to section build frames.
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        if (widget.showWelcome) _showWelcomeMessage();
        precacheImage(const AssetImage(AppImages.citadel), context);
        _checkTutorial();
      });
    });

    if (widget.openEventsSheet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Ensure events are loaded before opening the sheet.
        final authProvider = context.read<AuthProvider>();
        final eventsProvider = context.read<EventsProvider>();
        eventsProvider.loadEvents(authToken: authProvider.authToken);
        _showEventsCalendarSheet(context);
      });
    }
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_tutorial') ?? false;
    if (!seen) {
      if (!mounted) return;
      ShowCaseWidget.of(context).startShowCase([
        AppBottomNav.exploreKey,
        AppBottomNav.communityKey,
        AppBottomNav.mapKey,
        AppBottomNav.aiPlannerKey,
      ]);
      await prefs.setBool('has_seen_tutorial', true);
    }
  }

  void _showWelcomeMessage() {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final name = authProvider.userName;
    final l10n = AppLocalizations.of(context)!;
    final message = name != null && name.isNotEmpty && name != 'Guest'
        ? l10n.welcomeName(name.split(' ').first)
        : l10n.youreAllSet;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shared Add-to-Trip picker: search trips, pick one, or go to Trips to create.
  void _showAddToTripPicker(
    BuildContext context, {
    required void Function(Trip trip) onTripSelected,
  }) {
    final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AddToTripPickerSheet(
          trips: tripsProvider.trips,
          onTripSelected: (trip) {
            Navigator.pop(sheetContext);
            onTripSelected(trip);
          },
          onGoToTrips: () {
            Navigator.pop(sheetContext);
            context.push('/trips');
          },
        );
      },
    );
  }

  /// Add-to-trip flow for a single place from Explore. After trip is selected, user sets visit time (no conflict).
  void _showAddPlaceToTripDialog(BuildContext context, Place place) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.isGuest) {
      context.go('/login?redirect=${Uri.encodeComponent('/explore')}');
      return;
    }
    final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
    _showAddToTripPicker(context, onTripSelected: (trip) {
      if (!context.mounted) return;
      _showAddPlaceTimeSheet(context,
          trip: trip, place: place, tripsProvider: tripsProvider);
    });
  }

  /// Bottom sheet: set visit start/end time for the place; validates no conflict with existing slots.
  void _showAddPlaceTimeSheet(
    BuildContext context, {
    required Trip trip,
    required Place place,
    required TripsProvider tripsProvider,
  }) {
    final dateStr = trip.days.isNotEmpty
        ? trip.days.first.date
        : '${trip.startDate.year}-${trip.startDate.month.toString().padLeft(2, '0')}-${trip.startDate.day.toString().padLeft(2, '0')}';
    final dates = trip.days.isNotEmpty
        ? trip.days.map((d) => d.date).toList()
        : [dateStr];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddPlaceTimeSheet(
        trip: trip,
        place: place,
        initialDateStr: dateStr,
        dates: dates,
        tripsProvider: tripsProvider,
        onAdded: () => Navigator.pop(sheetContext),
        onCancel: () => Navigator.pop(sheetContext),
      ),
    );
  }

  /// Add tour (all its places) to a selected trip in one go.
  void _showAddTourToTripDialog(BuildContext context, Tour tour) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.isGuest) {
      context.go('/login?redirect=${Uri.encodeComponent('/explore')}');
      return;
    }
    final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
    final placeIds = tour.placeIds.where((id) => id.isNotEmpty).toList();
    if (placeIds.isEmpty) {
      AppFeedback.info(context, 'This tour has no places.');
      return;
    }
    _showAddToTripPicker(context, onTripSelected: (trip) async {
      final dateStr = trip.days.isNotEmpty
          ? trip.days.first.date
          : '${trip.startDate.year}-${trip.startDate.month.toString().padLeft(2, '0')}-${trip.startDate.day.toString().padLeft(2, '0')}';
      try {
        for (final placeId in placeIds) {
          await tripsProvider.addPlaceToTrip(trip.id, placeId, dateStr);
        }
        if (context.mounted) {
          AppFeedback.success(
            context,
            placeIds.length == 1
                ? AppLocalizations.of(context)!.addedToTrip(tour.name)
                : '${placeIds.length} places from "${tour.name}" added to trip',
          );
        }
      } catch (_) {
        if (context.mounted) {
          AppFeedback.error(
              context, AppLocalizations.of(context)!.couldNotLoadData);
        }
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset > 400;
    if (show != _showGoToTop && mounted) setState(() => _showGoToTop = show);
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    HapticFeedback.lightImpact();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _heroFadeController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchLogTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static IconData _categoryIcon(String id) {
    switch (id) {
      case 'souks':
        return FontAwesomeIcons.store;
      case 'historical':
        return FontAwesomeIcons.landmark;
      case 'mosques':
        return FontAwesomeIcons.mosque;
      case 'food':
        return FontAwesomeIcons.utensils;
      case 'cultural':
        return FontAwesomeIcons.masksTheater;
      case 'architecture':
        return FontAwesomeIcons.archway;
      default:
        return FontAwesomeIcons.locationDot;
    }
  }

  List<Place> _getPlacesForCategory(
    models.Category category,
    List<Place> places,
  ) {
    return places.where((p) {
      final catId = (p.categoryId ?? '').toLowerCase().trim();
      final catName = (category.name).toLowerCase().trim();
      final locCat = (p.category).toLowerCase().trim();
      final locType =
          ((p.tags?.isNotEmpty == true) ? p.tags!.first : '').toLowerCase();
      if (catId == category.id.toLowerCase()) return true;
      if (locCat == catName || locCat.contains(catName)) return true;
      if (category.id == 'souks' &&
          (locType.contains('souk') || catId == 'souks')) {
        return true;
      }
      if (category.id == 'historical' &&
          [
            'castle',
            'fortress',
            'landmark',
            'citadel',
          ].any((t) => locType.contains(t))) {
        return true;
      }
      if (category.id == 'mosques' &&
          (locType.contains('mosque') || catId == 'mosques')) {
        return true;
      }
      if (category.id == 'food' &&
          [
            'restaurant',
            'sweets',
            'cafe',
            'food',
          ].any((t) => locType.contains(t))) {
        return true;
      }
      if (category.id == 'cultural' &&
          ['museum', 'gallery', 'cultural'].any((t) => locType.contains(t))) {
        return true;
      }
      if (category.id == 'architecture' &&
          [
            'madrasa',
            'hammam',
            'architecture',
          ].any((t) => locType.contains(t))) {
        return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PlacesProvider>(context);
    final categoriesProvider = Provider.of<CategoriesProvider>(context);
    final toursProvider = Provider.of<ToursProvider>(context);
    final eventsProvider = Provider.of<EventsProvider>(context);
    final interestsProvider = Provider.of<InterestsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    // Sync profile (including avatar) from database once per app session so it persists after reload
    if (!_profileSyncScheduled &&
        authProvider.authToken != null &&
        authProvider.authToken!.isNotEmpty &&
        !authProvider.isGuest) {
      _profileSyncScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        profileProvider.syncFromApiIfNeeded(authProvider.authToken);
      });
    }

    final places = placesProvider.places;
    final categories = categoriesProvider.categories;
    final tours = toursProvider.tours;
    final userInterests = interestsProvider.selectedIds;

    final query = _searchController.text.toLowerCase().trim();
    final filteredPlaces = query.isEmpty
        ? places
        : places
            .where(
              (p) =>
                  p.name.toLowerCase().contains(query) ||
                  p.description.toLowerCase().contains(query),
            )
            .toList();

    final showAllSections = _filterId == 'all';
    final showRecommended = showAllSections || _filterId == 'popular';
    final showTours = showAllSections || _filterId == 'tours';
    final showCategories = showAllSections || _filterId == 'places';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: _ExploreBackground(),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                final token = authProvider.authToken;
                await Future.wait([
                  placesProvider.loadPlaces(
                      authToken: token, forceRefresh: true),
                  categoriesProvider.loadCategories(
                      authToken: token, forceRefresh: true),
                  toursProvider.loadTours(authToken: token, forceRefresh: true),
                  eventsProvider.loadEvents(
                      authToken: token, forceRefresh: true),
                  interestsProvider.loadInterests(
                      authToken: token, forceRefresh: true),
                ]);
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                cacheExtent: 900,
                slivers: [
                  if (placesProvider.error != null && places.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .couldNotLoadData,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatApiError(placesProvider.error),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () async {
                                  final token = authProvider.authToken;
                                  await Future.wait([
                                    placesProvider.loadPlaces(
                                        authToken: token, forceRefresh: true),
                                    categoriesProvider.loadCategories(
                                        authToken: token, forceRefresh: true),
                                    toursProvider.loadTours(
                                        authToken: token, forceRefresh: true),
                                    eventsProvider.loadEvents(
                                        authToken: token, forceRefresh: true),
                                    interestsProvider.loadInterests(
                                        authToken: token, forceRefresh: true),
                                  ]);
                                },
                                icon: const Icon(Icons.refresh),
                                label:
                                    Text(AppLocalizations.of(context)!.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: FadeTransition(
                        opacity: _heroFade,
                        child: _buildHero(context),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: FadeTransition(
                        opacity: _heroFade,
                        child: _buildEventsCalendarBar(context),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child:
                          SizedBox(height: _ExploreLayout.sectionGap(context))),
                  if (_belowFoldPhase == 0)
                    SliverToBoxAdapter(
                      child: RepaintBoundary(
                        child: SizedBox(
                          height: (showRecommended ? 280.0 : 0) +
                              (showTours ? 220.0 : 0) +
                              (showCategories ? 320.0 : 0),
                        ),
                      ),
                    )
                  else ...[
                    if (showRecommended && _belowFoldPhase >= 1)
                      _buildRecommendedSection(
                        context,
                        places,
                        userInterests,
                        interestsProvider,
                        sectionFade: _sectionFade,
                      ),
                    if (showTours && _belowFoldPhase >= 2)
                      _buildToursSection(
                        context,
                        tours,
                        toursProvider,
                        sectionFade: _sectionFade,
                      ),
                    if (showCategories && _belowFoldPhase >= 3)
                      _buildCategoriesSection(
                        context,
                        categories,
                        filteredPlaces,
                        placesProvider,
                        sectionFade: _sectionFade,
                      ),
                  ],
                  SliverToBoxAdapter(
                    child: _belowFoldPhase >= 4
                        ? RepaintBoundary(
                            child: _buildPartnershipFooter(context))
                        : const SizedBox(height: 80),
                  ),
                  SliverToBoxAdapter(
                    child:
                        SizedBox(height: _ExploreLayout.bottomPadding(context)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: _Responsive.horizontalPadding(context) + 8,
            bottom: 24,
            child: IgnorePointer(
              ignoring: !_showGoToTop,
              child: AnimatedOpacity(
                opacity: _showGoToTop ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: AnimatedScale(
                  scale: _showGoToTop ? 1 : 0.85,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Semantics(
                    label: 'Scroll to top',
                    button: true,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(28),
                      color: AppTheme.primaryColor,
                      child: InkWell(
                        onTap: _scrollToTop,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  void _openFiltersSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    final sectionFilters = [
      ('all', l10n.all, Icons.grid_view_rounded, l10n.showEverything),
      ('events', l10n.events, Icons.event_rounded, l10n.whatsHappening),
      ('popular', l10n.popular, Icons.star_rounded, l10n.topRated),
      ('tours', l10n.tours, Icons.route_rounded, l10n.curatedTours),
      ('places', l10n.places, Icons.storefront_rounded, l10n.placesByCategory),
    ];
    final sortOptions = [
      ('default', l10n.sortDefault, l10n.originalOrder),
      ('topRated', l10n.topRated, l10n.highestRatedFirst),
      ('freeFirst', l10n.freeFirst, l10n.freeEntryFirst),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              size: 24,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.filters,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                    height: 1.25,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _filterId == 'all' &&
                                          !_freeOnly &&
                                          _placeSortOrder == 'default'
                                      ? AppLocalizations.of(context)!
                                          .customizeWhatYouSee
                                      : AppLocalizations.of(context)!
                                          .activeFilters(
                                              _getActiveFilterCount()),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              AppFeedback.tap();
                              setState(() {
                                _filterId = 'all';
                                _placeSortOrder = 'default';
                                _freeOnly = false;
                              });
                              setModalState(() {});
                              Navigator.of(ctx).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.clearAll,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Section: Show
                      _buildFilterSectionLabel(
                          AppLocalizations.of(context)!.showSection),
                      const SizedBox(height: 12),
                      ...sectionFilters.map((f) {
                        final isActive = _filterId == f.$1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                AppFeedback.tap();
                                setState(() => _filterId = f.$1);
                                setModalState(() {});
                                Provider.of<ActivityLogProvider>(context,
                                        listen: false)
                                    .filterUsed(f.$2);
                                Navigator.of(ctx).pop();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.primaryColor
                                          .withValues(alpha: 0.12)
                                      : AppTheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isActive
                                        ? AppTheme.primaryColor
                                            .withValues(alpha: 0.5)
                                        : AppTheme.borderColor,
                                    width: isActive ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppTheme.primaryColor
                                            : AppTheme.textSecondary
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: isActive
                                            ? null
                                            : Border.all(
                                                color: AppTheme.textSecondary
                                                    .withValues(alpha: 0.2),
                                                width: 1,
                                              ),
                                      ),
                                      child: Icon(
                                        f.$3,
                                        size: 22,
                                        color: isActive
                                            ? Colors.white
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            f.$2,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isActive
                                                  ? AppTheme.primaryColor
                                                  : AppTheme.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (f.$4.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              f.$4,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: isActive
                                                        ? AppTheme.primaryColor
                                                            .withValues(
                                                                alpha: 0.85)
                                                        : AppTheme
                                                            .textSecondary,
                                                    fontSize: 13,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (isActive)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_filterId == 'places') ...[
                        const SizedBox(height: 24),
                        _buildFilterSectionLabel(
                            AppLocalizations.of(context)!.sortPlaces),
                        const SizedBox(height: 12),
                        ...sortOptions.map((s) {
                          final isActive = _placeSortOrder == s.$1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() => _placeSortOrder = s.$1);
                                  setModalState(() {});
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppTheme.primaryColor
                                            .withValues(alpha: 0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isActive
                                          ? AppTheme.primaryColor
                                              .withValues(alpha: 0.4)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.$2,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: isActive
                                                    ? AppTheme.primaryColor
                                                    : AppTheme.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              s.$3,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppTheme.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isActive)
                                        const Icon(Icons.check_rounded,
                                            color: AppTheme.primaryColor,
                                            size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        _buildFilterSectionLabel(
                            AppLocalizations.of(context)!.options),
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() => _freeOnly = !_freeOnly);
                              setModalState(() {});
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: _freeOnly
                                    ? AppTheme.successColor
                                        .withValues(alpha: 0.08)
                                    : AppTheme.surfaceVariant
                                        .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _freeOnly
                                      ? AppTheme.successColor
                                          .withValues(alpha: 0.4)
                                      : AppTheme.borderColor
                                          .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _freeOnly
                                          ? AppTheme.successColor
                                              .withValues(alpha: 0.12)
                                          : AppTheme.textSecondary
                                              .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _freeOnly
                                            ? AppTheme.successColor
                                                .withValues(alpha: 0.3)
                                            : AppTheme.textSecondary
                                                .withValues(alpha: 0.15),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.celebration_rounded,
                                      size: 20,
                                      color: _freeOnly
                                          ? AppTheme.successColor
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!
                                              .freeEntryOnly,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: _freeOnly
                                                ? AppTheme.successColor
                                                : AppTheme.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .showPlacesNoFee,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: _freeOnly,
                                    onChanged: (v) {
                                      setState(() => _freeOnly = v);
                                      setModalState(() {});
                                    },
                                    activeTrackColor: AppTheme.successColor
                                        .withValues(alpha: 0.5),
                                    activeThumbColor: AppTheme.successColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_filterId != 'all') count++;
    if (_placeSortOrder != 'default') count++;
    if (_freeOnly) count++;
    return count;
  }

  Widget _panel(
    BuildContext context, {
    required Widget child,
    bool transparentBackground = true,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _Responsive.horizontalPadding(context),
        0,
        _Responsive.horizontalPadding(context),
        0,
      ),
      child: Container(
        decoration:
            transparentBackground ? null : _ExploreStyles.panelDecoration(),
        padding: EdgeInsets.all(_ExploreLayout.panelPadding(context)),
        child: child,
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final horizontalPad = _Responsive.horizontalPadding(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Profile (left) | Page name (center) | Search + Filter icons (right)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AppProfileIconButton(
                    iconColor: AppTheme.textPrimary,
                    iconSize: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.tripoli,
                          style: TextStyle(
                            fontSize: isCompact ? 26 : 30,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.6,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.lebanon,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search icon
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _searchBarVisible = true);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _searchFocusNode.requestFocus();
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.search_rounded,
                          size: 24,
                          color: AppTheme.textPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Filter icon (opens filter sheet)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openFiltersSheet(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 24,
                              color: _getActiveFilterCount() > 0
                                  ? AppTheme.primaryColor
                                  : AppTheme.textPrimary.withValues(alpha: 0.7),
                            ),
                          ),
                          if (_getActiveFilterCount() > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppTheme.surfaceColor, width: 1.2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Search bar: only visible when search icon was tapped, no borders
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: l10n.discoverPlacesHint,
                            hintStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textTertiary,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 4),
                            isDense: true,
                            filled: true,
                            fillColor:
                                AppTheme.surfaceVariant.withValues(alpha: 0.6),
                          ),
                          onChanged: (_) {
                            setState(() {});
                            _searchLogTimer?.cancel();
                            _searchLogTimer =
                                Timer(const Duration(milliseconds: 1500), () {
                              if (mounted) {
                                final q = _searchController.text.trim();
                                if (q.isNotEmpty) {
                                  Provider.of<ActivityLogProvider>(context,
                                          listen: false)
                                      .search(q);
                                }
                                _searchLogTimer = null;
                              }
                            });
                          },
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _searchBarVisible = false;
                              _searchController.clear();
                            });
                            _searchFocusNode.unfocus();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: _searchBarVisible
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
              if (_searchBarVisible) const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Top bar: "Calendar of events" with arrow â€“ opens bottom sheet with events list.
  Widget _buildEventsCalendarBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final horizontalPad = _Responsive.horizontalPadding(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEventsCalendarSheet(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 22,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.whatsHappening,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.eventsInTripoli,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEventsCalendarSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final w = MediaQuery.sizeOf(context).width;
    final cardHeight = ResponsiveUtils.eventCalendarTicketHeight(context);
    final horizontalPad = _Responsive.horizontalPadding(context);
    final cardWidth = w - horizontalPad * 2 - _ExploreLayout.cardGap(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.event_rounded,
                            size: 24, color: AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.whatsHappening,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                l10n.eventsInTripoli,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Consumer<EventsProvider>(
                      builder: (context, eventsProvider, _) {
                        if (eventsProvider.isLoading) {
                          return const _EventsLoadingSkeleton();
                        }
                        final allEvents = eventsProvider.events;
                        if (eventsProvider.error != null && allEvents.isEmpty) {
                          final authProvider =
                              Provider.of<AuthProvider>(context, listen: false);
                          return _EventsErrorState(
                            message: eventsProvider.error!,
                            onRetry: () => eventsProvider.loadEvents(
                              authToken: authProvider.authToken,
                              forceRefresh: true,
                            ),
                          );
                        }
                        final events = allEvents;
                        if (events.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.event_busy_rounded,
                                    size: 48,
                                    color: AppTheme.textTertiary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.noEventsNow,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.checkBackEvents,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                ],
                              ),
                            ),
                          );
                        }
                        return _EventsCalendarContent(
                          scrollController: scrollController,
                          events: events,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          isEventSaved: eventsProvider.isEventSaved,
                          onEventTap: (event) {
                            Navigator.of(ctx).pop();
                            context.push('/event/${event.id}');
                          },
                          onToggleSave: (event) {
                            AppFeedback.tap();
                            eventsProvider.toggleSaveEvent(event);
                            if (context.mounted) {
                              final saved =
                                  eventsProvider.isEventSaved(event.id);
                              if (saved) {
                                Provider.of<ActivityLogProvider>(context,
                                        listen: false)
                                    .eventSaved(event.name);
                              } else {
                                Provider.of<ActivityLogProvider>(context,
                                        listen: false)
                                    .eventUnsaved(event.name);
                              }
                              AppFeedback.success(
                                context,
                                saved
                                    ? l10n.savedToFavourites(event.name)
                                    : l10n.removedFromFavourites(event.name),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    Provider.of<EventsProvider>(context, listen: false)
        .loadEvents(authToken: authProvider.authToken);
  }

  void _showToursSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    final toursProvider = Provider.of<ToursProvider>(context, listen: false);
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    final tours = toursProvider.tours;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        const Icon(FontAwesomeIcons.compass,
                            size: 24, color: AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.aTourInTripoli,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                l10n.curatedTours,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: tours.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.route_rounded,
                                    size: 48,
                                    color: AppTheme.textTertiary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.noToursAvailable,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            cacheExtent: 400,
                            itemCount: tours.length,
                            itemBuilder: (context, index) {
                              final tour = tours[index];
                              final isSaved =
                                  toursProvider.isTourSaved(tour.id);
                              return Padding(
                                key: ValueKey(tour.id),
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _TourCard(
                                  tour: tour,
                                  imageUrls:
                                      _getTourImageUrls(tour, placesProvider),
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    context.push('/tour/${tour.id}');
                                  },
                                  onDirections: () {
                                    AppFeedback.tap();
                                    context.push(
                                      '/map?tourOnly=true&placeIds=${tour.placeIds.join(",")}',
                                    );
                                  },
                                  isSaved: isSaved,
                                  onSave: () {
                                    AppFeedback.tap();
                                    toursProvider.toggleSaveTour(tour);
                                    if (context.mounted) {
                                      final saved =
                                          toursProvider.isTourSaved(tour.id);
                                      if (saved) {
                                        Provider.of<ActivityLogProvider>(
                                                context,
                                                listen: false)
                                            .tourSaved(tour.name);
                                      } else {
                                        Provider.of<ActivityLogProvider>(
                                                context,
                                                listen: false)
                                            .tourUnsaved(tour.name);
                                      }
                                      AppFeedback.success(
                                        context,
                                        saved
                                            ? l10n.savedToFavourites(tour.name)
                                            : l10n.removedFromFavourites(
                                                tour.name),
                                      );
                                    }
                                  },
                                  onAddToTrip: () =>
                                      _showAddTourToTripDialog(context, tour),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecommendedSection(
    BuildContext context,
    List<Place> places,
    List<String> userInterests,
    InterestsProvider interestsProvider, {
    Animation<double>? sectionFade,
  }) {
    List<Place> display;
    String title;
    String? subtitle;

    final recommended = places.where((p) {
      final catId = (p.categoryId ?? '').toLowerCase();
      final tags = (p.tags ?? []).map((t) => t.toLowerCase()).toList();
      return userInterests.any(
        (id) =>
            catId == id.toLowerCase() ||
            tags.any((t) => t.contains(id.toLowerCase())),
      );
    }).toList();

    if (recommended.isNotEmpty) {
      display = recommended.length > 6
          ? (recommended..shuffle()).take(6).toList()
          : recommended;
      title = AppLocalizations.of(context)!.recommendedForYou;
      subtitle = AppLocalizations.of(context)!
          .basedOnInterests(userInterests.take(3).join(', '));
    } else if (places.isNotEmpty) {
      display = [...places]
        ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      display = display.take(6).toList();
      title = AppLocalizations.of(context)!.popularInTripoli;
      subtitle = AppLocalizations.of(context)!.topRatedPlaces;
    } else {
      // Loading + empty: show skeleton so page structure appears in ms (HCI: immediate feedback).
      final isLoading = Provider.of<PlacesProvider>(context).isLoading;
      if (!isLoading) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      return _buildRecommendedSkeletonSliver(context);
    }

    final featured = display.first;
    final rest = display.length > 1 ? display.sublist(1) : <Place>[];

    final Widget content = RepaintBoundary(
      child: Column(
        children: [
          SizedBox(height: _ExploreLayout.sectionGap(context)),
          _panel(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: FontAwesomeIcons.heart,
                  title: title,
                  subtitle: subtitle,
                ),
                const SizedBox(height: 16),
                _FeaturedSpotlightCard(
                  place: featured,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/place/${featured.id}');
                  },
                ),
                if (rest.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.moreToExplore,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Builder(
                    builder: (ctx) {
                      final w = MediaQuery.sizeOf(ctx).width;
                      final pad = _Responsive.horizontalPadding(ctx);
                      final gap = _ExploreLayout.cardGap(context);
                      final divisor = _Responsive.isVerySmallPhone(ctx)
                          ? 2.6
                          : (w < 320 ? 2.5 : 2.4);
                      final cardWidth = (w - pad * 2 - gap * 2) / divisor;

                      return SizedBox(
                        height: _ExploreLayout.recommendedCardHeight(context),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.zero,
                          cacheExtent: 120,
                          itemCount: rest.length,
                          itemBuilder: (context, index) {
                            final place = rest[index];
                            return Padding(
                              key: ValueKey(place.id),
                              padding: EdgeInsetsDirectional.only(
                                end: index < rest.length - 1 ? gap : 0,
                              ),
                              child: RepaintBoundary(
                                child: _RecommendedCard(
                                  place: place,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context.push('/place/${place.id}');
                                  },
                                  width: cardWidth,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return SliverToBoxAdapter(
      child: sectionFade != null
          ? FadeTransition(opacity: sectionFade, child: content)
          : content,
    );
  }

  /// Skeleton for recommended section when loading and places empty (paint in ms).
  SliverToBoxAdapter _buildRecommendedSkeletonSliver(BuildContext context) {
    final pad = _Responsive.horizontalPadding(context);
    final gap = _ExploreLayout.cardGap(context);
    final cardHeight = _ExploreLayout.recommendedCardHeight(context);
    final w = MediaQuery.sizeOf(context).width;
    final cardWidth = (w - pad * 2 - gap * 2) / 2.4;
    final featuredWidth = w - pad * 2;

    return SliverToBoxAdapter(
      child: Semantics(
        label: 'Loading recommended places',
        liveRegion: true,
        child: RepaintBoundary(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: _ExploreLayout.sectionGap(context)),
              _panel(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: FontAwesomeIcons.heart,
                      title: AppLocalizations.of(context)!.recommendedForYou,
                      subtitle: AppLocalizations.of(context)!.topRatedPlaces,
                    ),
                    const SizedBox(height: 16),
                    _ExploreSkeletonCard(
                      width: featuredWidth,
                      height: 200,
                      compact: false,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: cardHeight,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        children: List.generate(
                            4,
                            (i) => Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    end: i < 3 ? gap : 0,
                                  ),
                                  child: _ExploreSkeletonCard(
                                    width: cardWidth,
                                    height: cardHeight,
                                    compact: true,
                                  ),
                                )),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getTourImageUrls(Tour tour, PlacesProvider placesProvider) {
    final urls = <String>[];
    if (tour.image.isNotEmpty) urls.add(tour.image);
    for (final placeId in tour.placeIds) {
      final place = placesProvider.getPlaceById(placeId);
      if (place != null &&
          place.images.isNotEmpty &&
          !urls.contains(place.images.first)) {
        urls.add(place.images.first);
      }
    }
    if (urls.isEmpty) urls.addAll(AppImages.intro);
    return urls;
  }

  Widget _buildToursSection(
    BuildContext context,
    List<Tour> tours,
    ToursProvider toursProvider, {
    Animation<double>? sectionFade,
  }) {
    final Widget content = RepaintBoundary(
      child: Column(
        children: [
          SizedBox(height: _ExploreLayout.sectionGap(context)),
          _panel(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: FontAwesomeIcons.compass,
                  title: AppLocalizations.of(context)!.aTourInTripoli,
                  actionLabel: AppLocalizations.of(context)!.viewAll,
                  onAction: () => _showToursSheet(context),
                ),
                if (toursProvider.isLoading) ...[
                  const SizedBox(height: 10),
                  _TourSectionLoading(),
                ] else if (tours.isEmpty) ...[
                  const SizedBox(height: 10),
                  _TourSectionEmpty(),
                ] else ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: _ExploreLayout.tourCardHeight(context),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      clipBehavior: Clip.none,
                      cacheExtent: 200,
                      itemCount: tours.length,
                      itemBuilder: (context, index) {
                        final tour = tours[index];
                        final isSaved = toursProvider.isTourSaved(tour.id);
                        final placesProvider = Provider.of<PlacesProvider>(
                          context,
                          listen: false,
                        );
                        return _TourCard(
                          tour: tour,
                          imageUrls: _getTourImageUrls(tour, placesProvider),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.push('/tour/${tour.id}');
                          },
                          onDirections: () {
                            AppFeedback.tap();
                            context.push(
                              '/map?tourOnly=true&placeIds=${tour.placeIds.join(",")}',
                            );
                          },
                          isSaved: isSaved,
                          onSave: () {
                            AppFeedback.tap();
                            toursProvider.toggleSaveTour(tour);
                            if (context.mounted) {
                              final saved = toursProvider.isTourSaved(tour.id);
                              if (saved) {
                                Provider.of<ActivityLogProvider>(context,
                                        listen: false)
                                    .tourSaved(tour.name);
                              } else {
                                Provider.of<ActivityLogProvider>(context,
                                        listen: false)
                                    .tourUnsaved(tour.name);
                              }
                              AppFeedback.success(
                                context,
                                saved
                                    ? AppLocalizations.of(context)!
                                        .savedToFavourites(tour.name)
                                    : AppLocalizations.of(context)!
                                        .removedFromFavourites(tour.name),
                              );
                            }
                          },
                          onAddToTrip: () =>
                              _showAddTourToTripDialog(context, tour),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return SliverToBoxAdapter(
      child: sectionFade != null
          ? FadeTransition(opacity: sectionFade, child: content)
          : content,
    );
  }

  Widget _buildCategoriesSection(
    BuildContext context,
    List<models.Category> categories,
    List<Place> places,
    PlacesProvider placesProvider, {
    Animation<double>? sectionFade,
  }) {
    List<Place> displayPlaces = places;
    if (_freeOnly) {
      displayPlaces = displayPlaces
          .where(
            (p) =>
                p.price == null ||
                p.price == '0' ||
                (p.price ?? '').toLowerCase() == 'free',
          )
          .toList();
    }
    if (_placeSortOrder == 'topRated') {
      displayPlaces = [...displayPlaces]
        ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    } else if (_placeSortOrder == 'freeFirst') {
      displayPlaces = [...displayPlaces]..sort((a, b) {
          final aFree = a.price == null ||
              a.price == '0' ||
              (a.price ?? '').toLowerCase() == 'free';
          final bFree = b.price == null ||
              b.price == '0' ||
              (b.price ?? '').toLowerCase() == 'free';
          if (aFree == bFree) return 0;
          return aFree ? -1 : 1;
        });
    }
    // Loading + empty: show skeleton strip so layout appears in ms.
    if (displayPlaces.isEmpty && placesProvider.isLoading) {
      return _buildCategoriesSkeletonSliver(context);
    }
    final Widget content = RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: _ExploreLayout.sectionGap(context)),
          // Places by Category: title row with filter icon and close arrow behind the text.
          _CategoryFilterBar(
            titleWidget: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.22),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.layerGroup,
                    size: 22,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.placesByCategoryTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.2,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.discoverByArea,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            categories: categories,
            selectedId: _categoryFilterId,
            expanded: _categoryFilterExpanded,
            onExpandChanged: (v) => setState(() => _categoryFilterExpanded = v),
            onSelected: (id) {
              AppFeedback.selection();
              try {
                final name = categories.firstWhere((c) => c.id == id).name;
                Provider.of<ActivityLogProvider>(context, listen: false)
                    .filterUsed(name);
              } catch (_) {}
              setState(() => _categoryFilterId = id);
            },
            getIcon: _categoryIcon,
          ),
          const SizedBox(height: 20),
          ...(_categoryFilterId == null
                  ? categories
                  : categories.where((c) => c.id == _categoryFilterId).toList())
              .map((category) {
            final categoryPlaces = _getPlacesForCategory(
              category,
              displayPlaces,
            );
            return Padding(
              padding:
                  EdgeInsets.only(bottom: _ExploreLayout.sectionGap(context)),
              child: _panel(
                context,
                child: _CategorySection(
                  category: category,
                  places: categoryPlaces,
                  getIcon: _categoryIcon,
                  placesProvider: placesProvider,
                  onPlaceTap: (p) => context.push('/place/${p.id}'),
                  onViewAll: () {
                    AppFeedback.tap();
                    context.push('/map?category=${category.id}');
                  },
                  onPlaceMapTap: (p) {
                    AppFeedback.tap();
                    context.push('/map?placeId=${p.id}&placeIds=${p.id}');
                  },
                  onPlaceAddToTrip: (p) =>
                      _showAddPlaceToTripDialog(context, p),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
    return SliverToBoxAdapter(
      child: sectionFade != null
          ? FadeTransition(opacity: sectionFade, child: content)
          : content,
    );
  }

  /// Skeleton for places-by-category when loading and empty (paint in ms).
  SliverToBoxAdapter _buildCategoriesSkeletonSliver(BuildContext context) {
    final pad = _Responsive.horizontalPadding(context);
    final gap = _ExploreLayout.cardGap(context);
    final listHeight = _ExploreLayout.horizontalListHeight(context) + 24;
    final cardWidth = _Responsive.cardWidth(context, base: 268);

    return SliverToBoxAdapter(
      child: Semantics(
        label: 'Loading places',
        liveRegion: true,
        child: RepaintBoundary(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: _ExploreLayout.sectionGap(context)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.22),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.layerGroup,
                        size: 22,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.placesByCategoryTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.2,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(context)!.discoverByArea,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _panel(
                context,
                child: SizedBox(
                  height: listHeight,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    children: List.generate(
                        4,
                        (i) => Padding(
                              padding: EdgeInsets.only(
                                right: i < 3 ? gap : 0,
                              ),
                              child: _ExploreSkeletonCard(
                                width: cardWidth,
                                height: listHeight - 24,
                                compact: false,
                              ),
                            )),
                  ),
                ),
              ),
              SizedBox(height: _ExploreLayout.sectionGap(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnershipFooter(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _Responsive.horizontalPadding(context),
        24,
        _Responsive.horizontalPadding(context),
        32,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.partnershipFooter,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Events sheet content: calendar month view + events list for selected day.
class _EventsCalendarContent extends StatefulWidget {
  final ScrollController scrollController;
  final List<Event> events;
  final double cardWidth;
  final double cardHeight;
  final bool Function(String eventId) isEventSaved;
  final void Function(Event event) onEventTap;
  final void Function(Event event) onToggleSave;

  const _EventsCalendarContent({
    required this.scrollController,
    required this.events,
    required this.cardWidth,
    required this.cardHeight,
    required this.isEventSaved,
    required this.onEventTap,
    required this.onToggleSave,
  });

  @override
  State<_EventsCalendarContent> createState() => _EventsCalendarContentState();
}

class _EventsCalendarContentState extends State<_EventsCalendarContent> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
  }

  static List<Event> _eventsForDay(List<Event> events, DateTime day) {
    return events.where((e) {
      final d = e.startDate;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eventsOnSelectedDay = _eventsForDay(widget.events, _selectedDay)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final hPad = ResponsiveUtils.contentPadding(context);
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.borderColor.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar<Event>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) => _eventsForDay(widget.events, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
              calendarFormat: CalendarFormat.month,
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                weekendTextStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                markerDecoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                outsideTextStyle: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textTertiary.withValues(alpha: 0.8),
                ),
                cellMargin:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              ),
              headerStyle: const HeaderStyle(
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                formatButtonVisible: false,
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                headerPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
                weekendStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            DateFormat('EEEE, MMM d').format(_selectedDay),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (eventsOnSelectedDay.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 40,
                      color: AppTheme.textTertiary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noEventsNow,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...eventsOnSelectedDay.map((event) {
              final isSaved = widget.isEventSaved(event.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EventCard(
                  event: event,
                  onTap: () => widget.onEventTap(event),
                  isSaved: isSaved,
                  onToggleSave: () => widget.onToggleSave(event),
                  width: widget.cardWidth,
                  height: widget.cardHeight,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _EventsLoadingSkeleton extends StatelessWidget {
  const _EventsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final hPad = ResponsiveUtils.contentPadding(context);
    final w = MediaQuery.sizeOf(context).width;
    final cardWidth = w - hPad * 2;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: cardWidth,
            height: 320,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.borderColor.withValues(alpha: 0.6)),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 16,
            width: cardWidth * 0.55,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < 3; i++) ...[
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.borderColor.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EventsErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.couldNotLoadData,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 18),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Event card — boarding-pass style: accent rail, image stub with date, perforated edge, main panel.
class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final double width;
  final double height;

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.isSaved,
    required this.onToggleSave,
    required this.width,
    required this.height,
  });

  static const _radius = 18.0;
  static const _accentWidth = 4.0;
  static const _notchRadius = 5.0;

  static String _formatDateLine(DateTime date, String locale) =>
      DateFormat('EEE, MMM d', locale).format(date);
  static String _formatTime(DateTime date, String locale) =>
      DateFormat('jm', locale).format(date);

  static Color _categoryColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('festival') || c.contains('music')) {
      return AppTheme.accentColor;
    }
    if (c.contains('workshop') || c.contains('art')) {
      return AppTheme.secondaryColor;
    }
    if (c.contains('food')) {
      return AppTheme.successColor;
    }
    return AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final imageUrl = event.image;
    final categoryColor = _categoryColor(event.category);
    final isFree = event.price == null || event.price == 0;
    final priceText =
        event.priceDisplay ?? (isFree ? l10n.free : '\$${event.price}');
    final stubW = ResponsiveUtils.eventTicketStubWidth(context);
    final tight = height < 132;
    final titleSize = tight ? 13.5 : 15.0;
    final metaSize = tight ? 11.5 : 12.5;
    final locMaxLines = height >= 138 ? 2 : 1;
    final dayNum = '${event.startDate.day}';
    final monthShort = DateFormat('MMM', locale).format(event.startDate);
    final weekdayShort = DateFormat('EEE', locale).format(event.startDate);

    return Material(
      color: AppTheme.surfaceColor,
      elevation: 2,
      shadowColor: AppTheme.textPrimary.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(
          color: AppTheme.borderColor.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: SizedBox(
          width: width,
          height: height,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand accent rail
                Container(
                  width: _accentWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        categoryColor,
                        categoryColor.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                // Stub: cover image + date block + perforations
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(0),
                        bottomLeft: Radius.circular(0),
                      ),
                      child: SizedBox(
                        width: stubW,
                        height: height,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned.fill(
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? AppImage(
                                      src: imageUrl,
                                      fit: BoxFit.cover,
                                      cacheWidth: 220,
                                      cacheHeight: 280,
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            categoryColor,
                                            categoryColor.withValues(alpha: 0.65),
                                          ],
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.confirmation_number_rounded,
                                          size: tight ? 26 : 30,
                                          color: Colors.white
                                              .withValues(alpha: 0.92),
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: EdgeInsets.fromLTRB(
                                  6,
                                  tight ? 18 : 22,
                                  6,
                                  tight ? 6 : 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.78),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      dayNum,
                                      style: TextStyle(
                                        fontSize: tight ? 20 : 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      monthShort.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: tight ? 9 : 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                        color: Colors.white
                                            .withValues(alpha: 0.92),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ...List.generate(4, (i) {
                      final frac = (i + 1) / 5;
                      final top = (height * frac - _notchRadius).clamp(
                        6.0,
                        height - 6 - _notchRadius * 2,
                      );
                      return Positioned(
                        left: stubW - _notchRadius,
                        top: top,
                        child: Container(
                          width: _notchRadius * 2,
                          height: _notchRadius * 2,
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                // Main panel
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      tight ? 8 : 10,
                      tight ? 6 : 8,
                      6,
                      tight ? 6 : 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    weekdayShort,
                                    style: TextStyle(
                                      fontSize: tight ? 10 : 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: categoryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    event.name,
                                    style: TextStyle(
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.25,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: onToggleSave,
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    isSaved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    size: tight ? 19 : 21,
                                    color: isSaved
                                        ? AppTheme.primaryColor
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: tight ? 4 : 5),
                        Row(
                          children: [
                            Icon(
                              Icons.event_rounded,
                              size: tight ? 12 : 13,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${_formatDateLine(event.startDate, locale)} · ${_formatTime(event.startDate, locale)}',
                                style: TextStyle(
                                  fontSize: metaSize,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: tight ? 3 : 4),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: tight ? 12 : 13,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location,
                                style: TextStyle(
                                  fontSize: tight ? 10.5 : 11.5,
                                  color: AppTheme.textSecondary,
                                  height: 1.25,
                                ),
                                maxLines: locMaxLines,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: tight ? 4 : 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final narrowPanel = constraints.maxWidth < 172;
                            Widget categoryPill() => Container(
                                  width: narrowPanel ? double.infinity : null,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: tight ? 6 : 8,
                                    vertical: tight ? 3 : 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceVariant
                                        .withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.borderColor
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  child: Text(
                                    event.category,
                                    style: TextStyle(
                                      fontSize: tight ? 10.5 : 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSecondary,
                                    ),
                                    maxLines: narrowPanel ? 2 : 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                            Widget pricePill() => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: tight ? 8 : 10,
                                    vertical: tight ? 4 : 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isFree
                                        ? AppTheme.successColor
                                            .withValues(alpha: 0.14)
                                        : categoryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isFree
                                          ? AppTheme.successColor
                                              .withValues(alpha: 0.4)
                                          : categoryColor.withValues(alpha: 0.32),
                                    ),
                                  ),
                                  child: Text(
                                    priceText,
                                    style: TextStyle(
                                      fontSize: tight ? 11.5 : 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: isFree
                                          ? AppTheme.successColor
                                          : categoryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                            if (narrowPanel) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  categoryPill(),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: pricePill(),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: categoryPill()),
                                const SizedBox(width: 8),
                                pricePill(),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}

class _FeaturedSpotlightCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _FeaturedSpotlightCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = place.images.isNotEmpty ? place.images.first : null;
    final priceText = (place.price == null || place.price == '0')
        ? AppLocalizations.of(context)!.free
        : '\$${place.price}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              SizedBox(
                height: 232,
                width: double.infinity,
                child: imageUrl != null
                    ? AppImage(
                        src: imageUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 400,
                        cacheHeight: 400,
                      )
                    : Container(
                        color: AppTheme.surfaceVariant,
                        child: const Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                      ),
              ),
              Container(
                height: 232,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.topPick,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${place.rating ?? 4.5}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (place.price == null || place.price == '0')
                                  ? AppTheme.successColor.withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              priceText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.explore,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vertical place card for "More to explore" - same style as top-rated, 1/3 width.
class _RecommendedCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final double width;

  const _RecommendedCard({
    required this.place,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = place.images.isNotEmpty ? place.images.first : null;
    final priceText = (place.price == null || place.price == '0')
        ? AppLocalizations.of(context)!.free
        : '\$${place.price}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: _ExploreLayout.recommendedCardHeight(context),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              imageUrl != null
                  ? AppImage(
                      src: imageUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 400,
                      cacheHeight: 300,
                    )
                  : Container(
                      color: AppTheme.surfaceVariant,
                      child: const Icon(
                        Icons.place_rounded,
                        size: 40,
                        color: AppTheme.textTertiary,
                      ),
                    ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Top badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.place,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom content
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${place.rating ?? 4.5}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (place.price == null || place.price == '0')
                                  ? AppTheme.successColor.withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              priceText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cycles through images on a timer for a dynamic card effect.
class _CyclingImageStack extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final BorderRadius? borderRadius;

  static const _cycleDuration = Duration(seconds: 3);

  const _CyclingImageStack({
    required this.imageUrls,
    this.height = 160,
    this.borderRadius,
  });

  @override
  State<_CyclingImageStack> createState() => _CyclingImageStackState();
}

class _CyclingImageStackState extends State<_CyclingImageStack> {
  late PageController _pageController;
  Timer? _cycleTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.imageUrls.length > 1) {
      _cycleTimer = Timer.periodic(_CyclingImageStack._cycleDuration, (_) {
        if (!mounted) return;
        final next = (_pageController.page?.round() ?? 0) + 1;
        final target = next >= widget.imageUrls.length ? 0 : next;
        _pageController.animateToPage(
          target,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return _placeholder(widget.height);
    }
    if (widget.imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: AppImage(
            src: widget.imageUrls.first,
            fit: BoxFit.cover,
            cacheWidth: 400,
            cacheHeight: 400,
            errorWidget: (_, __, ___) => _placeholder(widget.height),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.imageUrls.length,
          itemBuilder: (_, i) => AppImage(
            src: widget.imageUrls[i],
            fit: BoxFit.cover,
            cacheWidth: 400,
            cacheHeight: 400,
            errorWidget: (_, __, ___) => _placeholder(widget.height),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(double h) => Container(
        height: h,
        color: AppTheme.surfaceVariant,
        child: const Icon(
          Icons.image_outlined,
          size: 48,
          color: AppTheme.textTertiary,
        ),
      );
}

/// Compact tour card - phone-optimized UI/UX.
class _TourSectionLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cardHeight = _ExploreLayout.tourCardHeight(context);
    final w = MediaQuery.sizeOf(context).width;
    final widthFactor =
        _Responsive.isVerySmallPhone(context) ? 0.76 : (w < 380 ? 0.82 : 0.88);
    final cardWidth =
        w * widthFactor - _Responsive.horizontalPadding(context) * 2;

    return SizedBox(
      height: cardHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _TourCardSkeleton(width: cardWidth, height: cardHeight),
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: _ExploreLayout.cardGap(context),
            ),
            child: _TourCardSkeleton(width: cardWidth, height: cardHeight),
          ),
        ],
      ),
    );
  }
}

class _TourCardSkeleton extends StatelessWidget {
  const _TourCardSkeleton({required this.width, required this.height});

  final double width;
  final double height;

  static const _radius = 20.0;
  static const _imageRatio = 0.58;

  @override
  Widget build(BuildContext context) {
    final imageH = (height * _imageRatio).clamp(130.0, 160.0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Column(
          children: [
            Container(
              height: imageH,
              color: AppTheme.borderColor.withValues(alpha: 0.4),
              child: Center(
                child: Icon(
                  FontAwesomeIcons.compass,
                  size: 36,
                  color: AppTheme.textTertiary.withValues(alpha: 0.5),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.textTertiary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 24,
                      width: 90,
                      decoration: BoxDecoration(
                        color: AppTheme.textTertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          height: 36,
                          width: 75,
                          decoration: BoxDecoration(
                            color:
                                AppTheme.textTertiary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourSectionEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              FontAwesomeIcons.compass,
              size: 20,
              color: AppTheme.primaryColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.noToursAvailable,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.checkBackTours,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final Tour tour;
  final List<String> imageUrls;
  final VoidCallback onTap;
  final VoidCallback onDirections;
  final bool isSaved;
  final VoidCallback? onSave;
  final VoidCallback? onAddToTrip;

  const _TourCard({
    required this.tour,
    required this.imageUrls,
    required this.onTap,
    required this.onDirections,
    required this.isSaved,
    this.onSave,
    this.onAddToTrip,
  });

  static const _radius = 20.0;
  static const _imageRatio = 0.58;

  @override
  Widget build(BuildContext context) {
    final cardHeight = _ExploreLayout.tourCardHeight(context);
    final imageHeight = (cardHeight * _imageRatio).clamp(120.0, 188.0);
    final w = MediaQuery.sizeOf(context).width;
    final widthFactor =
        _Responsive.isVerySmallPhone(context) ? 0.76 : (w < 380 ? 0.82 : 0.88);
    final cardWidth =
        w * widthFactor - _Responsive.horizontalPadding(context) * 2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin:
            EdgeInsetsDirectional.only(end: _ExploreLayout.cardGap(context)),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.03),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero image
              SizedBox(
                height: imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _CyclingImageStack(
                      imageUrls: imageUrls,
                      height: imageHeight,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(_radius),
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.0, 0.4, 0.92],
                        ),
                      ),
                    ),
                    // Badge pill
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          tour.badge ?? AppLocalizations.of(context)!.tour,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    // Glass save button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: onSave,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              size: 20,
                              color:
                                  isSaved ? AppTheme.accentColor : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Stats overlay
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _glassStatChip(
                            icon: FontAwesomeIcons.clock,
                            label: tour.duration.isNotEmpty
                                ? tour.duration
                                : '${tour.durationHours}h',
                          ),
                          _glassStatChip(
                            icon: FontAwesomeIcons.mapLocationDot,
                            label: AppLocalizations.of(context)!
                                .stops(tour.locations),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tour.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Rating + price row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  FontAwesomeIcons.solidStar,
                                  size: 11,
                                  color: AppTheme.accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tour.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (tour.reviews > 0)
                                  Text(
                                    ' (${tour.reviews})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Text(
                              tour.priceDisplay,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: tour.price == 0
                                    ? AppTheme.successColor
                                    : AppTheme.primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Action row
                      Row(
                        children: [
                          Expanded(
                            child: _outlineActionButton(
                              icon: Icons.route_rounded,
                              label: AppLocalizations.of(context)!.map,
                              onTap: onDirections,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _filledActionButton(
                              icon: Icons.add_rounded,
                              label: AppLocalizations.of(context)!.addToTrip,
                              onTap: onAddToTrip ?? () {},
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: Colors.white.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlineActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filledActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.primaryColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final models.Category category;
  final List<Place> places;
  final IconData Function(String) getIcon;
  final PlacesProvider placesProvider;
  final void Function(Place) onPlaceTap;
  final VoidCallback onViewAll;
  final void Function(Place)? onPlaceMapTap;
  final void Function(Place)? onPlaceAddToTrip;

  const _CategorySection({
    required this.category,
    required this.places,
    required this.getIcon,
    required this.placesProvider,
    required this.onPlaceTap,
    required this.onViewAll,
    this.onPlaceMapTap,
    this.onPlaceAddToTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  getIcon(category.id),
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onViewAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.viewAll,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isRtl(context)
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (places.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.explore_outlined,
                    size: 32,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppLocalizations.of(context)!.noPlacesYet,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.categoryUpdatedSoon,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: _Responsive.isCompact(context)
                ? _ExploreLayout.horizontalListHeight(context) + 40
                : _ExploreLayout.horizontalListHeight(context) + 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              clipBehavior: Clip.none,
              cacheExtent: 120,
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                return Padding(
                  key: ValueKey(place.id),
                  padding: EdgeInsetsDirectional.only(
                    end: index < places.length - 1
                        ? _ExploreLayout.cardGap(context)
                        : 0,
                  ),
                  child: RepaintBoundary(
                    child: _ExplorePlaceCard(
                      place: place,
                      placesProvider: placesProvider,
                      onTap: () => onPlaceTap(place),
                      onMapTap: onPlaceMapTap != null
                          ? () => onPlaceMapTap!(place)
                          : null,
                      onAddToTrip: onPlaceAddToTrip != null
                          ? () => onPlaceAddToTrip!(place)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ExplorePlaceCard extends StatelessWidget {
  final Place place;
  final PlacesProvider placesProvider;
  final VoidCallback onTap;
  final VoidCallback? onMapTap;
  final VoidCallback? onAddToTrip;

  const _ExplorePlaceCard({
    required this.place,
    required this.placesProvider,
    required this.onTap,
    this.onMapTap,
    this.onAddToTrip,
  });

  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    final isSaved = placesProvider.isPlaceSaved(place.id);
    final imageUrl = place.images.isNotEmpty ? place.images.first : null;
    final isFree = place.price == null || place.price == '0';
    final priceText =
        isFree ? AppLocalizations.of(context)!.free : '\$${place.price}';
    final duration = place.duration ?? '1-2 hours';

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = _Responsive.cardWidth(context, base: 268);
        final cardH = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : _ExploreLayout.horizontalListHeight(context);
        final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
        final cacheW = (cardW * dpr).round().clamp(120, 2400);
        final cacheH = (cardH * dpr).round().clamp(120, 2400);
        return GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: cardW,
            height: cardH,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppTheme.textPrimary.withValues(alpha: 0.03),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Full-bleed image (fills card; decode matches slot aspect)
                    Positioned.fill(
                      child: imageUrl != null
                          ? AppImage(
                              src: imageUrl,
                              fit: BoxFit.cover,
                              cacheWidth: cacheW,
                              cacheHeight: cacheH,
                            )
                          : Container(
                              color: AppTheme.surfaceVariant,
                              child: const Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                    ),
                    // Gradient overlay (fills card so layout stays stable)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.0, 0.35, 0.75],
                            ),
                          ),
                        ),
                      ),
                    ),
              // Top overlays
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    place.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      try {
                        await placesProvider.toggleSavePlace(place);
                        if (context.mounted) {
                          AppSnackBars.showSuccess(
                              context,
                              placesProvider.isPlaceSaved(place.id)
                                  ? 'Saved to favourites'
                                  : 'Removed from saved');
                        }
                      } catch (_) {
                        if (context.mounted) {
                          AppSnackBars.showError(
                              context, 'Couldn\'t save place');
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        isSaved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color: isSaved ? Colors.red.shade400 : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom content overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _glassStat(
                            icon: Icons.star_rounded,
                            label: place.rating?.toStringAsFixed(1) ?? '4.5',
                            iconColor: AppTheme.accentColor,
                          ),
                          _glassStat(
                            icon: Icons.schedule_rounded,
                            label: duration,
                            iconColor: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isFree
                                    ? AppTheme.successColor
                                        .withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                priceText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: onMapTap ??
                                  () {
                                    AppFeedback.tap();
                                    context.push(
                                        '/map?placeId=${place.id}&placeIds=${place.id}');
                                  },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.directions_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(context)!.map,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Material(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: onAddToTrip ??
                                  () {
                                    AppFeedback.tap();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(context)!
                                              .addedToTrip(place.name),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.add_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(context)!.add,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
      },
    );
  }

  Widget _glassStat({
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor ?? Colors.white.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

/// Add-to-Trip picker bottom sheet: search trips, pick one, or go to Trips to create.
class _AddToTripPickerSheet extends StatefulWidget {
  const _AddToTripPickerSheet({
    required this.trips,
    required this.onTripSelected,
    required this.onGoToTrips,
  });

  final List<Trip> trips;
  final void Function(Trip trip) onTripSelected;
  final VoidCallback onGoToTrips;

  @override
  State<_AddToTripPickerSheet> createState() => _AddToTripPickerSheetState();
}

class _AddToTripPickerSheetState extends State<_AddToTripPickerSheet> {
  String _query = '';

  /// Build a searchable string for a trip: name + date parts and formatted dates.
  static String _searchableString(Trip t) {
    final start = t.startDate;
    final end = t.endDate;
    final d = start.day;
    final m = start.month;
    final y = start.year;
    final d2 = end.day;
    final m2 = end.month;
    final y2 = end.year;
    final dateRange = '$d/$m/$y â€“ $d2/$m2/$y2';
    final monthName = DateFormat.MMM().format(start); // e.g. "Mar"
    final monthNameLong = DateFormat.MMMM().format(start); // e.g. "March"
    return '${t.name.toLowerCase()} '
        '$d $m $y $d2 $m2 $y2 '
        '${d.toString().padLeft(2, '0')} ${m.toString().padLeft(2, '0')} $y '
        '${d2.toString().padLeft(2, '0')} ${m2.toString().padLeft(2, '0')} $y2 '
        '${dateRange.toLowerCase()} '
        '${monthName.toLowerCase()} ${monthNameLong.toLowerCase()}';
  }

  List<Trip> get _filteredTrips {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.trips;
    return widget.trips.where((t) => _searchableString(t).contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filteredTrips;
    final hasTrips = widget.trips.isNotEmpty;
    final hasResults = filtered.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                l10n.addToTrip,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: l10n.searchTrips,
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.textTertiary, size: 22),
                      filled: true,
                      fillColor: AppTheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          size: 16, color: AppTheme.textTertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.searchTripsExample,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textTertiary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      const _SearchChip(
                          label: 'Name', icon: Icons.badge_outlined),
                      _SearchChip(
                          label: l10n.date, icon: Icons.calendar_today_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: hasTrips
                  ? (hasResults
                      ? ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final trip = filtered[i];
                            final dateStr =
                                '${trip.startDate.day}/${trip.startDate.month}/${trip.startDate.year} â€“ ${trip.endDate.day}/${trip.endDate.month}/${trip.endDate.year}';
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => widget.onTripSelected(trip),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.map_rounded,
                                            color: AppTheme.primaryColor,
                                            size: 22),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              trip.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              dateStr,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                          Icons.add_circle_outline_rounded,
                                          color: AppTheme.primaryColor,
                                          size: 22),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  size: 48, color: AppTheme.textTertiary),
                              const SizedBox(height: 12),
                              Text(
                                l10n.noTripsMatchSearch,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.goToTripsToCreate,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ))
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.luggage_rounded,
                              size: 48, color: AppTheme.textTertiary),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noTripsYet,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.goToTripsToCreate,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onGoToTrips,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(hasTrips ? l10n.createNewTrip : l10n.createTrip),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet to set visit start/end time when adding a place to a trip. Ensures no time conflict.
class _AddPlaceTimeSheet extends StatefulWidget {
  const _AddPlaceTimeSheet({
    required this.trip,
    required this.place,
    required this.initialDateStr,
    required this.dates,
    required this.tripsProvider,
    required this.onAdded,
    required this.onCancel,
  });

  final Trip trip;
  final Place place;
  final String initialDateStr;
  final List<String> dates;
  final TripsProvider tripsProvider;
  final VoidCallback onAdded;
  final VoidCallback onCancel;

  @override
  State<_AddPlaceTimeSheet> createState() => _AddPlaceTimeSheetState();
}

class _AddPlaceTimeSheetState extends State<_AddPlaceTimeSheet> {
  late String _selectedDateStr;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _selectedDateStr = widget.initialDateStr;
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatDateDisplay(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return dateStr;
    final dt = DateTime(y, m, d);
    return DateFormat('EEE, MMM d').format(dt);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && mounted) {
      setState(() {
        _startTime = picked;
        if (_toMinutes(_endTime) <= _toMinutes(picked)) {
          _endTime = TimeOfDay(hour: picked.hour + 1, minute: picked.minute);
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && mounted) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _addToTrip() async {
    final startMin = _toMinutes(_startTime);
    final endMin = _toMinutes(_endTime);
    if (endMin <= startMin) {
      AppFeedback.error(
          context, AppLocalizations.of(context)!.endTimeAfterStart);
      return;
    }
    final slots = _getSlotsForDay(widget.trip, _selectedDateStr);
    if (_hasTimeConflict(startMin, endMin, slots)) {
      final duration = endMin - startMin;
      final suggested = _findNextFreeMinute(slots, duration);
      final l10n = AppLocalizations.of(context)!;
      final msg = suggested != null
          ? '${l10n.timeConflict} ${l10n.tryTimeSuggestion(_minutesToTime(suggested))}'
          : l10n.timeConflict;
      AppFeedback.error(context, msg);
      return;
    }
    setState(() => _isAdding = true);
    try {
      await widget.tripsProvider.addPlaceToTrip(
        widget.trip.id,
        widget.place.id,
        _selectedDateStr,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
      );
      if (!mounted) return;
      Provider.of<ActivityLogProvider>(context, listen: false)
          .addToTrip(widget.place.name, widget.trip.name);
      AppFeedback.success(context,
          AppLocalizations.of(context)!.addedToTrip(widget.place.name));
      widget.onAdded();
    } catch (_) {
      if (mounted) {
        AppFeedback.error(
            context, AppLocalizations.of(context)!.couldNotLoadData);
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.setVisitTime,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.dates.length > 1) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedDateStr,
                  decoration: InputDecoration(
                    labelText: l10n.date,
                    filled: true,
                    fillColor: AppTheme.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  items: widget.dates
                      .map((d) => DropdownMenuItem(
                          value: d, child: Text(_formatDateDisplay(d))))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedDateStr = v ?? _selectedDateStr),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: _TimeChip(
                      label: l10n.setStartTime,
                      time: _formatTime(_startTime),
                      onTap: _pickStartTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeChip(
                      label: l10n.setEndTime,
                      time: _formatTime(_endTime),
                      onTap: _pickEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: _isAdding ? null : widget.onCancel,
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isAdding ? null : _addToTrip,
                      child: _isAdding
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.addToTrip),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip(
      {required this.label, required this.time, required this.onTap});

  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchChip extends StatelessWidget {
  const _SearchChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
