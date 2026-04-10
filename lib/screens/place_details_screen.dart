import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
// legacy imports kept for backward compatibility with older builds
// (reviews now load from the backend).
// ignore_for_file: unused_import
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../widgets/app_image.dart';
import '../models/place.dart';
import '../providers/auth_provider.dart';
import '../providers/places_provider.dart';
import '../providers/map_provider.dart';
import '../providers/trips_provider.dart';
import '../providers/activity_log_provider.dart';
import '../services/api_service.dart';
import '../utils/feedback_utils.dart';
import '../utils/snackbar_utils.dart';
import '../theme/app_theme.dart';
import '../utils/map_launcher.dart';
import '../widgets/audio_guide_player.dart';
import '../widgets/tts_listen_button.dart';
import '../utils/responsive_utils.dart';
import '../widgets/route_origin_picker.dart';
import '../map/embedded_maps.dart';
import '../map/place_coordinates.dart';
import 'checkin_scan_screen.dart';
import '../utils/checkin_qr.dart';
import 'package:tripoli_explorer/l10n/app_localizations.dart';

// Legacy keys kept for backwards compatibility with older app versions.
// New versions load reviews from the backend instead of local storage.
// ignore: unused_element
const _reviewsKeyPrefix = 'place_reviews_';
// ignore: unused_element
const _placeRatingsKeyPrefix = 'place_ratings_';

class PlaceDetailsScreen extends StatefulWidget {
  final String placeId;

