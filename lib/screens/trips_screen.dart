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
import '../providers/tours_provider.dart';
import '../providers/events_provider.dart';
import '../models/trip.dart';
import '../models/place.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_profile_icon_button.dart';
import '../theme/app_theme.dart';
import '../utils/app_share.dart';
import '../utils/responsive_utils.dart';

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

Widget _modalDragHandle() {
  return Center(
    child: Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.borderColor,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<TripsProvider>(context, listen: false).loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripsProvider = Provider.of<TripsProvider>(context);
    final trips = tripsProvider.trips;
    final visibleTrips = _getVisibleTrips(tripsProvider);
    final totalPlaces = trips.fold<int>(
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
                    _TripsSummary(
                      totalTrips: trips.length,
                      totalPlaces: totalPlaces,
                    ),
                    const SizedBox(height: 12),
                    if (visibleTrips.isEmpty)
                      _TripsEmptyState(
                          onCreate: () => _openCreateTripModal(context))
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

  List<Trip> _getVisibleTrips(TripsProvider provider) {
    var trips = provider.trips;
    trips = List.from(trips)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_selectedDate == null) return trips;
    return trips.where((t) => _tripCoversDate(t, _selectedDate!)).toList();
  }

  bool _tripCoversDate(Trip trip, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s =
        DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
    final e = DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);
    return (d.isAtSameMomentAs(s) || d.isAfter(s)) &&
        (d.isAtSameMomentAs(e) || d.isBefore(e));
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
      builder: (ctx) => _TripDetailsModal(
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
      builder: (ctx) => _TripFormModal(
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _tripsPanelDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trip.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(FontAwesomeIcons.calendar,
                                    size: 10, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _formatTripDateRange(trip),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (trip.description != null &&
                        trip.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        trip.description!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(FontAwesomeIcons.clock,
                            size: 11, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            durationText,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(FontAwesomeIcons.locationDot,
                            size: 11, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            placeIds.length == 1
                                ? AppLocalizations.of(context)!
                                    .placeCount(placeIds.length)
                                : AppLocalizations.of(context)!
                                    .placesCount(placeIds.length),
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (places.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                                AppLocalizations.of(context)!.noPlacesYet,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                          )
                        else
                          ...places.take(3).map((p) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        if (places.length > 3)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .moreCount(places.length - 3),
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(FontAwesomeIcons.pen, size: 14),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      backgroundColor: AppTheme.surfaceVariant,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(FontAwesomeIcons.trash,
                        size: 14, color: AppTheme.textSecondary),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      backgroundColor: AppTheme.surfaceVariant,
                      foregroundColor: AppTheme.textSecondary,
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

class _TripDetailsModal extends StatelessWidget {
  final Trip trip;
  final List<String> placeIds;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onOpenMap;

  const _TripDetailsModal({
    required this.trip,
    required this.placeIds,
    required this.onEdit,
    required this.onShare,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PlacesProvider>(context);
    final tripsProvider = Provider.of<TripsProvider>(context);
    final slots = tripsProvider.getSlotsForTrip(trip);
    final places = placeIds
        .map((id) => placesProvider.getPlaceById(id))
        .whereType<Place>()
        .toList();
    final durationDays = _daysBetween(trip.startDate, trip.endDate);
    final durationText = durationDays > 1
        ? AppLocalizations.of(context)!.daysCount(durationDays)
        : AppLocalizations.of(context)!.flexibleDays;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _modalDragHandle(),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    tooltip: 'Share trip',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      backgroundColor: AppTheme.surfaceVariant,
                      foregroundColor: AppTheme.textPrimary,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(FontAwesomeIcons.pen, size: 14),
                    tooltip: AppLocalizations.of(context)!.editTrip,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      backgroundColor: AppTheme.surfaceVariant,
                      foregroundColor: AppTheme.textPrimary,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: AppLocalizations.of(context)!.close,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      backgroundColor: AppTheme.surfaceVariant,
                      foregroundColor: AppTheme.textPrimary,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: _tripsPanelDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow(AppLocalizations.of(context)!.dates,
                            _formatTripDateRange(trip)),
                        const SizedBox(height: 4),
                        _detailRow(AppLocalizations.of(context)!.duration,
                            durationText),
                        const SizedBox(height: 4),
                        _detailRow(AppLocalizations.of(context)!.places,
                            '${placeIds.length}'),
                        if (trip.description != null &&
                            trip.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            trip.description!,
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: _tripsPanelDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.tripMapRoute,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (trip.days.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  const Icon(FontAwesomeIcons.mapLocationDot,
                                      size: 18, color: AppTheme.borderColor),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .noPlacesAttachedYet,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...trip.days.asMap().entries.expand((dayEntry) {
                            final dayIndex = dayEntry.key;
                            final day = dayEntry.value;
                            final dayDate = DateTime.tryParse(day.date);
                            final dayLabel = dayDate != null
                                ? DateFormat('EEE, MMM d').format(dayDate)
                                : 'Day ${dayIndex + 1}';
                            return [
                              if (dayIndex > 0) const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Day ${dayIndex + 1} · $dayLabel',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              ...day.slots.asMap().entries.map((slotEntry) {
                                final i = slotEntry.key;
                                final slot = slotEntry.value;
                                final p =
                                    placesProvider.getPlaceById(slot.placeId);
                                if (p == null) return const SizedBox.shrink();
                                final isLast = i == day.slots.length - 1;
                                final timeStr = (slot.startTime != null &&
                                        slot.endTime != null)
                                    ? '${slot.startTime} – ${slot.endTime}'
                                    : (slot.startTime != null)
                                        ? 'From ${slot.startTime}'
                                        : (slot.endTime != null)
                                            ? 'Until ${slot.endTime}'
                                            : null;
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (!isLast)
                                          Container(
                                            width: 2,
                                            height: 24,
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.3),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          if (timeStr != null) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(
                                                    FontAwesomeIcons.clock,
                                                    size: 10,
                                                    color:
                                                        AppTheme.primaryColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  timeStr,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppTheme.primaryColor,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(
                                                  FontAwesomeIcons.locationDot,
                                                  size: 10,
                                                  color:
                                                      AppTheme.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(
                                                p.location,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppTheme.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ];
                          }),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onOpenMap,
                            icon: const Icon(FontAwesomeIcons.map, size: 16),
                            label: Text(
                                AppLocalizations.of(context)!.viewRouteOnMap),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: _tripsPanelDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.placesInThisTrip,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (places.isEmpty)
                          Text(
                              AppLocalizations.of(context)!.noPlacesAttachedYet,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary))
                        else
                          ...places.asMap().entries.map((e) {
                            final i = e.key;
                            final p = e.value;
                            final slot = i < slots.length ? slots[i] : null;
                            final timeStr = (slot != null &&
                                    slot.startTime != null &&
                                    slot.endTime != null)
                                ? '${slot.startTime} – ${slot.endTime}'
                                : (slot?.startTime != null)
                                    ? 'From ${slot!.startTime}'
                                    : (slot?.endTime != null)
                                        ? 'Until ${slot!.endTime}'
                                        : null;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (timeStr != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(FontAwesomeIcons.clock,
                                            size: 10,
                                            color: AppTheme.primaryColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(FontAwesomeIcons.locationDot,
                                          size: 10,
                                          color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        p.location,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                  if (p.category.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(FontAwesomeIcons.tag,
                                            size: 10,
                                            color: AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          p.category,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary)),
      ],
    );
  }
}

class _TripFormModal extends StatefulWidget {
  final Trip? trip;
  final DateTime? selectedDate;
  final void Function(String message) onSaved;

  const _TripFormModal({
    this.trip,
    this.selectedDate,
    required this.onSaved,
  });

  @override
  State<_TripFormModal> createState() => _TripFormModalState();
}

class _TripFormModalState extends State<_TripFormModal> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _searchController;
  late DateTime _startDate;
  late DateTime _endDate;
  final List<String> _orderedPlaceIds = [];
  final Map<String, String?> _startTimes = {};
  final Map<String, String?> _endTimes = {};
  String _nameError = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    if (widget.trip != null) {
      _nameController = TextEditingController(text: widget.trip!.name);
      _notesController =
          TextEditingController(text: widget.trip!.description ?? '');
      _startDate = widget.trip!.startDate;
      _endDate = widget.trip!.endDate;
      final slots = Provider.of<TripsProvider>(context, listen: false)
          .getSlotsForTrip(widget.trip!);
      for (final s in slots) {
        _orderedPlaceIds.add(s.placeId);
        _startTimes[s.placeId] = s.startTime;
        _endTimes[s.placeId] = s.endTime;
      }
    } else {
      _nameController = TextEditingController();
      _notesController = TextEditingController();
      final base = widget.selectedDate ?? DateTime.now();
      _startDate = base;
      _endDate = base;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyQuickDates(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      switch (preset) {
        case 'today':
          _startDate = today;
          _endDate = today;
          break;
        case 'weekend':
          final weekday = now.weekday;
          final saturday = today.add(Duration(days: (6 - weekday) % 7));
          _startDate = saturday;
          _endDate = saturday.add(const Duration(days: 1));
          break;
        case 'week':
          _startDate = today;
          _endDate = today.add(const Duration(days: 6));
          break;
      }
    });
  }

  static String _formatDateShort(DateTime d) =>
      DateFormat('EEE, MMM d').format(d);

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PlacesProvider>(context);
    final toursProvider = Provider.of<ToursProvider>(context);
    final eventsProvider = Provider.of<EventsProvider>(context);
    final allPlaces =
        _getAllPlaces(placesProvider, toursProvider, eventsProvider);
    final search = _searchController.text.trim().toLowerCase();
    final filteredPlaces = search.isEmpty
        ? allPlaces
        : allPlaces
            .where((p) =>
                p.name.toLowerCase().contains(search) ||
                p.location.toLowerCase().contains(search))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _modalDragHandle(),
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _buildSection(AppLocalizations.of(context)!.tripName,
                      AppLocalizations.of(context)!.giveTripMemorableName, [
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() => _nameError = ''),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.tripNameHint,
                        errorText: _nameError.isEmpty ? null : _nameError,
                        prefixIcon: const Icon(Icons.edit_note,
                            size: 20, color: AppTheme.textTertiary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _nameError.isNotEmpty
                                  ? Colors.red.shade400
                                  : AppTheme.borderColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(AppLocalizations.of(context)!.when,
                      AppLocalizations.of(context)!.setTravelDates, [
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _chip(AppLocalizations.of(context)!.today,
                          () => _applyQuickDates('today')),
                      _chip(AppLocalizations.of(context)!.thisWeekend,
                          () => _applyQuickDates('weekend')),
                      _chip(AppLocalizations.of(context)!.nextWeek,
                          () => _applyQuickDates('week')),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _dateChip(
                              AppLocalizations.of(context)!.start, _startDate,
                              () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) setState(() => _startDate = d);
                          }),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward,
                              size: 16, color: AppTheme.textTertiary),
                        ),
                        Expanded(
                          child: _dateChip(
                              AppLocalizations.of(context)!.end, _endDate,
                              () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) setState(() => _endDate = d);
                          }),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(AppLocalizations.of(context)!.notesOptional,
                      AppLocalizations.of(context)!.addTripDetails, [
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.notesHint,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildPlacesSection(allPlaces, filteredPlaces, search),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.trip == null
                    ? AppLocalizations.of(context)!.createNewTrip
                    : AppLocalizations.of(context)!.editTripTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.trip == null
                    ? AppLocalizations.of(context)!.addDatesPlaces
                    : AppLocalizations.of(context)!.updateTripDetails,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 22),
            tooltip: AppLocalizations.of(context)!.close,
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              backgroundColor: AppTheme.surfaceVariant,
              foregroundColor: AppTheme.textPrimary,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _dateChip(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  _formatDateShort(date),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(
      BuildContext context, String placeId, bool isStart) async {
    final current = isStart ? _startTimes[placeId] : _endTimes[placeId];
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    if (current != null && current.contains(':')) {
      final parts = current.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 9;
        final m = int.tryParse(parts[1]) ?? 0;
        initial = TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
      }
    } else if (!isStart && _startTimes[placeId] != null) {
      final start = _startTimes[placeId]!;
      if (start.contains(':')) {
        final parts = start.split(':');
        if (parts.length >= 2) {
          final h = (int.tryParse(parts[0]) ?? 9) + 1;
          final m = int.tryParse(parts[1]) ?? 0;
          initial = TimeOfDay(hour: (h > 23 ? 23 : h), minute: m.clamp(0, 59));
        }
      }
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        final str =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          _startTimes[placeId] = str;
        } else {
          _endTimes[placeId] = str;
        }
      });
    }
  }

  /// Arrange 1→n by visit time (earliest first). Places without time go last.
  void _arrangeByTime() {
    if (_orderedPlaceIds.length < 2) return;
    final ordered = List<String>.from(_orderedPlaceIds);
    ordered.sort((a, b) {
      final ta = _startTimes[a];
      final tb = _startTimes[b];
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return ta.compareTo(tb);
    });
    setState(() {
      _orderedPlaceIds.clear();
      _orderedPlaceIds.addAll(ordered);
    });
  }

  /// Parse duration string (e.g. "2 hours", "30 min", "1-2h") to minutes.
  static int _parseDurationMinutes(String? s) {
    if (s == null || s.isEmpty) return 60; // default 1h
    final lower = s.toLowerCase();
    final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(lower);
    final minMatch = RegExp(r'(\d+)\s*m').firstMatch(lower);
    final numMatch = RegExp(r'(\d+)').firstMatch(lower);
    int hours = 0, mins = 0;
    if (hourMatch != null) hours = int.tryParse(hourMatch.group(1) ?? '0') ?? 0;
    if (minMatch != null) mins = int.tryParse(minMatch.group(1) ?? '0') ?? 0;
    if (hours == 0 && mins == 0 && numMatch != null) {
      if (lower.contains('h')) {
        hours = int.tryParse(numMatch.group(1) ?? '0') ?? 0;
      } else {
        mins = int.tryParse(numMatch.group(1) ?? '0') ?? 60;
      }
    }
    if (lower.contains('half') || lower.contains('½')) return 240;
    if (lower.contains('full') || lower.contains('whole')) return 480;
    return hours * 60 + (mins > 0 ? mins : (hours > 0 ? 0 : 60));
  }

  /// Prefer order by location (geographic) and time needed at place (duration).
  void _preferByLocationAndDuration(List<Place> allPlaces) {
    if (_orderedPlaceIds.length < 2) return;
    final placeMap = {for (final p in allPlaces) p.id: p};
    final ordered = List<Place>.from(
        _orderedPlaceIds.map((id) => placeMap[id]).whereType<Place>());
    ordered.sort((a, b) {
      final latA = a.latitude ?? -999;
      final latB = b.latitude ?? -999;
      final lonA = a.longitude ?? -999;
      final lonB = b.longitude ?? -999;
      if ((latA - latB).abs() > 0.001) return latA.compareTo(latB);
      if ((lonA - lonB).abs() > 0.001) return lonA.compareTo(lonB);
      final durA = _parseDurationMinutes(a.duration);
      final durB = _parseDurationMinutes(b.duration);
      return durA.compareTo(durB);
    });
    setState(() {
      _orderedPlaceIds.clear();
      _orderedPlaceIds.addAll(ordered.map((p) => p.id));
    });
  }

  Widget _buildPlacesSection(
      List<Place> allPlaces, List<Place> filteredPlaces, String search) {
    final placesProvider = Provider.of<PlacesProvider>(context);
    return _buildSection(
      AppLocalizations.of(context)!.placesInThisTrip,
      _orderedPlaceIds.isEmpty
          ? AppLocalizations.of(context)!.addPlacesSubtitle
          : AppLocalizations.of(context)!
              .placesCountSubtitle(_orderedPlaceIds.length),
      [
        if (_orderedPlaceIds.isNotEmpty) ...[
          if (_orderedPlaceIds.length >= 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _arrangeByTime(),
                      icon: const Icon(FontAwesomeIcons.clock, size: 12),
                      label: Text(AppLocalizations.of(context)!.arrangeByTime),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _preferByLocationAndDuration(allPlaces),
                      icon: const Icon(FontAwesomeIcons.route, size: 12),
                      label: Text(
                          AppLocalizations.of(context)!.preferByRouteDuration),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ..._orderedPlaceIds.asMap().entries.map((e) {
            final i = e.key;
            final placeId = e.value;
            final p = placesProvider.getPlaceById(placeId);
            if (p == null) return const SizedBox.shrink();
            final start = _startTimes[placeId];
            final end = _endTimes[placeId];
            final timeStr = (start != null && end != null)
                ? '$start – $end'
                : (start != null)
                    ? 'From $start'
                    : (end != null)
                        ? 'Until $end'
                        : AppLocalizations.of(context)!.tapClockToSetTime;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Text(
                    '${i + 1}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _pickTime(context, placeId, true),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(FontAwesomeIcons.clock,
                                    size: 11, color: AppTheme.primaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryColor,
                                      decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _pickTime(context, placeId, true),
                    icon: const Icon(Icons.access_time, size: 18),
                    tooltip: AppLocalizations.of(context)!.setStartTime,
                    style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero),
                  ),
                  IconButton(
                    onPressed: () => _pickTime(context, placeId, false),
                    icon: const Icon(Icons.schedule, size: 18),
                    tooltip: AppLocalizations.of(context)!.setEndTime,
                    style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _orderedPlaceIds.remove(placeId);
                        _startTimes.remove(placeId);
                        _endTimes.remove(placeId);
                      });
                    },
                    icon: const Icon(Icons.remove_circle_outline,
                        size: 20, color: AppTheme.textSecondary),
                    tooltip: AppLocalizations.of(context)!.remove,
                    style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.addMorePlaces,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
        ],
        if (allPlaces.isEmpty)
          _emptyPlacesCard()
        else ...[
          if (allPlaces.length > 5)
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchPlaces,
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppTheme.textTertiary),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          if (allPlaces.length > 5) const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredPlaces.isEmpty ? 1 : filteredPlaces.length,
              itemBuilder: (context, i) {
                if (filteredPlaces.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      search.isEmpty
                          ? AppLocalizations.of(context)!.noPlacesFound
                          : AppLocalizations.of(context)!.noMatchesFor(search),
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  );
                }
                final p = filteredPlaces[i];
                final isSelected = _orderedPlaceIds.contains(p.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _orderedPlaceIds.remove(p.id);
                            _startTimes.remove(p.id);
                            _endTimes.remove(p.id);
                          } else {
                            _orderedPlaceIds.add(p.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                        .withValues(alpha: 0.15)
                                    : AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isSelected
                                    ? Icons.check
                                    : FontAwesomeIcons.mapLocationDot,
                                size: 16,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppTheme.textPrimary
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.location,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (p.rating != null)
                                        Text(
                                          '★ ${p.rating!.toStringAsFixed(1)}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              size: 22,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _emptyPlacesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(FontAwesomeIcons.mapLocationDot,
              size: 32, color: AppTheme.borderColor),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noPlacesYet,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.savePlacesFromExplore,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.go('/explore');
            },
            icon: const Icon(Icons.explore, size: 18),
            label: Text(AppLocalizations.of(context)!.explorePlaces),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _saveTrip,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  widget.trip == null
                      ? AppLocalizations.of(context)!.createTrip
                      : AppLocalizations.of(context)!.saveChanges,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Place> _getAllPlaces(PlacesProvider placesProvider,
      ToursProvider toursProvider, EventsProvider eventsProvider) {
    final seen = <String>{};
    final result = <Place>[];

    for (final p in placesProvider.places) {
      if (seen.add(p.id)) result.add(p);
    }
    for (final p in placesProvider.savedPlaces) {
      if (seen.add(p.id)) result.add(p);
    }
    for (final t in toursProvider.tours) {
      for (final pid in t.placeIds) {
        final p = placesProvider.getPlaceById(pid);
        if (p != null && seen.add(p.id)) result.add(p);
      }
    }
    for (final e in eventsProvider.events) {
      if (e.placeId != null) {
        final p = placesProvider.getPlaceById(e.placeId!);
        if (p != null && seen.add(p.id)) result.add(p);
      }
    }
    return result;
  }

  void _saveTrip() {
    final name = _nameController.text.trim();
    setState(() => _nameError = '');
    if (name.isEmpty) {
      setState(
          () => _nameError = AppLocalizations.of(context)!.pleaseEnterTripName);
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.endDateBeforeStart)),
      );
      return;
    }

    final provider = Provider.of<TripsProvider>(context, listen: false);
    final slots = _orderedPlaceIds
        .map((id) => TripSlot(
              placeId: id,
              startTime: _startTimes[id],
              endTime: _endTimes[id],
            ))
        .toList();
    final days = slots.isEmpty
        ? <TripDay>[]
        : [
            TripDay(
              date: DateFormat('yyyy-MM-dd').format(_startDate),
              slots: slots,
            ),
          ];

    if (widget.trip != null) {
      provider.updateTrip(Trip(
        id: widget.trip!.id,
        name: name,
        startDate: _startDate,
        endDate: _endDate,
        days: days,
        description: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.trip!.createdAt,
      ));
    } else {
      provider.addTrip(Trip(
        id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        startDate: _startDate,
        endDate: _endDate,
        days: days,
        description: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      ));
    }
    widget.onSaved(widget.trip == null
        ? AppLocalizations.of(context)!.tripCreated
        : AppLocalizations.of(context)!.tripUpdated);
  }
}
