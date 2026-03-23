import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/trips_provider.dart';
import '../providers/places_provider.dart';
import '../models/trip.dart';
import '../models/place.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_profile_icon_button.dart';
import '../theme/app_theme.dart';
import '../utils/app_share.dart';
import '../utils/responsive_utils.dart';
import 'trips/trip_details_modal.dart';
import 'trips/trip_form_modal.dart';
import 'trips/trips_list_logic.dart';

class _TripsResponsive {
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static bool isCompact(BuildContext context) => width(context) < 360;
  static double horizontalPadding(BuildContext context) =>
      ResponsiveUtils.contentPadding(context);
}

BoxDecoration _tripsPanelDecoration() {
  return BoxDecoration(
    color: AppTheme.surfaceColor,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: AppTheme.textPrimary.withValues(alpha: 0.04),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: AppTheme.textPrimary.withValues(alpha: 0.02),
        blurRadius: 40,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  DateTime _calendarMonth = DateTime.now();
  DateTime? _selectedDate;
  bool _calendarVisible = false;
  TripSortMode _tripSortMode = TripSortMode.smart;
  final TextEditingController _tripFilterController = TextEditingController();
  /// When false, trips whose [TripPhase] is past are omitted from the list.
  bool _showPastTrips = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<TripsProvider>(context, listen: false).loadTrips();
    });
  }

  @override
  void dispose() {
    _tripFilterController.dispose();
    super.dispose();
  }

  void _clearTripListFilters() {
    _tripFilterController.clear();
    setState(() => _selectedDate = null);
  }

  @override
  Widget build(BuildContext context) {
    final tripsProvider = Provider.of<TripsProvider>(context);
    final trips = tripsProvider.trips;
    final filteredForStats = _filteredTripsForList(tripsProvider);
    final visibleTrips = _getVisibleTrips(tripsProvider);
    final summaryPlaces = filteredForStats.fold<int>(
        0, (s, t) => s + tripsProvider.getPlaceIdsForTrip(t).length);
    final hp = _TripsResponsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _TripsHeader(
            onNewTrip: () => _openCreateTripModal(context),
          ),
          if (tripsProvider.lastError != null &&
              tripsProvider.lastError!.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(hp, 8, hp, 0),
              child: Material(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => tripsProvider.loadTrips(forceRefresh: true),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 20, color: AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tripsProvider.lastError!,
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textPrimary),
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.retry,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => tripsProvider.loadTrips(forceRefresh: true),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hp, 16, hp, 28),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TripsCalendarToggle(
                      isExpanded: _calendarVisible,
                      calendarMonth: _calendarMonth,
                      selectedDate: _selectedDate,
                      onToggle: () =>
                          setState(() => _calendarVisible = !_calendarVisible),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _TripsCalendar(
                          calendarMonth: _calendarMonth,
                          selectedDate: _selectedDate,
                          trips: trips,
                          tripsProvider: tripsProvider,
                          onMonthChanged: (m) =>
                              setState(() => _calendarMonth = m),
                          onDateSelected: (d) => setState(() =>
                              _selectedDate = d == _selectedDate ? null : d),
                          onClearFilter: () =>
                              setState(() => _selectedDate = null),
                        ),
                      ),
                      crossFadeState: _calendarVisible
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                    const SizedBox(height: 10),
                    _TripsListToolbar(
                      sortMode: _tripSortMode,
                      onSortChanged: (m) => setState(() => _tripSortMode = m),
                      filterController: _tripFilterController,
                      onFilterChanged: () => setState(() {}),
                      showPastTrips: _showPastTrips,
                      onShowPastTripsChanged: (v) =>
                          setState(() => _showPastTrips = v),
                    ),
                    const SizedBox(height: 10),
                    _TripsSummary(
                      totalTrips: filteredForStats.length,
                      totalPlaces: summaryPlaces,
                    ),
                    const SizedBox(height: 12),
                    if (trips.isEmpty)
                      _TripsEmptyState(
                          onCreate: () => _openCreateTripModal(context))
                    else if (visibleTrips.isEmpty)
                      _onlyPastTripsHiddenByFilter(tripsProvider)
                          ? _TripsPastHiddenState(
                              onShowPast: () =>
                                  setState(() => _showPastTrips = true),
                            )
                          : _TripsNoMatchState(
                              onClear: _clearTripListFilters,
                            )
                    else
                      ...visibleTrips.map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TripCard(
                              trip: t,
                              placeIds: tripsProvider.getPlaceIdsForTrip(t),
                              placesProvider:
                                  Provider.of<PlacesProvider>(context),
                              onTap: () => _openTripDetails(context, t),
                              onEdit: () => _openEditTripModal(context, t),
                              onDelete: () => _confirmDelete(context, t),
                            ),
                          )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  List<Trip> _listAfterSearchAndCalendar(TripsProvider provider) {
    var list = List<Trip>.from(provider.trips);
    list = filterTripsByQuery(list, _tripFilterController.text);
    if (_selectedDate != null) {
      list = list
          .where((t) => tripCoversCalendarDay(t, _selectedDate!))
          .toList();
    }
    return list;
  }

  /// True when the current search/calendar filters only match past trips and pasts are hidden.
  bool _onlyPastTripsHiddenByFilter(TripsProvider provider) {
    if (_showPastTrips) return false;
    final list = _listAfterSearchAndCalendar(provider);
    if (list.isEmpty) return false;
    final now = DateTime.now();
    return list.every((t) => tripPhase(t, now) == TripPhase.past);
  }

  /// Trips included in the list below (search + calendar + optional past filter), unsorted.
  List<Trip> _filteredTripsForList(TripsProvider provider) {
    var list = _listAfterSearchAndCalendar(provider);
    final now = DateTime.now();
    if (!_showPastTrips) {
      list =
          list.where((t) => tripPhase(t, now) != TripPhase.past).toList();
    }
    return list;
  }

  List<Trip> _getVisibleTrips(TripsProvider provider) {
    return sortTrips(_filteredTripsForList(provider), _tripSortMode);
  }

  void _openCreateTripModal(BuildContext context) {
    _showTripModal(context, trip: null);
  }

  void _openEditTripModal(BuildContext context, Trip trip) {
    _showTripModal(context, trip: trip);
  }

  void _openTripDetails(BuildContext context, Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TripDetailsModal(
        trip: trip,
        placeIds: Provider.of<TripsProvider>(context).getPlaceIdsForTrip(trip),
        onEdit: () {
          Navigator.pop(ctx);
          _openEditTripModal(context, trip);
        },
        onShare: () => _shareTrip(ctx, trip),
        onOpenMap: () {
          Navigator.pop(ctx);
          final ids = Provider.of<TripsProvider>(context)
              .getPlaceIdsForTrip(trip)
              .join(',');
          context.push('/map?tripOnly=true&placeIds=$ids');
        },
      ),
    );
  }

  Future<void> _shareTrip(BuildContext context, Trip trip) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.isGuest) {
      context.go('/login?redirect=${Uri.encodeComponent('/trips')}');
      return;
    }
    try {
      final res = await ApiService.instance
          .createTripShare(auth.authToken!, trip.id, expiresInHours: 168);
      final url = res['shareUrl'] as String? ?? '';
      if (url.isNotEmpty) {
        await sharePlainText(
            'Check out my trip "${trip.name}" in Visit Tripoli!\n$url');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Share link created'),
                behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to share: ${e.toString()}'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, Trip trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.deleteTripQuestion),
        content: Text(
          AppLocalizations.of(context)!.tripPermanentlyRemoved(trip.name),
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              Provider.of<TripsProvider>(context, listen: false)
                  .deleteTrip(trip.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.tripDeleted),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.textPrimary,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  void _showTripModal(BuildContext context, {Trip? trip}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TripFormModal(
        trip: trip,
        selectedDate: _selectedDate,
        onSaved: (message) {
          Navigator.pop(ctx);
          setState(() {});
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }
}

class _TripsHeader extends StatelessWidget {
  final VoidCallback onNewTrip;

  const _TripsHeader({required this.onNewTrip});

  @override
  Widget build(BuildContext context) {
    final hp = _TripsResponsive.horizontalPadding(context);
    final isCompact = _TripsResponsive.isCompact(context);
    final narrow = MediaQuery.sizeOf(context).width < 340;
    return SafeArea(
      bottom: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(hp, 20, hp, 20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.suitcase,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!.myTrips,
                          style: TextStyle(
                            fontSize: isCompact ? 20 : 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.planAdventuresAddPlaces,
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 13,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const AppProfileIconButton(iconColor: Colors.white, iconSize: 22),
            const SizedBox(width: 8),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onNewTrip();
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: narrow ? 14 : 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: narrow ? 18 : 20,
                        color: AppTheme.primaryColor,
                      ),
                      if (!narrow) ...[
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.newTrip,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ],
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

class _TripsCalendarToggle extends StatelessWidget {
  final bool isExpanded;
  final DateTime calendarMonth;
  final DateTime? selectedDate;
  final VoidCallback onToggle;

  const _TripsCalendarToggle({
    required this.isExpanded,
    required this.calendarMonth,
    required this.selectedDate,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(calendarMonth);
    final filterText = selectedDate != null
        ? DateFormat('EEE, MMM d').format(selectedDate!)
        : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: _tripsPanelDecoration(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(FontAwesomeIcons.calendarDays,
                    size: 18, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.calendar,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      filterText ?? monthLabel,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(FontAwesomeIcons.chevronDown,
                    size: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripsCalendar extends StatelessWidget {
  final DateTime calendarMonth;
  final DateTime? selectedDate;
  final List<Trip> trips;
  final TripsProvider tripsProvider;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onClearFilter;

  const _TripsCalendar({
    required this.calendarMonth,
    required this.selectedDate,
    required this.trips,
    required this.tripsProvider,
    required this.onMonthChanged,
    required this.onDateSelected,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final year = calendarMonth.year;
    final month = calendarMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startWeekday = (firstDay.weekday + 6) % 7;
    final daysInMonth = lastDay.day;

    final monthLabel = DateFormat('MMMM yyyy').format(DateTime(year, month));
    final datesWithTrips = _datesWithTrips(year, month);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _tripsPanelDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => onMonthChanged(DateTime(year, month - 1)),
                icon: const Icon(FontAwesomeIcons.chevronLeft, size: 14),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                  backgroundColor: AppTheme.surfaceVariant,
                  foregroundColor: AppTheme.textPrimary,
                ),
              ),
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => onMonthChanged(DateTime(year, month + 1)),
                icon: const Icon(FontAwesomeIcons.chevronRight, size: 14),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                  backgroundColor: AppTheme.surfaceVariant,
                  foregroundColor: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Text(d,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)))
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1.2,
            children: [
              ...List.generate(startWeekday, (_) => const SizedBox()),
              ...List.generate(daysInMonth, (i) {
                final day = i + 1;
                final date = DateTime(year, month, day);
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                final hasTrips = datesWithTrips.contains(dateStr);
                final isSelected = selectedDate != null &&
                    date.year == selectedDate!.year &&
                    date.month == selectedDate!.month &&
                    date.day == selectedDate!.day;

                return GestureDetector(
                  onTap: () => onDateSelected(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (hasTrips
                              ? AppTheme.primaryColor.withValues(alpha: 0.15)
                              : AppTheme.surfaceVariant),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimary,
                          ),
                        ),
                        if (hasTrips && !isSelected)
                          Positioned(
                            bottom: 3,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppTheme.successColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedDate == null
                    ? AppLocalizations.of(context)!.showingAllTrips
                    : AppLocalizations.of(context)!.tripsCoveringDate(
                        DateFormat('EEE, MMM d, y').format(selectedDate!)),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              if (selectedDate != null)
                TextButton(
                  onPressed: onClearFilter,
                  child: Text(AppLocalizations.of(context)!.clearDayFilter,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.primaryColor)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Set<String> _datesWithTrips(int year, int month) {
    final set = <String>{};
    for (final t in trips) {
      var cur = DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
      final end = DateTime(t.endDate.year, t.endDate.month, t.endDate.day);
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0);

      if (cur.isAfter(monthEnd) || end.isBefore(monthStart)) continue;
      if (cur.isBefore(monthStart)) cur = monthStart;
      var last = end.isAfter(monthEnd) ? monthEnd : end;

      while (!cur.isAfter(last)) {
        set.add(DateFormat('yyyy-MM-dd').format(cur));
        cur = cur.add(const Duration(days: 1));
      }
    }
    return set;
  }
}

class _TripsSummary extends StatelessWidget {
  final int totalTrips;
  final int totalPlaces;

  const _TripsSummary({
    required this.totalTrips,
    required this.totalPlaces,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _tripsPanelDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              icon: FontAwesomeIcons.suitcase,
              label: AppLocalizations.of(context)!.trips,
              value: '$totalTrips',
              color: AppTheme.primaryColor,
            ),
          ),
          Container(width: 1, height: 36, color: AppTheme.borderColor),
          Expanded(
            child: _summaryItem(
              icon: FontAwesomeIcons.locationDot,
              label: AppLocalizations.of(context)!.placesLinked,
              value: '$totalPlaces',
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _TripsListToolbar extends StatelessWidget {
  final TripSortMode sortMode;
  final ValueChanged<TripSortMode> onSortChanged;
  final TextEditingController filterController;
  final VoidCallback onFilterChanged;
  final bool showPastTrips;
  final ValueChanged<bool> onShowPastTripsChanged;

  const _TripsListToolbar({
    required this.sortMode,
    required this.onSortChanged,
    required this.filterController,
    required this.onFilterChanged,
    required this.showPastTrips,
    required this.onShowPastTripsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: filterController,
          builder: (context, value, _) {
            return TextField(
              controller: filterController,
              onChanged: (_) => onFilterChanged(),
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.searchTrips,
                hintStyle: const TextStyle(
                    fontSize: 14, color: AppTheme.textTertiary),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: AppTheme.textSecondary),
                suffixIcon: value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: AppTheme.textSecondary,
                        onPressed: () {
                          filterController.clear();
                          onFilterChanged();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Material(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(
                l10n.tripsShowPastTrips,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              value: showPastTrips,
              onChanged: onShowPastTripsChanged,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text(l10n.tripsSortSmart),
                selected: sortMode == TripSortMode.smart,
                onSelected: (_) => onSortChanged(TripSortMode.smart),
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: Text(l10n.tripsSortStartDate),
                selected: sortMode == TripSortMode.startSoonest,
                onSelected: (_) => onSortChanged(TripSortMode.startSoonest),
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: Text(l10n.tripsSortRecent),
                selected: sortMode == TripSortMode.recentlyCreated,
                onSelected: (_) =>
                    onSortChanged(TripSortMode.recentlyCreated),
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: Text(l10n.tripsSortName),
                selected: sortMode == TripSortMode.nameAtoZ,
                onSelected: (_) => onSortChanged(TripSortMode.nameAtoZ),
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripsNoMatchState extends StatelessWidget {
  final VoidCallback onClear;

  const _TripsNoMatchState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              size: 40, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noTripsMatchSearch,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onClear,
            child: Text(AppLocalizations.of(context)!.tripsClearListFilters),
          ),
        ],
      ),
    );
  }
}

class _TripsPastHiddenState extends StatelessWidget {
  final VoidCallback onShowPast;

  const _TripsPastHiddenState({required this.onShowPast});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_rounded,
              size: 40, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(
            l10n.tripsPastTripsHiddenHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onShowPast,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.tripsShowPastTrips),
          ),
        ],
      ),
    );
  }
}

class _TripsEmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _TripsEmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(FontAwesomeIcons.route,
                size: 40, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.yourFirstTripAwaits,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.createTripDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(FontAwesomeIcons.plus, size: 16),
            label: Text(AppLocalizations.of(context)!.createFirstTrip),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTripDateRange(Trip trip) {
  final s = trip.startDate;
  final e = trip.endDate;
  if (s.year == e.year && s.month == e.month && s.day == e.day) {
    return DateFormat('MMM d, y').format(s);
  }
  if (s.year == e.year && s.month == e.month) {
    return '${DateFormat('MMM').format(s)} ${s.day} – ${e.day}, ${s.year}';
  }
  return '${DateFormat('MMM d, y').format(s)} – ${DateFormat('MMM d, y').format(e)}';
}

int _daysBetween(DateTime start, DateTime end) {
  final s = DateTime(start.year, start.month, start.day);
  final e = DateTime(end.year, end.month, end.day);
  return e.difference(s).inDays + 1;
}

class _TripPhaseChip extends StatelessWidget {
  final TripPhase phase;

  const _TripPhaseChip({required this.phase});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (phase) {
      case TripPhase.upcoming:
        label = l10n.tripStatusUpcoming;
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
        break;
      case TripPhase.ongoing:
        label = l10n.tripStatusOngoing;
        bg = AppTheme.successColor.withValues(alpha: 0.12);
        fg = AppTheme.successColor;
        break;
      case TripPhase.past:
        label = l10n.tripStatusPast;
        bg = AppTheme.surfaceVariant;
        fg = AppTheme.textSecondary;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: fg,
        ),
      ),
    );
  }
}

class _TripDatePill extends StatelessWidget {
  final Trip trip;

  const _TripDatePill({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          const Icon(
            FontAwesomeIcons.calendar,
            size: 11,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _formatTripDateRange(trip),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCardActionButton extends StatelessWidget {
  final IconData icon;
  final Color foreground;
  final VoidCallback onPressed;

  const _TripCardActionButton({
    required this.icon,
    required this.foreground,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceVariant,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(icon, size: 14, color: foreground),
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final List<String> placeIds;
  final PlacesProvider placesProvider;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TripCard({
    required this.trip,
    required this.placeIds,
    required this.placesProvider,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final places = placeIds
        .map((id) => placesProvider.getPlaceById(id))
        .whereType<Place>()
        .toList();
    final durationDays = _daysBetween(trip.startDate, trip.endDate);
    final durationText = durationDays > 1
        ? AppLocalizations.of(context)!.daysCount(durationDays)
        : AppLocalizations.of(context)!.flexibleDays;
    final phase = tripPhase(trip, DateTime.now());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: _tripsPanelDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            trip.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppTheme.textPrimary,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: _TripPhaseChip(phase: phase),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: _TripDatePill(trip: trip),
                          ),
                        ),
                      ],
                    ),
                    if (trip.description != null &&
                        trip.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        trip.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.clock,
                          size: 12,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          durationText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '·',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textTertiary.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const Icon(
                          FontAwesomeIcons.locationDot,
                          size: 12,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            placeIds.length == 1
                                ? AppLocalizations.of(context)!
                                    .placeCount(placeIds.length)
                                : AppLocalizations.of(context)!
                                    .placesCount(placeIds.length),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (places.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.noPlacesYet,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          )
                        else
                          ...places.take(3).map(
                                (p) => Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 220,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                        if (places.length > 3)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .moreCount(places.length - 3),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TripCardActionButton(
                    icon: FontAwesomeIcons.pen,
                    foreground: AppTheme.textPrimary,
                    onPressed: onEdit,
                  ),
                  const SizedBox(height: 8),
                  _TripCardActionButton(
                    icon: FontAwesomeIcons.trash,
                    foreground: AppTheme.textSecondary,
                    onPressed: onDelete,
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