  const PlaceDetailsScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _imagePageController = PageController();
  bool _loggedView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  /// Fullscreen gallery: all images at full/4K resolution when user taps the fullscreen icon.
  void _openFullscreenGallery(BuildContext context, Place place) {
    if (place.images.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => _FullscreenGalleryPage(
          images: place.images,
          placeName: place.name,
          initialIndex: _imagePageController.hasClients
              ? (_imagePageController.page?.round() ?? 0).clamp(0, place.images.length - 1)
              : 0,
        ),
      ),
    );
  }

  Future<void> _sharePlace(Place place) async {
    AppFeedback.tap();
    final text =
        '${place.name} - ${place.location}\n\nCheck out this place in Visit Tripoli';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      Provider.of<ActivityLogProvider>(context, listen: false).shared(place.name);
      AppFeedback.success(context, 'Place info copied to clipboard');
    }
  }

  Future<void> _showDirectionsPicker(BuildContext context, Place place) async {
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
          destinationName: place.name,
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
    final placesProvider = Provider.of<PlacesProvider>(context);
    final place = placesProvider.getPlaceById(widget.placeId);

    if (place == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Place Not Found')),
        body: const Center(child: Text('Place not found')),
      );
    }

    if (!_loggedView) {
      _loggedView = true;
      final placeId = place.id;
      final placeName = place.name;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Provider.of<ActivityLogProvider>(context, listen: false).placeViewed(placeId, placeName);
      });
    }

    final isSaved = placesProvider.isPlaceSaved(widget.placeId);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Back Header - collapses with image
          SliverAppBar(
            pinned: true,
            expandedHeight: ResponsiveUtils.detailSliverHeroHeight(context),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Place Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            centerTitle: true,
            actions: [
              if (place.images.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.fullscreen, size: 22),
                  onPressed: () => _openFullscreenGallery(context, place),
                  tooltip: 'View all images in full',
                ),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 22),
                onPressed: () => _sharePlace(place),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  place.images.isNotEmpty
                      ? PageView.builder(
                          controller: _imagePageController,
                          itemCount: place.images.length,
                          itemBuilder: (_, i) => RepaintBoundary(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Backdrop: fill the whole area (no black bars) using a blurred cover image.
                                Positioned.fill(
                                  child: AppImage(
                                    key: ValueKey('bg_${place.images[i]}'),
                                    src: place.images[i],
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        Container(color: Colors.grey[300]),
                                    errorWidget: (_, __, ___) =>
                                        Container(color: Colors.grey[300]),
                                  ),
                                ),
                                Positioned.fill(
                                  child: ImageFiltered(
                                    imageFilter:
                                        ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.08),
                                    ),
                                  ),
                                ),
                                // Foreground: show the full image (no crop).
                                Center(
                                  child: AppImage(
                                    key: ValueKey(place.images[i]),
                                    src: place.images[i],
                                    fit: BoxFit.contain,
                                    placeholder: (_, __) =>
                                        Container(color: Colors.transparent),
                                    errorWidget: (_, __, ___) =>
                                        Container(color: Colors.grey[300]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(color: Colors.grey[300]),
                  if (place.images.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: MediaQuery.of(context).size.height < 600 ? 72 : 100,
                      child: _ImagePageIndicator(
                        controller: _imagePageController,
                        count: place.images.length,
                      ),
                    ),
                  // Gradient overlay at bottom
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
                  // Badges
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
                        place.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                            place.rating != null
                                ? place.rating!.toStringAsFixed(1)
                                : '—',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
          // Tabs - sticky below header
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Map'),
                  Tab(text: 'Reviews'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(
                place: place,
                placeId: widget.placeId,
                isSaved: isSaved,
                onShare: _sharePlace,
                onDirections: _showDirectionsPicker,
                onAddToTrip: _showAddToTripDialog,
                onCheckIn: _showCheckIn,
                onBook: _showBookingDialog),
            _MapTab(place: place, onDirections: _showDirectionsPicker),
            _ReviewsTab(placeId: widget.placeId, place: place),
          ],
        ),
      ),
    );
  }

  Future<void> _showCheckIn(BuildContext context, String placeId) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.isGuest) {
      context.go('/login?redirect=${Uri.encodeComponent('/place/$placeId')}');
      return;
    }
    final placesProvider = context.read<PlacesProvider>();
    final place = placesProvider.getPlaceById(placeId);
    final placeName = place?.name ?? 'this place';

    final scanned = await Navigator.of(context).push<CheckInQrData?>(
      MaterialPageRoute(
        builder: (ctx) => CheckInScanScreen(
          placeName: placeName,
        ),
      ),
    );

    if (!context.mounted) return;
    if (scanned == null) return; // user closed scanner

    if (scanned.placeId != placeId) {
      AppSnackBars.showError(
        context,
        'Wrong place. Please scan the QR code at $placeName to check in.',
      );
      return;
    }
    if (scanned.token == null || scanned.token!.isEmpty) {
      AppSnackBars.showError(
        context,
        'This code is not valid for check-in. Scan the official QR printed at the entrance of $placeName.',
      );
      return;
    }

    try {
      final res = await ApiService.instance.checkIn(
        auth.authToken!,
        placeId,
        checkinToken: scanned.token!,
      );
      final newBadges = res['newBadges'] as List? ?? [];
      if (context.mounted) {
        SystemSound.play(SystemSoundType.click);
        AppSnackBars.showSuccess(context, 'Checked in!');
        if (newBadges.isNotEmpty) {
          final names = newBadges.map((b) => b['name']).join(', ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('New badge: $names'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (context.mounted) AppSnackBars.showError(context, e.toString().replaceAll('API Exception: ', ''));
    }
  }

  void _showBookingDialog(BuildContext context, Place place) {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.isGuest) {
      context.go('/login?redirect=${Uri.encodeComponent('/place/${place.id}')}');
      return;
    }
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: auth.userName ?? '');
    final emailController = TextEditingController(text: auth.userEmail ?? '');
    final phoneController = TextEditingController();
    final partySizeController = TextEditingController(text: '1');
    final dateController = TextEditingController();
    final date = DateTime.now();
    dateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: ResponsiveUtils.modalPadding(context),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Book ${place.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.length < 3) return 'Please enter your full name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Email is required';
                      final emailRegex = RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+\$');
                      if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                    validator: (v) {
                      final value = v?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                      if (value.length < 7) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: dateController,
                          decoration: const InputDecoration(
                            labelText: 'Date (YYYY-MM-DD)',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: date,
                              firstDate: date,
                              lastDate: date.add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              dateController.text =
                                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                            }
                          },
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Choose a date';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        child: TextFormField(
                          controller: partySizeController,
                          decoration: const InputDecoration(
                            labelText: 'People',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            final value = int.tryParse(v ?? '');
                            if (value == null || value <= 0) return 'Min 1';
                            if (value > 20) return 'Max 20';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        await ApiService.instance.createBooking(auth.authToken!, {
                          'placeId': place.id,
                          'bookingType': 'place',
                          'bookingDate': dateController.text,
                          'partySize': int.parse(partySizeController.text),
                          'name': nameController.text.trim(),
                          'email': emailController.text.trim(),
                          'phone': phoneController.text.trim(),
                        });
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          AppSnackBars.showSuccess(context, 'Booking created!');
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          AppSnackBars.showError(
                            context,
                            e.toString().replaceAll('API Exception: ', ''),
                          );
                        }
                      }
                    },
                    child: const Text('Confirm booking'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddToTripDialog(BuildContext context, Place place) {
    final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add to Trip'),
        content: tripsProvider.trips.isEmpty
            ? const Text('No trips available. Create a new trip first.')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...tripsProvider.trips.map(
                      (trip) => ListTile(
                        title: Text(trip.name),
                        subtitle: Text(
                          '${trip.startDate.day}/${trip.startDate.month}/${trip.startDate.year} - ${trip.endDate.day}/${trip.endDate.month}/${trip.endDate.year}',
                        ),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          final dateStr = trip.days.isNotEmpty
                              ? trip.days.first.date
                              : '${trip.startDate.year}-${trip.startDate.month.toString().padLeft(2, '0')}-${trip.startDate.day.toString().padLeft(2, '0')}';
                          final err = await tripsProvider.addPlaceToTrip(
                              trip.id, place.id, dateStr);
                          if (context.mounted) {
                            final l10n = AppLocalizations.of(context)!;
                            if (err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    err == 'overlap'
                                        ? l10n.timeConflict
                                        : l10n.tripStopDateNotInRange,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.addedToTrip(place.name))),
                              );
                            }
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

class _AudioGuidesSection extends StatefulWidget {
  final String placeId;

  const _AudioGuidesSection({required this.placeId});

  @override
  State<_AudioGuidesSection> createState() => _AudioGuidesSectionState();
}

class _AudioGuidesSectionState extends State<_AudioGuidesSection> {
  List<dynamic> _guides = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    ApiService.instance.getAudioGuides(placeId: widget.placeId).then((list) {
      if (mounted) setState(() { _guides = list; _loaded = true; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _guides.isEmpty) return const SizedBox.shrink();
    final gap = ResponsiveUtils.sectionGap(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: gap * 1.16),
        const _SectionHeader(icon: Icons.headphones_rounded, title: 'Audio Guide'),
        const SizedBox(height: 12),
        ..._guides.map<Widget>((g) {
          final url = g['audio_url'] as String? ?? '';
          final title = g['title'] as String? ?? 'Audio (${g['language'] ?? 'en'})';
          final dur = g['duration_seconds'] as int?;
          final durStr = dur != null ? '${dur ~/ 60}:${(dur % 60).toString().padLeft(2, '0')}' : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AudioGuidePlayer(
              url: url,
              title: title,
              durationLabel: durStr,
            ),
          );
        }),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

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
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

class _OverviewTab extends StatelessWidget {
  final Place place;
  final String placeId;
  final bool isSaved;
  final Future<void> Function(Place) onShare;
  final Future<void> Function(BuildContext, Place) onDirections;
  final void Function(BuildContext, Place) onAddToTrip;
  final Future<void> Function(BuildContext, String) onCheckIn;
  final void Function(BuildContext, Place) onBook;

  const _OverviewTab({
    required this.place,
    required this.placeId,
    required this.isSaved,
    required this.onShare,
    required this.onDirections,
    required this.onAddToTrip,
    required this.onCheckIn,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PlacesProvider>(context);
    final similarPlaces = placesProvider.places
        .where((p) => p.id != place.id && p.category == place.category)
        .take(6)
        .toList();

    final pad = ResponsiveUtils.contentPadding(context);
    final gap = ResponsiveUtils.sectionGap(context);
    final vertPad = ResponsiveUtils.detailVerticalPadding(context);
    final maxW = ResponsiveUtils.contentMaxWidth(context);
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
                place.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
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
                  place.location,
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
              SizedBox(height: gap * 0.5),
              // Key info: category, duration, price, best time — enhanced and responsive
              _KeyInfoSection(place: place),
              SizedBox(height: gap),
              SizedBox(height: gap * 1.16),
              // Description / Overview
              const _SectionHeader(icon: Icons.article_outlined, title: 'About'),
              const SizedBox(height: 12),
              _OverviewContent(description: place.description),
              if (place.description.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                TtsListenButton(text: place.description, label: 'Listen to description'),
              ],
              // Tags
              if (place.tags != null && place.tags!.isNotEmpty) ...[
                SizedBox(height: gap),
                const _SectionHeader(icon: Icons.label_outline, title: 'Tags'),
                const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: place.tags!
                  .take(10)
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
              // Audio guides
              _AudioGuidesSection(placeId: placeId),
              // Opening hours
              if (place.hours != null && place.hours!.isNotEmpty) ...[
                SizedBox(height: gap * 1.16),
                const _SectionHeader(
                    icon: Icons.access_time_rounded, title: 'Opening Hours'),
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(ResponsiveUtils.isSmallPhone(context) ? 14 : 18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: _formatHours(place.hours!).map(
                  (line) {
                    final idx = line.indexOf(':');
                    final day = idx > 0 ? line.substring(0, idx).trim() : '';
                    final time =
                        idx > 0 ? line.substring(idx + 1).trim() : line;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              day,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              time,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ],
              // Similar & Nearby
              if (similarPlaces.isNotEmpty) ...[
                SizedBox(height: gap * 1.16),
                const _SectionHeader(
                  icon: Icons.explore_outlined,
                  title: 'Similar & Nearby',
                ),
                SizedBox(height: gap * 0.58),
                SizedBox(
                  height: ResponsiveUtils.similarListHeight(context, base: 160),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: similarPlaces.length,
                    separatorBuilder: (_, __) => SizedBox(
                        width: ResponsiveUtils.contentPadding(context) * 0.8),
                itemBuilder: (_, i) {
                  final p = similarPlaces[i];
                  return _SimilarPlaceCard(
                    place: p,
                    onTap: () => context.push('/place/${p.id}'),
                  );
                },
              ),
            ),
          ],
              // Visitor tips
              SizedBox(height: gap * 1.16),
              _SectionHeader(
                  icon: Icons.lightbulb_outline_rounded,
                  title: AppLocalizations.of(context)!.sectionVisitorTips),
              const SizedBox(height: 12),
              ..._visitorTips(place).asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TipCard(tip: e.value),
                    ),
                  ),
              // Contact & practical info
              SizedBox(height: gap * 1.16),
              _ContactInfoCard(place: place),
              SizedBox(height: gap * 1.16),
              // Primary actions
          _PrimaryActions(
            place: place,
            isSaved: isSaved,
            onDirections: () => onDirections(context, place),
            onAddToTrip: () => onAddToTrip(context, place),
            onCheckIn: () => onCheckIn(context, placeId),
            onBook: () => onBook(context, place),
          ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _formatHours(Map<String, dynamic> hours) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = <String>[];
    for (final d in days) {
      final v = hours[d] ?? hours[d.toLowerCase()];
      if (v != null) {
        result.add('$d: $v');
      }
    }
    if (result.isEmpty) {
      for (final e in hours.entries) {
        result.add('${e.key}: ${e.value}');
      }
    }
    return result.isEmpty ? ['Hours vary – check locally'] : result;
  }

  List<String> _visitorTips(Place place) {
    final tips = <String>[];
    if (place.bestTime != null) {
      tips.add('Best time to visit: ${place.bestTime}');
    }
    if (place.duration != null) {
      tips.add('Plan for ${place.duration} to explore fully.');
    }
    if (place.price != null && place.price != '0') {
      tips.add('Entry fee: \$${place.price}');
    }
    if (place.category.toLowerCase().contains('mosque')) {
      tips.add('Dress modestly and remove shoes before entering.');
    }
    if (place.category.toLowerCase().contains('souk') ||
        place.category.toLowerCase().contains('market')) {
      tips.add('Bargaining is common in the souks.');
    }
    if (tips.isEmpty) tips.add('Enjoy your visit to ${place.name}!');
    return tips;
  }
}

class _OverviewContent extends StatefulWidget {
  final String description;

  const _OverviewContent({required this.description});

  @override
  State<_OverviewContent> createState() => _OverviewContentState();
}

class _OverviewContentState extends State<_OverviewContent> {
  bool _expanded = false;
  static const int _collapseLength = 320;

  String _truncateAtBoundary(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    // Prefer paragraph break before maxLen
    final paraBreak = text.lastIndexOf('\n\n', maxLen);
    if (paraBreak > 80) return text.substring(0, paraBreak).trim();
    // Else sentence boundary
    final lastPeriod = text.lastIndexOf('. ', maxLen);
    if (lastPeriod > 80) return text.substring(0, lastPeriod + 1);
    // Fallback: avoid mid-word
    final lastSpace = text.lastIndexOf(' ', maxLen);
    if (lastSpace > 80) return text.substring(0, lastSpace);
    return text.substring(0, maxLen);
  }

  @override
  Widget build(BuildContext context) {
    final desc = widget.description.trim();
    final isEmpty = desc.isEmpty;
    final paragraphs = isEmpty
        ? <String>[]
        : desc
            .split(RegExp(r'\n\s*\n'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
    final isLong = desc.length > _collapseLength;
    final showExpand = isLong && !_expanded;
    final displayText = showExpand
        ? '${_truncateAtBoundary(desc, _collapseLength)}${desc.length > _collapseLength ? '...' : ''}'
        : desc;

    final padding = ResponsiveUtils.isSmallPhone(context) ? 14.0 : 20.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isEmpty
          ? _EmptyOverview()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showExpand)
                  _OverviewParagraph(text: displayText, isLead: true)
                else if (paragraphs.isEmpty)
                  _OverviewParagraph(text: desc, isLead: false)
                else
                  ...paragraphs.asMap().entries.map(
                        (e) => _OverviewParagraph(
                          text: e.value,
                          isLead: e.key == 0,
                        ),
                      ),
                if (showExpand)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextButton.icon(
                      onPressed: () => setState(() => _expanded = true),
                      icon: const Icon(Icons.expand_more, size: 20),
                      label: const Text('Read more'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _OverviewParagraph extends StatelessWidget {
  final String text;
  final bool isLead;

  const _OverviewParagraph({
    required this.text,
    required this.isLead,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.7,
          color: AppTheme.textPrimary,
          letterSpacing: 0.1,
        );
    final leadStyle = style?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLead ? 16 : 0,
        top: isLead ? 0 : 12,
      ),
      child: Text(
        text,
        style: isLead ? leadStyle : style,
      ),
    );
  }
}

class _EmptyOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 20,
          color: AppTheme.textSecondary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'No description available for this place yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

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

class _TipCard extends StatelessWidget {
  final String tip;

  const _TipCard({required this.tip});

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

/// Key info section: category, duration, price, best time — enhanced and comfortable on small phones.
class _KeyInfoSection extends StatelessWidget {
  final Place place;

  const _KeyInfoSection({required this.place});

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveUtils.cardPadding(context) + 2;
    final isSmall = ResponsiveUtils.isSmallPhone(context);
    final isVerySmall = ResponsiveUtils.isVerySmallPhone(context);
    final iconSize = isVerySmall ? 18.0 : (isSmall ? 20.0 : 22.0);
    final valueSize = isVerySmall ? 13.0 : (isSmall ? 14.0 : 15.0);
    final rowSpacing = isVerySmall ? 10.0 : (isSmall ? 12.0 : 14.0);
    final chipPaddingH = isSmall ? 12.0 : 14.0;
    final chipPaddingV = isSmall ? 10.0 : 12.0;

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
          // Category — full-width prominent header chip
          if (place.category.isNotEmpty) ...[
            _KeyInfoChip(
              icon: Icons.category_rounded,
              label: place.category,
              iconSize: iconSize,
              valueSize: valueSize + 1,
              isFree: false,
              paddingH: chipPaddingH,
              paddingV: chipPaddingV,
              fullWidth: true,
              iconInCircle: true,
            ),
            SizedBox(height: rowSpacing),
          ],
          // Duration & Price — row (or stack on very narrow)
          if (place.duration != null || place.price != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (place.duration != null)
                  Expanded(
                    child: _KeyInfoChip(
                      icon: Icons.timer_outlined,
                      label: place.duration!,
                      iconSize: iconSize,
                      valueSize: valueSize,
                      isFree: false,
                      paddingH: chipPaddingH,
                      paddingV: chipPaddingV,
                      fullWidth: false,
                      iconInCircle: true,
                    ),
                  ),
                if (place.duration != null && place.price != null)
                  SizedBox(width: isVerySmall ? 8 : 12),
                if (place.price != null)
                  Expanded(
                    child: _KeyInfoChip(
                      icon: Icons.paid_outlined,
                      label: place.price == '0' ? 'Free' : '\$${place.price}',
                      iconSize: iconSize,
                      valueSize: valueSize,
                      isFree: place.price == '0',
                      paddingH: chipPaddingH,
                      paddingV: chipPaddingV,
                      fullWidth: false,
                      iconInCircle: true,
                    ),
                  ),
              ],
            ),
            if (place.bestTime != null) SizedBox(height: rowSpacing),
          ],
          // Best time — full width, allows 2 lines
          if (place.bestTime != null)
            _KeyInfoChip(
              icon: Icons.wb_sunny_outlined,
              label: place.bestTime!,
              iconSize: iconSize,
              valueSize: valueSize,
              isFree: false,
              paddingH: chipPaddingH,
              paddingV: chipPaddingV,
              fullWidth: true,
              iconInCircle: true,
              maxLines: 2,
            ),
        ],
      ),
    );
  }
}

class _KeyInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double iconSize;
  final double valueSize;
  final bool isFree;
  final double paddingH;
  final double paddingV;
  final bool fullWidth;
  final bool iconInCircle;
  final int maxLines;

  const _KeyInfoChip({
    required this.icon,
    required this.label,
    required this.iconSize,
    required this.valueSize,
    required this.isFree,
    required this.paddingH,
    required this.paddingV,
    this.fullWidth = false,
    this.iconInCircle = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFree ? AppTheme.successColor : AppTheme.primaryColor;
    final iconWidget = iconInCircle
        ? Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: iconSize, color: color),
          )
        : Icon(icon, size: iconSize, color: color);

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
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
          iconWidget,
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

class _SimilarPlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _SimilarPlaceCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardW = ResponsiveUtils.similarCardWidth(context);
    final imgH = ResponsiveUtils.similarCardImageHeight(context);
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
    final cacheW = (cardW * dpr).round().clamp(120, 2400);
    final cacheH = (imgH * dpr).round().clamp(120, 2400);
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
                child: place.images.isNotEmpty
                    ? AppImage(
                        src: place.images.first,
                        fit: BoxFit.cover,
                        cacheWidth: cacheW,
                        cacheHeight: cacheH,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey[300]),
                        errorWidget: (_, __, ___) =>
                            Container(color: Colors.grey[300]),
                      )
                    : Container(color: Colors.grey[300]),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  place.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        height: 1.15,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  final Place place;

  const _ContactInfoCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.isSmallPhone(context) ? 12.0 : 16.0;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ContactRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: place.location,
          ),
          if (place.bestTime != null) ...[
            const SizedBox(height: 12),
            _ContactRow(
              icon: Icons.schedule_outlined,
              label: 'Best Time',
              value: place.bestTime!,
            ),
          ],
          if (place.price != null) ...[
            const SizedBox(height: 12),
            _ContactRow(
              icon: Icons.paid_outlined,
              label: 'Price',
              value: place.price == '0' ? 'Free' : '\$${place.price}',
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      )),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  final Place place;
  final bool isSaved;
  final VoidCallback onDirections;
  final VoidCallback onAddToTrip;
  final VoidCallback onCheckIn;
  final VoidCallback onBook;

  const _PrimaryActions({
    required this.place,
    required this.isSaved,
    required this.onDirections,
    required this.onAddToTrip,
    required this.onCheckIn,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PlacesProvider>(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  AppFeedback.tap();
                  try {
                    await placesProvider.toggleSavePlace(
                      place,
                      auth: Provider.of<AuthProvider>(context, listen: false),
                    );
                    if (context.mounted) {
                      final saved = placesProvider.isPlaceSaved(place.id);
                      if (saved) {
                        Provider.of<ActivityLogProvider>(context, listen: false).placeSaved(place.name);
                      } else {
                        Provider.of<ActivityLogProvider>(context, listen: false).placeUnsaved(place.name);
                      }
                      AppFeedback.success(context, saved ? 'Saved to favourites' : 'Removed from saved');
                    }
                  } catch (_) {
                    if (context.mounted) {
                      AppFeedback.error(context, 'Couldn\'t save place');
                    }
                  }
                },
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  size: ResponsiveUtils.isSmallPhone(context) ? 18 : 20,
                  color: isSaved ? Colors.red : null,
                ),
                label: Text(isSaved ? 'Saved' : 'Save', maxLines: 1, overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.actionButtonPadding(context)),
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.actionButtonGap(context)),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  AppFeedback.tap();
                  Provider.of<ActivityLogProvider>(context, listen: false).directionsRequested(place.name);
                  onDirections();
                },
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
                  AppFeedback.tap();
                  onAddToTrip();
                },
                icon: Icon(Icons.add, size: ResponsiveUtils.isSmallPhone(context) ? 18 : 20),
                label: const Text('Add to Trip', maxLines: 1, overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.actionButtonPadding(context)),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.actionButtonGap(context)),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  AppFeedback.tap();
                  onCheckIn();
                },
                icon: Icon(Icons.location_on_outlined, size: ResponsiveUtils.isSmallPhone(context) ? 18 : 20),
                label: const Text('Check in', maxLines: 1, overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.actionButtonPadding(context)),
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.actionButtonGap(context)),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  AppFeedback.tap();
                  onBook();
                },
                icon: Icon(Icons.calendar_today_outlined, size: ResponsiveUtils.isSmallPhone(context) ? 18 : 20),
                label: const Text('Book', maxLines: 1, overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.actionButtonPadding(context)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MapTab extends StatelessWidget {
  final Place place;
  final Future<void> Function(BuildContext, Place) onDirections;

  const _MapTab({required this.place, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    final hasCoords = place.hasMapCoordinates;

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
                child: hasCoords
                    ? EmbeddedMapDefaults.singlePlace(
                        target: place.mapLatLng!,
                        markerId: place.id,
                        infoTitle: place.name,
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.map_outlined,
                              size: 48, color: Colors.grey),
                        ),
                      ),
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onDirections(context, place),
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
                        if (hasCoords) {
                          context.push('/map?placeId=${place.id}');
                        }
                      },
                      icon: Icon(Icons.map_outlined, size: ResponsiveUtils.isSmallPhone(context) ? 18 : 20),
                      label: const Text('View on Map', maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.actionButtonPadding(context)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap * 0.83),
              Text('How to get there',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Most places in Tripoli\'s old city are best explored on foot. Taxis are available from the city center. Local buses connect main areas.',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: gap),
              const _TransportCard(
                icon: FontAwesomeIcons.personWalking,
                title: 'On Foot',
                description:
                    'Old city is pedestrian-friendly. Allow 15–30 mins from Clock Tower.',
              ),
              SizedBox(height: gap * 0.5),
              const _TransportCard(
                icon: FontAwesomeIcons.taxi,
                title: 'By Taxi',
                description:
                    'Taxis available at Al-Sa\'at Square. Negotiate fare before departure.',
              ),
              SizedBox(height: gap * 0.5),
              const _TransportCard(
                icon: FontAwesomeIcons.bus,
                title: 'By Bus',
                description:
                    'Local buses run from Tripoli bus station to city center.',
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

class _ReviewsTab extends StatefulWidget {
  final String placeId;
  final Place place;

  const _ReviewsTab({required this.placeId, required this.place});

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  List<Map<String, dynamic>> _reviews = [];
  double? _userRating;
  bool _loaded = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loadError = null);
    try {
      final list = await ApiService.instance.getPlaceReviews(widget.placeId);
      if (!mounted) return;
      _reviews = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map<String, dynamic>);
        return <String, dynamic>{
          'id': m['id']?.toString(),
          'user_id': m['user_id']?.toString(),
          'stars': m['stars'] ?? m['rating'],
          'title': m['title']?.toString() ?? '',
          'text': m['text']?.toString() ?? m['review']?.toString() ?? '',
          'author': m['author']?.toString() ?? '',
          'date': m['date']?.toString() ?? '',
        };
      }).toList();
      _loadError = null;
    } catch (e) {
      if (!mounted) return;
      _reviews = [];
      _loadError = e.toString().replaceAll('API Exception: ', '');
    }
    if (mounted) setState(() => _loaded = true);
  }

  void _showRateModal() async {
    int stars = (_userRating ?? (widget.place.rating != null ? widget.place.rating! : 0)).round().clamp(0, 5);
    if (stars < 1) stars = 1; // modal needs at least 1 star to show
    String title = '';
    String reviewText = '';
    String visitDate = '';

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.isGuest) {
      context.go('/login?redirect=${Uri.encodeComponent('/place/${widget.placeId}')}');
      return;
    }
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _RateModal(
        initialStars: stars,
        initialTitle: title,
        initialReview: reviewText,
        initialDate: visitDate,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _userRating = (result['stars'] as int).toDouble();
      });
      try {
        await ApiService.instance.createPlaceReview(auth.authToken!, {
          'placeId': widget.placeId,
          'rating': result['stars'],
          'title': result['title'],
          'text': result['text'],
          'visitDate': result['date'],
        });
        await _loadReviews();
        if (mounted) AppSnackBars.showSuccess(context, 'Review submitted');
      } catch (e) {
        if (mounted) {
          AppSnackBars.showError(
            context,
            e.toString().replaceAll('API Exception: ', ''),
          );
        }
      }
    }
  }

  Future<void> _showAllReviewsModal() async {
    await _loadReviews();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ReviewsModal(
        placeId: widget.placeId,
        place: widget.place,
        reviews: List<Map<String, dynamic>>.from(_reviews),
        userRating: _userRating,
        currentUserId: context.read<AuthProvider>().userId,
        onRate: () {
          Navigator.pop(ctx);
          _showRateModal();
        },
        onEdit: _onEditReview,
        onDelete: _onDeleteReview,
      ),
    );
  }

  Future<void> _onEditReview(Map<String, dynamic> review) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.authToken == null) return;
    final reviewId = review['id']?.toString();
    if (reviewId == null || reviewId.isEmpty) return;
    if (mounted && Navigator.of(context).canPop()) Navigator.pop(context);
    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _RateModal(
        initialStars: ((review['stars'] ?? review['rating']) as num?)?.toInt().clamp(1, 5) ?? 1,
        initialTitle: review['title']?.toString() ?? '',
        initialReview: review['text']?.toString() ?? review['review']?.toString() ?? '',
        initialDate: review['date']?.toString() ?? '',
      ),
    );
    if (result != null && mounted) {
      try {
        await ApiService.instance.updatePlaceReview(auth.authToken!, reviewId, {
          'rating': result['stars'],
          'title': result['title'],
          'text': result['text'],
          'date': result['date'],
        });
        await _loadReviews();
        if (mounted) AppSnackBars.showSuccess(context, 'Review updated');
      } catch (e) {
        if (mounted) {
          AppSnackBars.showError(
            context,
            e.toString().replaceAll('API Exception: ', ''),
          );
        }
      }
    }
  }

  Future<void> _onDeleteReview(Map<String, dynamic> review) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.authToken == null) return;
    final reviewId = review['id']?.toString();
    if (reviewId == null || reviewId.isEmpty) return;
    if (mounted && Navigator.of(context).canPop()) Navigator.pop(context);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text(
          'This action cannot be undone. Do you want to delete this review?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService.instance.deletePlaceReview(auth.authToken!, reviewId);
      await _loadReviews();
      if (mounted) AppSnackBars.showSuccess(context, 'Review deleted');
    } catch (e) {
      if (mounted) {
        AppSnackBars.showError(
          context,
          e.toString().replaceAll('API Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    // Use real data from database only: rating and count from loaded reviews
    final totalReviews = _reviews.length;
    final displayRating = _reviews.isNotEmpty
        ? _reviews.map((r) => (r['stars'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a + b) / _reviews.length
        : (_userRating ?? 0.0);
    final breakdown = _computeBreakdown();

    final pad = ResponsiveUtils.contentPadding(context);
    final vertPad = ResponsiveUtils.detailVerticalPadding(context);
    final maxW = ResponsiveUtils.contentMaxWidth(context);
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
          pad, vertPad, pad, 32 + MediaQuery.of(context).padding.bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating overview
          Center(
            child: Column(
              children: [
                Text(
                  displayRating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final filled = i < displayRating.round();
                    return Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppTheme.warningColor,
                      size: 28,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalReviews review${totalReviews == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Breakdown
          if (breakdown.isNotEmpty) ...[
            ...breakdown.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text('${e.key}',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: e.value,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation(AppTheme.warningColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Actions
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showRateModal,
              icon: Icon(Icons.star_outline, size: ResponsiveUtils.isSmallPhone(context) ? 18 : 20),
              label: const Text('Rate this Place', maxLines: 1, overflow: TextOverflow.ellipsis),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.actionButtonPadding(context)),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.actionButtonGap(context)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAllReviewsModal,
              icon: Icon(Icons.rate_review_outlined, size: ResponsiveUtils.isSmallPhone(context) ? 18 : 20),
              label: const Text('View All Reviews', maxLines: 1, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.actionButtonPadding(context)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Recent Reviews', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (_loadError != null)
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.cardPadding(context) + 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 12),
                    Text(
                      'Couldn\'t load reviews',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (_loadError!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _loadError!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _loadReviews,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_reviews.isEmpty)
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.cardPadding(context) + 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.rate_review_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No reviews yet. Be the first!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._reviews.take(5).map((r) => _ReviewCard(
                  review: r,
                  currentUserId: context.read<AuthProvider>().userId,
                  onEdit: _onEditReview,
                  onDelete: _onDeleteReview,
                )),
        ],
          ),
        ),
      ),
    );
  }

  Map<int, double> _computeBreakdown() {
    final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in _reviews) {
      final s = (r['stars'] as num?)?.toInt() ?? 0;
      if (counts.containsKey(s)) counts[s] = counts[s]! + 1;
    }
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) return {};
    return {
      for (final e in counts.entries) e.key: e.value / total,
    };
  }
}

class _RateModal extends StatefulWidget {
  final int initialStars;
  final String initialTitle;
  final String initialReview;
  final String initialDate;

  const _RateModal({
    required this.initialStars,
    required this.initialTitle,
    required this.initialReview,
    required this.initialDate,
  });

  @override
  State<_RateModal> createState() => _RateModalState();
}

class _RateModalState extends State<_RateModal> {
  late int _stars;
  late TextEditingController _titleController;
  late TextEditingController _reviewController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _stars = widget.initialStars;
    _titleController = TextEditingController(text: widget.initialTitle);
    _reviewController = TextEditingController(text: widget.initialReview);
    _dateController = TextEditingController(text: widget.initialDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _reviewController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: ResponsiveUtils.modalPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Rate this Place',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final filled = i < _stars;
                    return IconButton(
                      icon: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppTheme.warningColor,
                        size: 40,
                      ),
                      onPressed: () => setState(() => _stars = i + 1),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (optional)',
                    hintText: 'Sum up your experience',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewController,
                  decoration: const InputDecoration(
                    labelText: 'Your review (optional)',
                    hintText: 'Share your experience...',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Visit date (optional)',
                    hintText: 'e.g. Feb 2025',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, {
                          'stars': _stars,
                          'title': _titleController.text,
                          'text': _reviewController.text,
                          'date': _dateController.text,
                        }),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewsModal extends StatelessWidget {
  final String placeId;
  final Place place;
  final List<Map<String, dynamic>> reviews;
  final double? userRating;
  final String? currentUserId;
  final VoidCallback onRate;
  final void Function(Map<String, dynamic> review)? onEdit;
  final void Function(Map<String, dynamic> review)? onDelete;

  const _ReviewsModal({
    required this.placeId,
    required this.place,
    required this.reviews,
    required this.userRating,
    required this.onRate,
    this.currentUserId,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: ResponsiveUtils.modalPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reviews',
                      style: Theme.of(context).textTheme.headlineSmall),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onRate();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Review'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (reviews.isEmpty)
                Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.cardPadding(context) + 8),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.rate_review_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No reviews yet. Be the first to rate!',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...reviews.map((r) => _ReviewCard(
                      review: r,
                      currentUserId: currentUserId,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final String? currentUserId;
  final void Function(Map<String, dynamic> review)? onEdit;
  final void Function(Map<String, dynamic> review)? onDelete;

  const _ReviewCard({
    required this.review,
    this.currentUserId,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rawStars = review['stars'] ?? review['rating'];
    final stars = (rawStars is num)
        ? rawStars.toInt().clamp(1, 5)
        : (int.tryParse(rawStars?.toString() ?? '') ?? 0).clamp(1, 5);
    final title = review['title']?.toString() ?? '';
    final text = review['text']?.toString() ?? review['review']?.toString() ?? '';
    final authorRaw = review['author']?.toString() ?? '';
    final author = authorRaw.isEmpty || authorRaw == 'Visitor'
        ? AppLocalizations.of(context)!.reviewAuthorGuest
        : authorRaw;
    final date = review['date']?.toString() ?? '';
    final reviewUserId = review['user_id']?.toString();
    final isOwnReview = currentUserId != null &&
        reviewUserId != null &&
        currentUserId!.toLowerCase() == reviewUserId.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                  5,
                  (i) => Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppTheme.warningColor,
                        size: 18,
                      )),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  author,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (date.isNotEmpty) ...[
                Text(
                  '• $date',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
              if (isOwnReview && (onEdit != null || onDelete != null)) ...[
                const SizedBox(width: 8),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => onEdit!(review),
                    tooltip: 'Edit',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[700]),
                    onPressed: () => onDelete!(review),
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ],
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          ],
          if (text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _ImagePageIndicator extends StatelessWidget {
  final PageController controller;
  final int count;

  const _ImagePageIndicator({required this.controller, required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        int page = 0;
        if (controller.hasClients && controller.page != null) {
          page = controller.page!.round().clamp(0, count - 1);
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            final isActive = i == page;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: isActive ? 1 : 0.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Fullscreen gallery: all place images at full/4K resolution (no cache size limit).
class _FullscreenGalleryPage extends StatefulWidget {
  const _FullscreenGalleryPage({
    required this.images,
    required this.placeName,
    this.initialIndex = 0,
  });

  final List<String> images;
  final String placeName;
  final int initialIndex;

  @override
  State<_FullscreenGalleryPage> createState() => _FullscreenGalleryPageState();
}

class _FullscreenGalleryPageState extends State<_FullscreenGalleryPage> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: AppImage(
                  key: ValueKey('full_${widget.images[i]}'),
                  src: widget.images[i],
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 64, color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        widget.placeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(),
                if (widget.images.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _ImagePageIndicator(
                      controller: _controller,
                      count: widget.images.length,
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
