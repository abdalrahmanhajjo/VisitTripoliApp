import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../providers/app_tour_segment.dart';
import '../providers/auth_provider.dart';
import '../providers/trips_provider.dart';
import '../models/trip.dart';
import '../services/api_service.dart';
import '../utils/app_tour_showcase.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/themed_showcase.dart';
import '../widgets/app_profile_icon_button.dart';
import '../theme/app_theme.dart';
import '../utils/app_share.dart';
import '../utils/responsive_utils.dart';
import 'trips/trip_details_modal.dart';
import 'trips/trip_form_modal.dart';
import 'trips/trip_route_map.dart';
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
    borderRadius: BorderRadius.circular(16),
    boxShadow: AppTheme.premiumCardShadow,
  );
}

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  static final GlobalKey tutorialHeaderKey = GlobalKey();
  static final GlobalKey tutorialNewTripKey = GlobalKey();
  static final GlobalKey tutorialCalendarKey = GlobalKey();

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  bool _tripsTourKickoff = false;
  DateTime _calendarMonth = DateTime.now();
  DateTime? _selectedDate;
  bool _calendarVisible = false;
  TripSortMode _tripSortMode = TripSortMode.smart;
  final TextEditingController _tripFilterController = TextEditingController();
  /// When false, trips whose [TripPhase] is past are omitted from the list.
  bool _showPastTrips = false;
  List<Map<String, dynamic>> _incomingShareRequests = const [];
  final Set<String> _respondingShareRequestIds = <String>{};
  final Set<String> _previewingShareRequestIds = <String>{};
  final Map<String, List<Map<String, dynamic>>> _tripMembersCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<TripsProvider>(context, listen: false).loadTrips();
      _loadShareRequests();
      unawaited(_maybeRunSpotlightTour());
    });
  }

  Future<void> _maybeRunSpotlightTour() async {
    if (_tripsTourKickoff || !mounted) return;
    final appState = context.read<AppStateProvider>();
    if (!appState.isFullAppTourActive ||
        appState.activeTourSegment != AppTourSegment.trips) {
      return;
    }
    _tripsTourKickoff = true;
    await Future.delayed(const Duration(milliseconds: 560));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    startAppTourShowcase(
      context: context,
      prefs: prefs,
      keys: [
        AppBottomNav.tripsKey,
        TripsScreen.tutorialHeaderKey,
        TripsScreen.tutorialNewTripKey,
        TripsScreen.tutorialCalendarKey,
      ],
      advanceFromSegment: AppTourSegment.trips,
    );
  }

  Future<void> _loadShareRequests() async {
    final auth = context.read<AuthProvider>();
    final token = auth.authToken;
    if (token == null || token.isEmpty || auth.isGuest) return;
    try {
      final data = await ApiService.instance.getTripShareRequests(token);
      if (!mounted) return;
      setState(() {
        _incomingShareRequests = ((data['incoming'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (_) {}
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
    final auth = Provider.of<AuthProvider>(context);
    final tripsProvider = Provider.of<TripsProvider>(context);
    final trips = tripsProvider.trips;
    final filteredForStats = _filteredTripsForList(tripsProvider);
    final visibleTrips = _getVisibleTrips(tripsProvider);
    final showCollaborationRequestsCard = _incomingShareRequests.any((r) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      return status == 'pending';
    });
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
                    ThemedShowcase(
                      showcaseKey: TripsScreen.tutorialCalendarKey,
                      title: AppLocalizations.of(context)!
                          .appTutorialTripsCalendarTitle,
                      description: AppLocalizations.of(context)!
                          .appTutorialTripsCalendarBody,
                      child: _TripsCalendarToggle(
                        isExpanded: _calendarVisible,
                        calendarMonth: _calendarMonth,
                        selectedDate: _selectedDate,
                        onToggle: () => setState(
                            () => _calendarVisible = !_calendarVisible),
                      ),
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
                    if (auth.isLoggedIn &&
                        !auth.isGuest &&
                        showCollaborationRequestsCard)
                      _TripShareRequestsCard(
                        requests: _incomingShareRequests,
                        respondingIds: _respondingShareRequestIds,
                        previewingIds: _previewingShareRequestIds,
                        onViewTrip: _openRequestTripPreview,
                        onRespond: (id, action) async {
                          final token = context.read<AuthProvider>().authToken;
                          final tripsProvider = context.read<TripsProvider>();
                          if (token == null || token.isEmpty) return;
                          if (_respondingShareRequestIds.contains(id)) return;
                          setState(() => _respondingShareRequestIds.add(id));
                          try {
                            await ApiService.instance
                                .respondTripShareRequest(token, id, action);
                            await _loadShareRequests();
                            if (action.toLowerCase() == 'accept' && mounted) {
                              await tripsProvider.loadTrips(forceRefresh: true);
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to respond: ${e.toString()}'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _respondingShareRequestIds.remove(id));
                            }
                          }
                        },
                      ),
                    if (auth.isLoggedIn &&
                        !auth.isGuest &&
                        showCollaborationRequestsCard)
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
                              canManageTrip:
                                  t.isHost || (t.hostUserId == auth.userId),
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

  Future<void> _openTripDetails(BuildContext context, Trip trip) async {
    final auth = context.read<AuthProvider>();
    final tripsProvider = context.read<TripsProvider>();
    final canManageTrip = trip.isHost || (trip.hostUserId == auth.userId);
    List<Map<String, dynamic>> tripMembers =
        _tripMembersCache[trip.id] ?? const <Map<String, dynamic>>[];
    final token = auth.authToken;
    if (token != null && token.isNotEmpty) {
      try {
        final fetched = await ApiService.instance.getTripMembers(token, trip.id);
        if (mounted) {
          _tripMembersCache[trip.id] = fetched;
          tripMembers = fetched;
        }
      } catch (_) {
        // Keep opening details even if members endpoint fails.
      }
    }
    if (!mounted || !context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TripDetailsModal(
        trip: trip,
        placeIds: tripsProvider.getPlaceIdsForTrip(trip),
        tripMembers: tripMembers,
        canManageTrip: canManageTrip,
        onEdit: () {
          if (!canManageTrip) return;
          Navigator.pop(ctx);
          _openEditTripModal(context, trip);
        },
        onInvite: canManageTrip ? () => _inviteToTrip(ctx, trip) : null,
        onShare: () => _shareTrip(ctx, trip),
        onOpenMap: () {
          Navigator.pop(ctx);
          if (!context.mounted) return;
          openTripRouteOnMap(context, trip);
        },
        onOpenPlace: (placeId) => context.push('/place/$placeId'),
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

  Future<void> _inviteToTrip(BuildContext context, Trip trip) async {
    final auth = context.read<AuthProvider>();
    final token = auth.authToken;
    if (token == null || token.isEmpty || auth.isGuest) {
      context.go('/login?redirect=${Uri.encodeComponent('/trips')}');
      return;
    }
    final canManageTrip = trip.isHost || (trip.hostUserId == auth.userId);
    if (!canManageTrip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only trip host can invite collaborators.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final users = await ApiService.instance.getTripShareUsers(token);
      if (!context.mounted) return;
      final candidates = users
          .where((u) => (u['id']?.toString() ?? '') != (auth.userId ?? ''))
          .toList(growable: false);
      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No users available to invite.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      String query = '';
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) {
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              final filtered = candidates.where((u) {
                final name = (u['name'] ?? '').toString().toLowerCase();
                final email = (u['email'] ?? '').toString().toLowerCase();
                final q = query.toLowerCase().trim();
                if (q.isEmpty) return true;
                return name.contains(q) || email.contains(q);
              }).toList(growable: false);
              return SafeArea(
                top: false,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search user by name or email',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                          onChanged: (v) => setModalState(() => query = v),
                        ),
                      ),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: AppTheme.borderColor.withValues(alpha: 0.5)),
                          itemBuilder: (_, i) {
                            final u = filtered[i];
                            final id = (u['id'] ?? '').toString();
                            final name = (u['name'] ?? 'Traveler').toString();
                            final email = (u['email'] ?? '').toString();
                            return ListTile(
                              leading: const Icon(Icons.person_outline_rounded),
                              title: Text(name),
                              subtitle: email.isEmpty ? null : Text(email),
                              trailing: FilledButton(
                                onPressed: () async {
                                  try {
                                    await ApiService.instance.createTripShareRequest(
                                      token,
                                      tripId: trip.id,
                                      toUserId: id,
                                    );
                                    if (!ctx.mounted) return;
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Invite sent to $name'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!ctx.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to invite: ${e.toString()}'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Invite'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load users: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openRequestTripPreview(String requestId) async {
    final auth = context.read<AuthProvider>();
    final token = auth.authToken;
    if (token == null || token.isEmpty || auth.isGuest) return;
    if (_previewingShareRequestIds.contains(requestId)) return;
    setState(() => _previewingShareRequestIds.add(requestId));
    try {
      final data =
          await ApiService.instance.getTripShareRequestTrip(token, requestId);
      if (!mounted) return;
      final trip = Trip.fromJson(data);
      final placeIds = context.read<TripsProvider>().getPlaceIdsForTrip(trip);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => TripDetailsModal(
          trip: trip,
          placeIds: placeIds,
          tripMembers: const <Map<String, dynamic>>[],
          canManageTrip: false,
          onInvite: null,
          onEdit: () {},
          onShare: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Accept request first to collaborate on this trip.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          onOpenMap: () {
            Navigator.pop(ctx);
            if (!context.mounted) return;
            openTripRouteOnMap(context, trip);
          },
          onOpenPlace: (placeId) => context.push('/place/$placeId'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load trip details: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _previewingShareRequestIds.remove(requestId));
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
              child: ThemedShowcase(
                showcaseKey: TripsScreen.tutorialHeaderKey,
                title: AppLocalizations.of(context)!.appTutorialTripsHeaderTitle,
                description:
                    AppLocalizations.of(context)!.appTutorialTripsHeaderBody,
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
            ),
            const SizedBox(width: 8),
            const AppProfileIconButton(iconColor: Colors.white, iconSize: 22),
            const SizedBox(width: 8),
            ThemedShowcase(
              showcaseKey: TripsScreen.tutorialNewTripKey,
              title: AppLocalizations.of(context)!.appTutorialTripsNewTripTitle,
              description:
                  AppLocalizations.of(context)!.appTutorialTripsNewTripBody,
              child: Material(
                color: AppTheme.surfaceColor,
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

class _TripShareRequestsCard extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final Set<String> respondingIds;
  final Set<String> previewingIds;
  final Future<void> Function(String id) onViewTrip;
  final Future<void> Function(String id, String action) onRespond;

  const _TripShareRequestsCard({
    required this.requests,
    required this.respondingIds,
    required this.previewingIds,
    required this.onViewTrip,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final pending = requests.where((r) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      return status == 'pending';
    }).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _tripsPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collaboration requests',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (pending.isEmpty)
            const Text(
              'No pending requests.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ...pending.take(10).map((r) {
            final id = (r['id'] ?? '').toString();
            final from = (r['from_name'] ?? r['from_user_name'] ?? 'Traveler').toString();
            final tripName = (r['trip_name'] ?? 'Trip').toString();
            final isBusy = respondingIds.contains(id);
            final isPreviewing = previewingIds.contains(id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$from invited you to collaborate on "$tripName"',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: (isBusy || isPreviewing)
                        ? null
                        : () => onViewTrip(id),
                    child: isPreviewing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('View trip'),
                  ),
                  TextButton(
                    onPressed: isBusy ? null : () => onRespond(id, 'reject'),
                    child: const Text('Decline'),
                  ),
                  FilledButton(
                    onPressed: isBusy ? null : () => onRespond(id, 'accept'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Accept'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TripSortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TripSortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primaryColor
                  : AppTheme.surfaceVariant.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
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
              _TripSortChip(
                label: l10n.tripsSortSmart,
                selected: sortMode == TripSortMode.smart,
                onTap: () => onSortChanged(TripSortMode.smart),
              ),
              _TripSortChip(
                label: l10n.tripsSortStartDate,
                selected: sortMode == TripSortMode.startSoonest,
                onTap: () => onSortChanged(TripSortMode.startSoonest),
              ),
              _TripSortChip(
                label: l10n.tripsSortRecent,
                selected: sortMode == TripSortMode.recentlyCreated,
                onTap: () => onSortChanged(TripSortMode.recentlyCreated),
              ),
              _TripSortChip(
                label: l10n.tripsSortName,
                selected: sortMode == TripSortMode.nameAtoZ,
                onTap: () => onSortChanged(TripSortMode.nameAtoZ),
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
        color: AppTheme.surfaceColor,
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
        color: AppTheme.surfaceColor,
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
        color: AppTheme.surfaceColor,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            FontAwesomeIcons.calendar,
            size: 11,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            _formatTripDateRange(trip),
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
  final bool canManageTrip;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TripCard({
    required this.trip,
    required this.placeIds,
    required this.canManageTrip,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final narrowCard = MediaQuery.sizeOf(context).width < 360;
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
                    Text(
                      trip.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppTheme.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _TripPhaseChip(phase: phase),
                        if (trip.isHost)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium_rounded,
                                    size: 12, color: AppTheme.primaryColor),
                                SizedBox(width: 4),
                                Text(
                                  'HOST',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Shared${(trip.hostName != null && trip.hostName!.trim().isNotEmpty) ? " by ${trip.hostName}" : ""}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        _TripDatePill(trip: trip),
                      ],
                    ),
                    if (!narrowCard &&
                        trip.description != null &&
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
                  ],
                ),
              ),
              if (canManageTrip) ...[
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
            ],
          ),
        ),
      ),
    );
  }
}
