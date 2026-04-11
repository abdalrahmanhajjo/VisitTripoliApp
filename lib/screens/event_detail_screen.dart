import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../widgets/app_image.dart';
import '../utils/trip_slot_validation.dart';
import '../widgets/detail_hero_image.dart';
import '../widgets/detail_key_info_chip.dart';
import '../models/event.dart';
import '../models/place.dart';
import '../providers/events_provider.dart';
import '../providers/places_provider.dart';
import '../providers/map_provider.dart';
import '../providers/trips_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/route_origin_picker.dart';
import '../map/embedded_maps.dart';
import '../map/place_coordinates.dart';
import 'package:url_launcher/url_launcher.dart';

String _eventDetailDatePill(DateTime start, DateTime end) {
  if (start.year == end.year &&
      start.month == end.month &&
      start.day == end.day) {
    return DateFormat('MMM d, y').format(start);
  }
  return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, y').format(end)}';
}

String _eventDetailTimePill(DateTime start, DateTime end) {
  return '${DateFormat('jm').format(start)} – ${DateFormat('jm').format(end)}';
}

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _shareEvent(Event event) async {
    final text =
        '${event.name} - ${event.location}\n${DateFormat('MMM d, y').format(event.startDate)}\n\nCheck out this event in Visit Tripoli';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventInfoCopied)),
      );
    }
  }

  Future<void> _showDirectionsPicker(
      BuildContext context, Event event, Place? place) async {
    if (place == null || !place.hasMapCoordinates) {
      return;
    }
    final mapProvider = Provider.of<MapProvider>(context, listen: false);

    final myCoords = mapProvider.currentPosition != null
        ? (
            mapProvider.currentPosition!.latitude,
            mapProvider.currentPosition!.longitude
          )
        : null;

    if (!context.mounted) return;
    final result = await showModalBottomSheet<RouteOriginResult?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: RouteOriginPicker(
          myLocationCoords: myCoords,
          destinationName: event.name,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );

    if (result == null || !context.mounted) return;
    if (!place.hasMapCoordinates) return;

    final pick = result.chooseStartOnMap ? '&pickStartOnMap=1' : '';
    context.push(
      '/map?placeId=${place.id}&travelMode=${result.travelMode}$pick',
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsProvider = Provider.of<EventsProvider>(context);
    final event = eventsProvider.getEventById(widget.eventId);
    final placesProvider = Provider.of<PlacesProvider>(context);
    final place = event?.placeId != null
        ? placesProvider.getPlaceById(event!.placeId!)
        : null;

    if (event == null) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.eventNotFoundTitle)),
        body: Center(child: Text(l10n.eventNotFoundBody)),
      );
    }

    final isSaved = eventsProvider.isEventSaved(widget.eventId);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: ResponsiveUtils.detailSliverHeroHeight(context),
            backgroundColor: Colors.black.withValues(alpha: 0.28),
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              l10n.eventDetailsTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 22),
                onPressed: () => _shareEvent(event),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DetailHeroImage(
                    imageUrl: event.image,
                    fallback: const DetailHeroEventFallback(),
                  ),
                  const DetailHeroBottomGradient(),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 56,
                    left: ResponsiveUtils.contentPadding(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        event.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 56,
                    right: ResponsiveUtils.contentPadding(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        event.priceDisplay ?? l10n.free,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _EventTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: l10n.eventOverviewTab),
                  Tab(text: l10n.eventMapTab),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _EventOverviewTab(
              event: event,
              isSaved: isSaved,
              onShare: _shareEvent,
              onDirections: (ctx) => _showDirectionsPicker(ctx, event, place),
              onAddToTrip: _showAddToTripDialog,
              hasPlace: place != null,
            ),
            _EventMapTab(
              event: event,
              place: place,
              onDirections: (ctx) => _showDirectionsPicker(ctx, event, place),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToTripDialog(BuildContext context, Event event) {
    final l10n = AppLocalizations.of(context)!;
    if (event.placeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventNoLinkedVenue)),
      );
      return;
    }
    final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    final place = placesProvider.getPlaceById(event.placeId!);
    if (place == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.eventAddToTripTitle),
        content: tripsProvider.trips.isEmpty
            ? Text(l10n.eventNoTripsCreateFirst)
            : Builder(
                builder: (ctx) {
                  final dateStr =
                      '${event.startDate.year}-${event.startDate.month.toString().padLeft(2, '0')}-${event.startDate.day.toString().padLeft(2, '0')}';
                  final eligible = tripsProvider.trips
                      .where((t) => tripCoversCalendarDate(t, dateStr))
                      .toList();
                  if (eligible.isEmpty) {
                    return Text(l10n.eventNoTripCoversEventDay);
                  }
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.eventAddedOnEventDayOnly,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ...eligible.map(
                          (trip) => ListTile(
                            title: Text(trip.name),
                            subtitle: Text(
                              '${trip.startDate.day}/${trip.startDate.month}/${trip.startDate.year}',
                            ),
                            onTap: () async {
                              Navigator.pop(dialogContext);
                              final err = await tripsProvider.addPlaceToTrip(
                                  trip.id, place.id, dateStr);
                              if (context.mounted) {
                                if (err != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        err == 'overlap'
                                            ? AppLocalizations.of(context)!
                                                .timeConflict
                                            : AppLocalizations.of(context)!
                                                .tripStopDateNotInRange,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .eventVenueAddedToTrip),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: Text(l10n.createNewTripTitle),
                          onTap: () {
                            Navigator.pop(dialogContext);
                            context.push('/trips');
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

class _EventTabBarDelegate extends SliverPersistentHeaderDelegate {
  _EventTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapping) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_EventTabBarDelegate oldDelegate) => false;
}

class _EventOverviewTab extends StatelessWidget {
  final Event event;
  final bool isSaved;
  final void Function(Event) onShare;
  final void Function(BuildContext) onDirections;
  final void Function(BuildContext, Event) onAddToTrip;
  final bool hasPlace;

  const _EventOverviewTab({
    required this.event,
    required this.isSaved,
    required this.onShare,
    required this.onDirections,
    required this.onAddToTrip,
    required this.hasPlace,
  });

  @override
  Widget build(BuildContext context) {
    final eventsProvider = Provider.of<EventsProvider>(context);
    final isLive =
        event.category.trim().toLowerCase() == 'live' ||
        event.location.trim().toLowerCase().startsWith('http');

    final similarEvents = eventsProvider.events
        .where((e) => e.id != event.id && e.category == event.category)
        .take(6)
        .toList();

    final pad = ResponsiveUtils.contentPadding(context);
    final vertPad = ResponsiveUtils.detailVerticalPadding(context);
    final maxW = ResponsiveUtils.contentMaxWidth(context);
    final gap = ResponsiveUtils.sectionGap(context);
    final rowSpacing =
        ResponsiveUtils.isVerySmallPhone(context) ? 10.0 : (ResponsiveUtils.isSmallPhone(context) ? 12.0 : 14.0);
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
          pad, vertPad, pad, 40 + MediaQuery.of(context).padding.bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                event.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (isLive &&
                  event.location.trim().toLowerCase().startsWith('http')) ...[
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(event.location)),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.openLink),
                ),
                SizedBox(height: gap),
              ],
              // Location
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap),
              _EventKeyInfoCard(event: event, rowSpacing: rowSpacing),
              SizedBox(height: gap),
              _EventPrimaryActions(
                event: event,
                isSaved: isSaved,
                onDirections: () => onDirections(context),
                onAddToTrip: () => onAddToTrip(context, event),
                hasPlace: hasPlace,
              ),
              SizedBox(height: gap * 1.16),
              // Description
              _EventSectionHeader(
                  icon: Icons.article_outlined,
                  title: AppLocalizations.of(context)!.about),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                    ResponsiveUtils.isSmallPhone(context) ? 14 : 18),
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
            child: Text(
              event.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
          // Organizer
          if (event.organizer != null) ...[
            const SizedBox(height: 28),
            _ContactInfoCard(
              icon: Icons.business_outlined,
              label: AppLocalizations.of(context)!.eventOrganizerLabel,
              value: event.organizer!,
            ),
          ],
          // Similar events
          if (similarEvents.isNotEmpty) ...[
            const SizedBox(height: 28),
            _EventSectionHeader(
              icon: Icons.explore_outlined,
              title: AppLocalizations.of(context)!.similarEventsSectionTitle,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: ResponsiveUtils.similarListHeight(context, base: 140),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: similarEvents.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) {
                  final e = similarEvents[i];
                  return _SimilarEventCard(
                    event: e,
                    onTap: () => context.push('/event/${e.id}'),
                  );
                },
              ),
            ),
          ],
          // Visitor tips
          const SizedBox(height: 28),
          _EventSectionHeader(
              icon: Icons.lightbulb_outline_rounded,
              title: AppLocalizations.of(context)!.sectionVisitorTips),
          const SizedBox(height: 12),
          ..._visitorTips(event).map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EventTipCard(tip: tip),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _visitorTips(Event event) {
    final tips = <String>[];
    tips.add(
        'Event runs from ${DateFormat('MMM d').format(event.startDate)} to ${DateFormat('MMM d, y').format(event.endDate)}.');
    if (event.priceDisplay != null && event.priceDisplay != 'Free') {
      tips.add('Price: ${event.priceDisplay}');
    }
    if (event.organizer != null) {
      tips.add('Organized by ${event.organizer}');
    }
    tips.add('Arrive early to secure a good spot.');
    return tips;
  }
}

