import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_image.dart';
import '../models/tour.dart';
import '../models/place.dart';
import '../providers/tours_provider.dart';
import '../providers/places_provider.dart';
import '../providers/map_provider.dart';
import '../providers/trips_provider.dart';
import '../theme/app_theme.dart';
import '../utils/map_launcher.dart';
import '../services/api_service.dart';
import '../widgets/audio_guide_player.dart';
import '../widgets/tts_listen_button.dart';
import '../utils/responsive_utils.dart';
import '../widgets/route_origin_picker.dart';
import '../map/embedded_maps.dart';
import '../map/place_coordinates.dart';

class TourDetailScreen extends StatefulWidget {
  final String tourId;

  const TourDetailScreen({super.key, required this.tourId});

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _shareTour(Tour tour) async {
    final text =
        '${tour.name} - ${tour.duration}\n${tour.priceDisplay}\n\nCheck out this tour in Visit Tripoli';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tour info copied to clipboard')),
      );
    }
  }

  Future<void> _showDirectionsPicker(
      BuildContext context, Tour tour, Place? firstPlace) async {
    if (firstPlace == null || !firstPlace.hasMapCoordinates) return;
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);

    if (mapProvider.currentPosition == null) {
      await mapProvider.getCurrentLocation();
    }
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
          destinationName: tour.name,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );

    if (result == null || !context.mounted) return;

    final validPlaces = placesWithCoordinates(
      tour.placeIds.map((id) => placesProvider.getPlaceById(id)).whereType<Place>(),
    );
    if (validPlaces.isEmpty) return;

    final travelMode = result.travelMode == MapLauncher.transit
        ? MapLauncher.walking
        : result.travelMode;

    final pick = result.chooseStartOnMap ? '&pickStartOnMap=1' : '';
    if (validPlaces.length == 1) {
      context.push(
        '/map?placeId=${validPlaces.first.id}&travelMode=$travelMode$pick',
      );
    } else {
      final ids = validPlaces.map((p) => p.id).join(',');
      context.push(
        '/map?tourPlaces=$ids&travelMode=$travelMode$pick',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final toursProvider = Provider.of<ToursProvider>(context);
    final tour = toursProvider.getTourById(widget.tourId);
    final placesProvider = Provider.of<PlacesProvider>(context);
    final firstPlace = tour?.placeIds.isNotEmpty == true
        ? placesProvider.getPlaceById(tour!.placeIds.first)
        : null;

    if (tour == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tour Not Found')),
        body: const Center(child: Text('Tour not found')),
      );
    }

    final isSaved = toursProvider.isTourSaved(widget.tourId);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: ResponsiveUtils.heroHeight(context),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Tour Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 22),
                onPressed: () => _shareTour(tour),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    src: tour.image,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[300]),
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.grey[300]),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 56,
                    left: ResponsiveUtils.contentPadding(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: tour.badgeColor != null
                            ? _parseColor(tour.badgeColor!)
                            : AppTheme.primaryColor,
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
                        tour.badge ?? 'Tour',
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppTheme.warningColor, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            tour.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${tour.reviews})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
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
          SliverPersistentHeader(
            pinned: true,
            delegate: _TourTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Map'),
                  Tab(text: 'Itinerary'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _TourOverviewTab(
              tour: tour,
              isSaved: isSaved,
              onShare: _shareTour,
              onDirections: (ctx) =>
                  _showDirectionsPicker(ctx, tour, firstPlace),
              onAddToTrip: _showAddToTripDialog,
              onViewMap: () {
                final ids = tour.placeIds.join(',');
                context.push('/map?tourOnly=true&placeIds=$ids');
              },
            ),
            _TourMapTab(
              tour: tour,
              firstPlace: firstPlace,
              onDirections: (ctx) =>
                  _showDirectionsPicker(ctx, tour, firstPlace),
            ),
            _TourItineraryTab(tour: tour),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  void _showAddToTripDialog(BuildContext context, Tour tour) {
    if (tour.placeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This tour has no places')),
      );
      return;
    }
    final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    final firstPlace = placesProvider.getPlaceById(tour.placeIds.first);
    if (firstPlace == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Tour to Trip'),
        content: tripsProvider.trips.isEmpty
            ? const Text('No trips available. Create a new trip first.')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'The first stop of this tour will be added to your trip.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ...tripsProvider.trips.map(
                      (trip) => ListTile(
                        title: Text(trip.name),
                        subtitle: Text(
                          '${trip.startDate.day}/${trip.startDate.month}/${trip.startDate.year}',
                        ),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          final dateStr = trip.days.isNotEmpty
                              ? trip.days.first.date
                              : '${trip.startDate.year}-${trip.startDate.month.toString().padLeft(2, '0')}-${trip.startDate.day.toString().padLeft(2, '0')}';
                          await tripsProvider.addPlaceToTrip(
                              trip.id, firstPlace.id, dateStr);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Tour start added to trip')),
                            );
                          }
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Create New Trip'),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        context.push('/trips');
                      },
                    ),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _TourTabBarDelegate extends SliverPersistentHeaderDelegate {
  _TourTabBarDelegate(this.tabBar);

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
  bool shouldRebuild(_TourTabBarDelegate oldDelegate) => false;
}