class _EventKeyInfoCard extends StatelessWidget {
  final Event event;
  final double rowSpacing;

  const _EventKeyInfoCard({
    required this.event,
    required this.rowSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveUtils.cardPadding(context) + 2;
    final isVerySmall = ResponsiveUtils.isVerySmallPhone(context);
    final priceFree =
        event.priceDisplay == null || event.priceDisplay == 'Free';

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DetailKeyInfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: _eventDetailDatePill(event.startDate, event.endDate),
                  maxLines: 2,
                ),
              ),
              SizedBox(width: isVerySmall ? 8 : 12),
              Expanded(
                child: DetailKeyInfoChip(
                  icon: Icons.access_time_outlined,
                  label: _eventDetailTimePill(event.startDate, event.endDate),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: rowSpacing),
          Row(
            children: [
              Expanded(
                child: DetailKeyInfoChip(
                  icon: Icons.paid_outlined,
                  label: event.priceDisplay ?? 'Free',
                  isFree: priceFree,
                ),
              ),
              SizedBox(width: isVerySmall ? 8 : 12),
              Expanded(
                child: DetailKeyInfoChip(
                  icon: Icons.category_outlined,
                  label: event.category,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _EventSectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            padding: EdgeInsets.all(ResponsiveUtils.iconBoxPadding(context)),
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
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
        ),
      ],
    );
  }
}

class _EventTipCard extends StatelessWidget {
  final String tip;