class _TourOverviewTab extends StatelessWidget {
  final Tour tour;
  final bool isSaved;
  final void Function(Tour) onShare;
  final void Function(BuildContext) onDirections;
  final void Function(BuildContext, Tour) onAddToTrip;
  final VoidCallback onViewMap;

  const _TourOverviewTab({
    required this.tour,
    required this.isSaved,
    required this.onShare,
    required this.onDirections,
    required this.onAddToTrip,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    final toursProvider = Provider.of<ToursProvider>(context);
    final similarTours =
        toursProvider.tours.where((t) => t.id != tour.id).take(6).toList();

    final pad = ResponsiveUtils.contentPadding(context);
    final vertPad = ResponsiveUtils.detailVerticalPadding(context);
    final maxW = ResponsiveUtils.contentMaxWidth(context);
    final gap = ResponsiveUtils.sectionGap(context);
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
                tour.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Subtitle: duration & price
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      tour.duration,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: gap * 0.66),
                  Flexible(
                    child: Text(
                      tour.priceDisplay,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap),
              // Quick stats pills
              Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TourQuickStatPill(
                icon: Icons.star_rounded,
                label: tour.rating.toStringAsFixed(1),
                color: AppTheme.accentColor,
              ),
              _TourQuickStatPill(
                icon: Icons.timer_outlined,
                label: tour.duration,
                color: AppTheme.primaryColor,
              ),
              _TourQuickStatPill(
                icon: Icons.paid_outlined,
                label: tour.priceDisplay,
                color: AppTheme.primaryColor,
              ),
              _TourQuickStatPill(
                icon: Icons.place_outlined,
                label: '${tour.locations} stops',
                color: AppTheme.primaryColor,
              ),
              _TourQuickStatPill(
                icon: Icons.terrain_outlined,
                label: tour.difficulty,
                color: AppTheme.primaryColor,
                maxWidth: 140,
              ),
            ],
          ),
              SizedBox(height: gap),
              // Stats grid
              _TourStatsGrid(tour: tour),
              _TourAudioGuidesSection(tourId: tour.id),
              SizedBox(height: gap * 1.16),
              // Description
              const _TourSectionHeader(
                  icon: Icons.article_outlined, title: 'About'),
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
              tour.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
          if (tour.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            TtsListenButton(text: tour.description, label: 'Listen to tour'),
          ],
          // Highlights
          if (tour.highlights.isNotEmpty) ...[
            const SizedBox(height: 28),
            const _TourSectionHeader(
                icon: Icons.star_outline_rounded, title: 'Highlights'),
            const SizedBox(height: 12),
            ...tour.highlights.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TourTipCard(tip: h),
              ),
            ),
          ],
          // What's Included
          if (tour.includes.isNotEmpty) ...[
            const SizedBox(height: 28),
            const _TourSectionHeader(
                icon: Icons.check_circle_outline_rounded,
                title: "What's Included"),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tour.includes
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.successColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check,
                              size: 16, color: AppTheme.successColor),
                          const SizedBox(width: 6),
                          Text(
                            s,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          // Not Included
          if (tour.excludes.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _TourSectionHeader(
                icon: Icons.cancel_outlined, title: 'Not Included'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tour.excludes
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            s,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          // Similar tours
          if (similarTours.isNotEmpty) ...[
            const SizedBox(height: 28),
            const _TourSectionHeader(
              icon: Icons.explore_outlined,
              title: 'Similar Tours',
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: ResponsiveUtils.similarListHeight(context, base: 140),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: similarTours.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) {
                  final t = similarTours[i];
                  return _SimilarTourCard(
                    tour: t,
                    onTap: () => context.push('/tour/${t.id}'),
                  );
                },
              ),
            ),
          ],
          // Visitor tips
          const SizedBox(height: 28),
          const _TourSectionHeader(
              icon: Icons.lightbulb_outline_rounded, title: 'Visitor Tips'),
          const SizedBox(height: 12),
          ..._visitorTips(tour).map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TourTipCard(tip: tip),
            ),
          ),
          // Primary actions
          const SizedBox(height: 28),
          _TourPrimaryActions(
            tour: tour,
            isSaved: isSaved,
            onDirections: () => onDirections(context),
            onAddToTrip: () => onAddToTrip(context, tour),
            onViewMap: onViewMap,
            hasPlaces: tour.placeIds.isNotEmpty,
          ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _visitorTips(Tour tour) {
    final tips = <String>[];
    tips.add('Tour duration: ${tour.duration} - plan your day accordingly.');
    tips.add('Difficulty level: ${tour.difficulty}.');
    tips.add(
        'Includes ${tour.locations} stops - check the Itinerary tab for the full schedule.');
    tips.add('Price: ${tour.priceDisplay}.');
    tips.add('Wear comfortable shoes and bring water.');
    return tips;
  }
}

class _TourQuickStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double? maxWidth;

  const _TourQuickStatPill({
    required this.icon,
    required this.label,
    required this.color,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: content,
      );
    }
    return content;
  }
}

class _TourSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _TourSectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
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

class _TourTipCard extends StatelessWidget {
  final String tip;

  const _TourTipCard({required this.tip});

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

class _TourAudioGuidesSection extends StatefulWidget {
  final String tourId;

  const _TourAudioGuidesSection({required this.tourId});

  @override
  State<_TourAudioGuidesSection> createState() => _TourAudioGuidesSectionState();
}

class _TourAudioGuidesSectionState extends State<_TourAudioGuidesSection> {
  List<dynamic> _guides = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    ApiService.instance.getAudioGuides(tourId: widget.tourId).then((list) {
      if (mounted) setState(() { _guides = list; _loaded = true; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _guides.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const Row(
          children: [
            Icon(Icons.headphones_rounded, size: 20, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Text('Audio Guide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        ..._guides.map<Widget>((g) {
          final url = g['audio_url'] as String? ?? '';
          final title = g['title'] as String? ?? 'Audio (${g['language'] ?? 'en'})';
          final dur = g['duration_seconds'] as int?;
          final durStr = dur != null ? '${dur ~/ 60}:${(dur % 60).toString().padLeft(2, '0')}' : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AudioGuidePlayer(url: url, title: title, durationLabel: durStr),
          );
        }),
      ],
    );
  }
}

class _TourStatsGrid extends StatelessWidget {
  final Tour tour;

  const _TourStatsGrid({required this.tour});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _TourStatCard(
          icon: Icons.schedule_outlined,
          label: 'Duration',
          value: tour.duration,
        ),
        _TourStatCard(
          icon: Icons.paid_outlined,
          label: 'Price',
          value: tour.priceDisplay,
        ),
        _TourStatCard(
          icon: Icons.place_outlined,
          label: 'Locations',
          value: '${tour.locations} stops',
        ),
        _TourStatCard(
          icon: Icons.terrain_outlined,
          label: 'Difficulty',
          value: tour.difficulty,
        ),
      ],
    );
  }
}