  const _EventTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 20,
            color: AppTheme.accentColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimilarEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _SimilarEventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardW = ResponsiveUtils.similarCardWidth(context);
    final imgH = ResponsiveUtils.similarCardImageHeight(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: cardW,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: imgH,
                width: cardW,
                child: event.image != null
                    ? AppImage(
                        src: event.image!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey[300]),
                        errorWidget: (_, __, ___) =>
                            Container(color: Colors.grey[300]),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.event, size: 32),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.name,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              DateFormat('MMM d').format(event.startDate),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventPrimaryActions extends StatelessWidget {
  final Event event;
  final bool isSaved;
  final VoidCallback onDirections;
  final VoidCallback onAddToTrip;
  final bool hasPlace;

  const _EventPrimaryActions({
    required this.event,
    required this.isSaved,
    required this.onDirections,
    required this.onAddToTrip,
    required this.hasPlace,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eventsProvider = Provider.of<EventsProvider>(context);
    final gap = ResponsiveUtils.actionButtonGap(context);
    final pad = ResponsiveUtils.actionButtonPadding(context);
    final small = ResponsiveUtils.isSmallPhone(context);
    final btnFontSize = ResponsiveUtils.actionButtonFontSize(context);
    final iconSize = small ? 18.0 : 20.0;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => eventsProvider.toggleSaveEvent(event),
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              size: iconSize,
              color: isSaved ? AppTheme.primaryColor : null,
            ),
            label: Text(isSaved ? l10n.saved : l10n.save, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: btnFontSize)),
            style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: pad)),
          ),
        ),
        if (hasPlace) ...[
          SizedBox(width: gap),
          Expanded(
            child: FilledButton.icon(
              onPressed: onDirections,
              icon: Icon(Icons.directions, size: iconSize),
              label: Text(l10n.directions, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: btnFontSize)),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: pad),
              ),
            ),
          ),
          SizedBox(width: gap),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasPlace ? onAddToTrip : null,
            icon: Icon(Icons.add, size: iconSize),
            label: Text(l10n.addToTrip, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: btnFontSize)),
            style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: pad)),
          ),
        ),
      ],
    );
  }
}

class _EventMapTab extends StatelessWidget {
  final Event event;
  final Place? place;
  final void Function(BuildContext) onDirections;

  const _EventMapTab({
    required this.event,
    required this.place,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (place == null || !place!.hasMapCoordinates) {
      return Center(
        child: Padding(
          padding: ResponsiveUtils.modalPadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.eventNoMapLocation,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                event.location,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final p = place!;

    final pad = ResponsiveUtils.contentPadding(context);
    final vertPad = ResponsiveUtils.detailVerticalPadding(context);
    final maxW = ResponsiveUtils.contentMaxWidth(context);
    final gap = ResponsiveUtils.sectionGap(context);
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
          pad, vertPad, pad, 32 + MediaQuery.of(context).padding.bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailMapCard(
                height: ResponsiveUtils.mapHeight(context),
                child: EmbeddedMapDefaults.singlePlace(
                  target: p.mapLatLng!,
                  markerId: p.id,
                  infoTitle: event.name,
                ),
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onDirections(context),
                      icon: Icon(Icons.directions, size: ResponsiveUtils.isSmallPhone(context) ? 18 : 20),
                      label: Text(l10n.getDirections, maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.actionButtonPadding(context)),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.actionButtonGap(context)),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/map?placeId=${place!.id}');
                      },
                      icon: Icon(Icons.map_outlined, size: ResponsiveUtils.isSmallPhone(context) ? 18 : 20),
                      label: Text(l10n.viewOnMap, maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.actionButtonPadding(context)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap * 0.83),
              Text(l10n.venue, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              _TransportCard(
                icon: FontAwesomeIcons.locationDot,
                title: place!.name,
                description: place!.location,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TransportCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.cardPadding(context)),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.iconBoxPadding(context)),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(icon, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
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