class _TourStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TourStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveUtils.cardPadding(context);
    final isSmall = ResponsiveUtils.isSmallPhone(context);
    final iconSize = isSmall ? 20.0 : 22.0;
    final valueSize = isSmall ? 13.0 : 14.0;
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: AppTheme.primaryColor),
          SizedBox(height: isSmall ? 6 : 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: ResponsiveUtils.isVerySmallPhone(context) ? 11 : 12,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: valueSize),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SimilarTourCard extends StatelessWidget {
  final Tour tour;
  final VoidCallback onTap;

  const _SimilarTourCard({required this.tour, required this.onTap});

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
                child: AppImage(
                  src: tour.image,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[300]),
                  errorWidget: (_, __, ___) =>
                      Container(color: Colors.grey[300]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tour.name,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${tour.duration} • ${tour.priceDisplay}',
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

class _TourPrimaryActions extends StatelessWidget {
  final Tour tour;
  final bool isSaved;
  final VoidCallback onDirections;
  final VoidCallback onAddToTrip;
  final VoidCallback onViewMap;
  final bool hasPlaces;

  const _TourPrimaryActions({
    required this.tour,
    required this.isSaved,
    required this.onDirections,
    required this.onAddToTrip,
    required this.onViewMap,
    required this.hasPlaces,
  });

  @override
  Widget build(BuildContext context) {
    final toursProvider = Provider.of<ToursProvider>(context);
    final gap = ResponsiveUtils.actionButtonGap(context);
    final pad = ResponsiveUtils.actionButtonPadding(context);
    final small = ResponsiveUtils.isSmallPhone(context);
    final btnFontSize = ResponsiveUtils.actionButtonFontSize(context);
    final iconSize = small ? 18.0 : 20.0;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => toursProvider.toggleSaveTour(tour),
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              size: iconSize,
              color: isSaved ? Colors.red : null,
            ),
            label: Text(isSaved ? 'Saved' : 'Save', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: btnFontSize)),
            style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: pad)),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: FilledButton.icon(
            onPressed: hasPlaces ? onViewMap : null,
            icon: Icon(Icons.map, size: iconSize),
            label: Text('View Map', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: btnFontSize)),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: EdgeInsets.symmetric(vertical: pad),
            ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasPlaces ? onAddToTrip : null,
            icon: Icon(Icons.add, size: iconSize),
            label: Text('Add to Trip', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: btnFontSize)),
            style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: pad)),
          ),
        ),
      ],
    );
  }
}

class _TourStopCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TourStopCard({
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

class _TourMapTab extends StatelessWidget {
  final Tour tour;
  final Place? firstPlace;
  final void Function(BuildContext) onDirections;

  const _TourMapTab({
    required this.tour,
    required this.firstPlace,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PlacesProvider>(context);
    final placesWithCoords = placesWithCoordinates(
      tour.placeIds.map((id) => placesProvider.getPlaceById(id)).whereType<Place>(),
    );

    if (placesWithCoords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No map data for this tour',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
                child: EmbeddedMapDefaults.multiStopRoute(
                  placesWithCoords: placesWithCoords,
                ),
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onDirections(context),
                      icon: Icon(Icons.directions, size: ResponsiveUtils.isSmallPhone(context) ? 18 : 20),
                      label: const Text('Directions', maxLines: 1, overflow: TextOverflow.ellipsis),
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
                        context.push(
                            '/map?tourOnly=true&placeIds=${tour.placeIds.join(",")}');
                      },
                      icon: Icon(Icons.fullscreen, size: ResponsiveUtils.isSmallPhone(context) ? 18 : 20),
                      label: const Text('Full Map', maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.actionButtonPadding(context)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap * 0.83),
              Text('Tour Stops', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...placesWithCoords.asMap().entries.map((e) {
                final idx = e.key + 1;
                final p = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TourStopCard(
                    icon: FontAwesomeIcons.locationDot,
                    title: '$idx. ${p.name}',
                    description: p.location,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourItineraryTab extends StatelessWidget {
  final Tour tour;

  const _TourItineraryTab({required this.tour});

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveUtils.contentPadding(context);
    final vertPad = ResponsiveUtils.detailVerticalPadding(context);
    return ListView.builder(
      padding: EdgeInsetsDirectional.fromSTEB(
          pad, vertPad, pad, 32 + MediaQuery.of(context).padding.bottom),
      itemCount: tour.itinerary.length,
      itemBuilder: (context, index) {
        final item = tour.itinerary[index];
        final isLast = index == tour.itinerary.length - 1;
        return _ItineraryItemCard(
          time: item.time,
          activity: item.activity,
          description: item.description,
          isLast: isLast,
        );
      },
    );
  }
}

class _ItineraryItemCard extends StatelessWidget {
  final String time;
  final String activity;
  final String description;
  final bool isLast;

  const _ItineraryItemCard({
    required this.time,
    required this.activity,
    required this.description,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    time.split(' ').first,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppTheme.borderColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
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
          ),
        ],
      ),
    );
  }
}
