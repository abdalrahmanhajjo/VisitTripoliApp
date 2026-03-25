import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../providers/places_provider.dart';
import '../providers/events_provider.dart';
import '../providers/tours_provider.dart';
import '../providers/trips_provider.dart';
import '../models/event.dart';
import '../models/tour.dart';
import '../providers/language_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import 'package:tripoli_explorer/l10n/app_localizations.dart';
import '../widgets/app_image.dart';
import '../utils/profile_avatar_storage.dart';
import '../utils/responsive_utils.dart';

String _buildProfileAvatarUrl(ProfileProvider profile) {
  final url = profile.avatarUrl.trim();
  if (url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  final path = url.startsWith('/') ? url : '/$url';
  return '${ApiConfig.effectiveBaseUrl}$path';
}

Widget _profileAvatarLoadingPlaceholder(double size) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
      ),
    ),
    child: const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
      ),
    ),
  );
}

BoxDecoration _profileCardDecoration() {
  return BoxDecoration(
    color: AppTheme.surfaceColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.85)),
    boxShadow: [
      BoxShadow(
        color: AppTheme.textPrimary.withValues(alpha: 0.035),
        blurRadius: 20,
        offset: const Offset(0, 6),
        spreadRadius: -2,
      ),
    ],
  );
}

/// Responsive breakpoints matching Explore page.
class _ProfileResponsive {
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static bool isSmallPhone(BuildContext context) => width(context) < 340;
  static bool isCompact(BuildContext context) => width(context) < 360;
  static double horizontalPadding(BuildContext context) {
    return ResponsiveUtils.contentPadding(context);
  }
  static double sectionGap(BuildContext context) {
    if (isSmallPhone(context)) return 10;
    if (isCompact(context)) return 12;
    return 18;
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _hasLoadedFromApi = false;
  bool _isLoadingProfile = false;
  bool _isUploadingAvatar = false;
  bool _formFilledFromProfile = false;
  String? _lastAccountKey;

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _cityController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _cityController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final key = '${auth.isGuest}:${auth.userId ?? ''}';
    if (_lastAccountKey != key) {
      _lastAccountKey = key;
      _hasLoadedFromApi = false;
      _formFilledFromProfile = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _fillFormFromProfile(ProfileProvider p) {
    _nameController.text = p.name;
    _usernameController.text = p.username;
    _emailController.text = p.email;
    _cityController.text = p.city;
    _bioController.text = p.bio;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profile = Provider.of<ProfileProvider>(context);
    final places = Provider.of<PlacesProvider>(context);
    final trips = Provider.of<TripsProvider>(context);
    final events = Provider.of<EventsProvider>(context);
    final toursP = Provider.of<ToursProvider>(context);
    final language = Provider.of<LanguageProvider>(context);

    // Load profile from API for logged-in users so avatar and data come from database (persists after reload)
    if (!_hasLoadedFromApi && auth.authToken != null && !auth.isGuest) {
      _hasLoadedFromApi = true;
      _isLoadingProfile = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ok = await profile.loadFromApi(auth.authToken);
        if (mounted) {
          setState(() => _isLoadingProfile = false);
          _fillFormFromProfile(profile);
          _formFilledFromProfile = true;
        }
        if (mounted && ok && profile.name.isEmpty && auth.userName != null) {
          profile.syncFromAuth(auth.userName, auth.userEmail);
        }
      });
    }
    // Fill form from profile when data is already available (e.g. guest, or cached profile)
    if (!_formFilledFromProfile &&
        !_isLoadingProfile &&
        (profile.name.isNotEmpty ||
            profile.username.isNotEmpty ||
            profile.email.isNotEmpty)) {
      _formFilledFromProfile = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isEditing) {
          _fillFormFromProfile(profile);
          setState(() {});
        }
      });
    }

    final savedCount = places.savedPlaces.length;
    final tripCount = trips.trips.length;
    final favoritesCount =
        savedCount + events.savedEvents.length + toursP.savedTours.length;

    final hp = _ProfileResponsive.horizontalPadding(context);
    final bottomPad = _ProfileResponsive.isSmallPhone(context) ? 20.0 : 28.0;
    final cardLift = _ProfileResponsive.isSmallPhone(context) ? -22.0 : -32.0;

    Future<void> onPullRefresh() async {
      final token = auth.authToken;
      if (token != null && !auth.isGuest) {
        await profile.loadFromApi(token);
        if (mounted) {
          _fillFormFromProfile(profile);
          setState(() {});
        }
      } else if (mounted) {
        setState(() {});
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        top: false,
        bottom: true,
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: onPullRefresh,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeader(
                  isEditing: _isEditing,
                  onBack: () => context.pop(),
                  onEditToggle: () {
                    setState(() {
                      _isEditing = !_isEditing;
                      if (_isEditing) {
                        _fillFormFromProfile(profile);
                      }
                    });
                  },
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(hp, 0, hp, bottomPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: Offset(0, cardLift),
                        child: _isLoadingProfile
                            ? _buildProfileLoadingCard()
                            : _ProfileUserCard(
                                profile: profile,
                                canChangeAvatar: auth.isLoggedIn && !auth.isGuest,
                                isUploadingAvatar: _isUploadingAvatar,
                                onAvatarTap: () => _pickAndUploadAvatar(context, auth, profile),
                              ),
                      ),
                  SizedBox(height: _ProfileResponsive.sectionGap(context)),
                  _ProfileStats(
                    trips: tripCount,
                    favoritesCount: favoritesCount,
                    onTripsTap: () => _showTripsModal(context),
                    onFavoritesTap: () => _showFavoritesModal(context),
                  ),
                  if (auth.isLoggedIn && !auth.isGuest && auth.authToken != null) ...[
                    SizedBox(height: _ProfileResponsive.sectionGap(context)),
                    _ProfileBookingsBadgesRow(
                      onBookings: () => _showBookingsModal(context, auth.authToken!),
                      onBadges: () => _showBadgesModal(context, auth.authToken!),
                    ),
                  ],
                  SizedBox(height: _ProfileResponsive.sectionGap(context)),
                  _ProfileAccountDetails(
                    profile: profile,
                    isEditing: _isEditing,
                    nameController: _nameController,
                    usernameController: _usernameController,
                    emailController: _emailController,
                    cityController: _cityController,
                    bioController: _bioController,
                    onCancel: () {
                      setState(() => _isEditing = false);
                      _fillFormFromProfile(profile);
                    },
                    onSave: () async {
                      final ok = await profile.updateProfile(
                        name: _nameController.text.trim(),
                        username: _usernameController.text.trim(),
                        email: _emailController.text.trim(),
                        city: _cityController.text.trim(),
                        bio: _bioController.text.trim(),
                        authToken: auth.authToken,
                      );
                      setState(() => _isEditing = false);
                      if (context.mounted) {
                        _showToast(
                          context,
                          ok
                              ? AppLocalizations.of(context)!.profileSaved
                              : 'Failed to save. Check connection.',
                        );
                      }
                    },
                  ),
                  SizedBox(height: _ProfileResponsive.sectionGap(context)),
                  _ProfileSettings(
                    profile: profile,
                    languageProvider: language,
                    authToken: auth.isGuest ? null : auth.authToken,
                    showAccountLinks: auth.isLoggedIn && !auth.isGuest,
                    showTechnicalAppSettings: auth.isAdmin,
                  ),
                  SizedBox(height: _ProfileResponsive.sectionGap(context)),
                  _ProfileRateCard(
                    profile: profile,
                    authToken: auth.isGuest ? null : auth.authToken,
                    onSendFeedback: () => _sendFeedbackEmail(profile),
                  ),
                  SizedBox(height: _ProfileResponsive.sectionGap(context)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.developerCredit,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppTheme.textTertiary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: _ProfileResponsive.sectionGap(context) * 0.65),
                    _ProfileSessionCard(
                      onLogout: () async {
                        await Provider.of<AuthProvider>(context, listen: false)
                            .logout();
                        if (context.mounted) context.go('/intro');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildProfileLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _profileCardDecoration(),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 16),
            Text('Loading profile...',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context, AuthProvider auth, ProfileProvider profile) async {
    if (auth.authToken == null || auth.authToken!.isEmpty) return;
    if (_isUploadingAvatar) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null || !context.mounted) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty || !context.mounted) return;
      final url = await ApiService.instance.uploadProfileAvatar(auth.authToken!, bytes: bytes);
      if (url != null && context.mounted) {
        await profile.updateProfile(avatarUrl: url, authToken: auth.authToken);
        if (context.mounted) {
          _showToast(context, AppLocalizations.of(context)!.profileSaved);
        }
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString()
            .replaceAll('API Exception: ', '')
            .replaceAll('API 400: ', '')
            .replaceAll('API 500: ', '')
            .replaceAll('API 503: ', '');
        _showToast(context, msg.length > 80 ? '${msg.substring(0, 77)}...' : msg);
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      ),
    );
  }

  static const _feedbackMail = 'tripoliexplorer@gmail.com';

  Future<void> _sendFeedbackEmail(ProfileProvider profile) async {
    final l10n = AppLocalizations.of(context)!;
    if (profile.appRating == 0) {
      _showToast(context, l10n.pickStarsFirst);
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: _feedbackMail,
      queryParameters: {
        'subject': 'Visit Tripoli feedback',
        'body': 'Rating: ${profile.appRating}/5\n\n',
      },
    );
    var opened = false;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        opened = true;
      }
    } catch (_) {}
    if (!mounted) return;
    if (!opened) {
      _showToast(context, l10n.couldNotOpenEmail);
      return;
    }
    if (profile.appRating <= 3) {
      _showToast(context, l10n.feedbackNoted);
    } else {
      _showToast(context, l10n.happyEnjoying);
    }
  }

  void _showFavoritesModal(BuildContext context) {
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    final events = Provider.of<EventsProvider>(context, listen: false);
    final tours = Provider.of<ToursProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final saved = placesProvider.savedPlaces;
    final savedEv = events.savedEvents;
    final savedTr = tours.savedTours;
    final isEmpty =
        saved.isEmpty && savedEv.isEmpty && savedTr.isEmpty;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetH = MediaQuery.sizeOf(ctx).height * 0.88;
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: sheetH,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _ProfileResponsive.horizontalPadding(ctx),
                      16,
                      _ProfileResponsive.horizontalPadding(ctx),
                      8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.profileFavoritesTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip:
                              MaterialLocalizations.of(ctx).closeButtonTooltip,
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(FontAwesomeIcons.heart,
                                      size: 56,
                                      color: AppTheme.textTertiary),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.favoritesEmptyTitle,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.favoritesEmptyBody,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.45,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView(
                  padding: EdgeInsets.fromLTRB(
                    _ProfileResponsive.horizontalPadding(ctx),
                    0,
                    _ProfileResponsive.horizontalPadding(ctx),
                    24 + MediaQuery.paddingOf(ctx).bottom,
                  ),
                  children: [
                    if (saved.isNotEmpty) ...[
                      _favoritesSectionHeader(l10n.favoritesSectionPlaces),
                      ...saved.map((p) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: p.images.isNotEmpty
                                ? SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: AppImage(
                                        src: p.images.first,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) =>
                                            _placeholderIcon(48),
                                      ),
                                    ),
                                  )
                                : _placeholderIcon(48),
                            title: Text(p.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(p.location),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/place/${p.id}');
                            },
                          )),
                      const SizedBox(height: 8),
                    ],
                    if (savedEv.isNotEmpty) ...[
                      _favoritesSectionHeader(l10n.favoritesSectionEvents),
                      ...savedEv.map((Event e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: e.image != null && e.image!.isNotEmpty
                                    ? AppImage(
                                        src: e.image!,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) =>
                                            _placeholderIcon(48),
                                      )
                                    : _placeholderIcon(48),
                              ),
                            ),
                            title: Text(e.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(e.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/event/${e.id}');
                            },
                          )),
                      const SizedBox(height: 8),
                    ],
                    if (savedTr.isNotEmpty) ...[
                      _favoritesSectionHeader(l10n.favoritesSectionTours),
                      ...savedTr.map((Tour t) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: t.image.isNotEmpty
                                    ? AppImage(
                                        src: t.image,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) =>
                                            _placeholderIcon(48),
                                      )
                                    : _placeholderIcon(48),
                              ),
                            ),
                            title: Text(t.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(t.duration),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/tour/${t.id}');
                            },
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _favoritesSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  void _showBookingsModal(BuildContext context, String token) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final h = MediaQuery.sizeOf(ctx).height * 0.85;
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: h,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.myBookings,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: ApiService.instance.getBookings(token),
                      builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.profileLoadFailed,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.bookingsEmptyHint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final b = list[i] as Map<String, dynamic>;
                      final title = (b['place_name'] ?? b['tour_name'] ?? '')
                          .toString()
                          .trim();
                      final date =
                          (b['booking_date'] ?? '').toString();
                      final slot =
                          (b['time_slot'] ?? '').toString();
                      final status =
                          (b['status'] ?? '').toString();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.12),
                          child: const Icon(FontAwesomeIcons.calendarCheck,
                              size: 18, color: AppTheme.primaryColor),
                        ),
                        title: Text(
                          title.isEmpty ? '—' : title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            if (date.isNotEmpty) date,
                            if (slot.isNotEmpty) slot,
                            if (status.isNotEmpty) status,
                          ].join(' · '),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  );
                },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBadgesModal(BuildContext context, String token) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final h = MediaQuery.sizeOf(ctx).height * 0.88;
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: h,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.myBadges,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: ApiService.instance.getMyBadges(token),
                      builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.profileLoadFailed,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  }
                  final data = snap.data ?? {};
                  final rawBadges = data['badges'];
                  final badges = rawBadges is List ? rawBadges : <dynamic>[];
                  final placeCountRaw = data['placesCheckedIn'];
                  final checkInCount = placeCountRaw is num
                      ? placeCountRaw.toInt()
                      : int.tryParse('$placeCountRaw') ?? 0;
                  if (badges.isEmpty) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (checkInCount > 0)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                l10n.profilePlacesCheckIns(checkInCount),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          const Icon(FontAwesomeIcons.trophy,
                              size: 48, color: AppTheme.textTertiary),
                          const SizedBox(height: 12),
                          Text(
                            l10n.badgesEmptyHint,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      if (checkInCount > 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withValues(alpha: 0.12),
                                AppTheme.primaryDark.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(FontAwesomeIcons.locationDot,
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.profilePlacesCheckIns(checkInCount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...badges.map((raw) {
                        final m = raw as Map<String, dynamic>;
                        final name = (m['name'] ?? '').toString();
                        final icon = (m['icon'] ?? '🏅').toString();
                        final desc =
                            (m['description'] ?? '').toString();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(icon, style: const TextStyle(fontSize: 32)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        desc,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTripsModal(BuildContext context) {
    final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
    final tripsList = tripsProvider.trips;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileListSheet(
        title: AppLocalizations.of(context)!.myTrips,
        isEmpty: tripsList.isEmpty,
        emptyIcon: FontAwesomeIcons.route,
        emptyTitle: AppLocalizations.of(context)!.noTripsYet,
        emptySubtitle: AppLocalizations.of(context)!.createFirstTripAi,
        itemCount: tripsList.length,
        itemBuilder: (context, index) {
          final t = tripsList[index];
          return ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(FontAwesomeIcons.route,
                  color: AppTheme.primaryColor),
            ),
            title: Text(t.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${t.startDate.day}/${t.startDate.month}/${t.startDate.year}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(ctx);
              context.go('/trips');
            },
          );
        },
      ),
    );
  }

  Widget _placeholderIcon(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.borderColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.place, color: AppTheme.textTertiary),
      );
}

class _ProfileHeader extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onBack;
  final VoidCallback onEditToggle;

  const _ProfileHeader({
    required this.isEditing,
    required this.onBack,
    required this.onEditToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hp = _ProfileResponsive.horizontalPadding(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final l10n = AppLocalizations.of(context)!;
    final small = _ProfileResponsive.isSmallPhone(context);
    final compact = _ProfileResponsive.isCompact(context);
    final titleSize = small ? 21.0 : 26.0;
    final subtitleSize = small ? 12.0 : 13.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(4, topInset + 8, hp, small ? 36 : 44),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryDark.withValues(alpha: 0.92),
            const Color(0xFF0D5C55),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.profile,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.6,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: small ? 4 : 6),
                  Text(
                    l10n.profileScreenSubtitle,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: small ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: Colors.white,
            elevation: 0,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onEditToggle,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 16,
                  vertical: compact ? 10 : 12,
                ),
                child: compact
                    ? Tooltip(
                        message: isEditing ? l10n.done : l10n.edit,
                        child: Icon(
                          isEditing ? Icons.check_rounded : Icons.edit_rounded,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isEditing ? Icons.check_rounded : Icons.edit_rounded,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isEditing ? l10n.done : l10n.edit,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileUserCard extends StatelessWidget {
  final ProfileProvider profile;
  final bool canChangeAvatar;
  final bool isUploadingAvatar;
  final VoidCallback? onAvatarTap;

  const _ProfileUserCard({
    required this.profile,
    this.canChangeAvatar = false,
    this.isUploadingAvatar = false,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final stackVertical = _ProfileResponsive.isCompact(context);
    final avatarSize = stackVertical ? 76.0 : 88.0;
    final hp = _ProfileResponsive.horizontalPadding(context);
    final padH = stackVertical ? (hp < 14 ? 14.0 : hp) : 20.0;
    return Container(
      padding: EdgeInsets.fromLTRB(padH, stackVertical ? 18 : 22, padH, stackVertical ? 18 : 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.045),
            blurRadius: 28,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        children: [
          if (stackVertical) ...[
            Center(child: _profileAvatar(context, profile, avatarSize)),
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  profile.name.isEmpty
                      ? AppLocalizations.of(context)!.profileIdentity
                      : profile.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: stackVertical ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile.username.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile.username,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (profile.city.isNotEmpty)
                      _ProfileBadge(
                        icon: FontAwesomeIcons.locationDot,
                        label: profile.city,
                      ),
                    _ProfileBadge(
                      icon: FontAwesomeIcons.compass,
                      label: AppLocalizations.of(context)!.explorer,
                      subtle: true,
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _profileAvatar(context, profile, avatarSize),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.isEmpty
                            ? AppLocalizations.of(context)!.profileIdentity
                            : profile.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile.username.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          profile.username,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (profile.city.isNotEmpty)
                            _ProfileBadge(
                              icon: FontAwesomeIcons.locationDot,
                              label: profile.city,
                            ),
                          _ProfileBadge(
                            icon: FontAwesomeIcons.compass,
                            label: AppLocalizations.of(context)!.explorer,
                            subtle: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: stackVertical ? 14 : 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.memberSince,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  profile.memberSince,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileAvatar(BuildContext context, ProfileProvider profile, double size) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: _buildProfileAvatarUrl(profile).isNotEmpty
            ? KeyedSubtree(
                key: ValueKey('avatar_${profile.avatarUrl}_${profile.avatarLocalPath}'),
                child: buildProfileAvatarImage(
                  networkUrl: _buildProfileAvatarUrl(profile),
                  localPath: profile.avatarLocalPath.isNotEmpty ? profile.avatarLocalPath : null,
                  width: size,
                  height: size,
                  placeholder: _profileAvatarLoadingPlaceholder(size),
                  errorWidget: _avatarPlaceholder(profile, size),
                ),
              )
            : _avatarPlaceholder(profile, size),
      ),
    );
    if (canChangeAvatar && onAvatarTap != null) {
      return Semantics(
        label: AppLocalizations.of(context)!.changeProfilePhoto,
        button: true,
        child: GestureDetector(
          onTap: isUploadingAvatar ? null : onAvatarTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              avatar,
              if (isUploadingAvatar)
                Positioned.fill(
                  child: ClipOval(
                    child: Container(
                      color: Colors.black38,
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return avatar;
  }

  Widget _avatarPlaceholder(ProfileProvider profile, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
        ),
      ),
      child: Center(
        child: Text(
          profile.getInitials(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool subtle;

  const _ProfileBadge(
      {required this.icon, required this.label, this.subtle = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: subtle
            ? AppTheme.surfaceVariant.withValues(alpha: 0.6)
            : AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: subtle
              ? AppTheme.borderColor
              : AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: subtle ? AppTheme.textTertiary : AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: subtle ? FontWeight.w500 : FontWeight.w600,
              color: subtle ? AppTheme.textSecondary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  final int trips;
  final int favoritesCount;
  final VoidCallback onTripsTap;
  final VoidCallback onFavoritesTap;

  const _ProfileStats({
    required this.trips,
    required this.favoritesCount,
    required this.onTripsTap,
    required this.onFavoritesTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = _ProfileResponsive.isCompact(context);
    final gap = compact ? 6.0 : 8.0;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: AppLocalizations.of(context)!.trips,
            value: trips.toString(),
            meta: AppLocalizations.of(context)!.createdInApp,
            onTap: onTripsTap,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _StatCard(
            label: AppLocalizations.of(context)!.profileFavoritesTitle,
            value: favoritesCount.toString(),
            meta: AppLocalizations.of(context)!.profileFavoritesMeta,
            onTap: onFavoritesTap,
          ),
        ),
      ],
    );
  }
}

class _ProfileBookingsBadgesRow extends StatelessWidget {
  final VoidCallback onBookings;
  final VoidCallback onBadges;

  const _ProfileBookingsBadgesRow({
    required this.onBookings,
    required this.onBadges,
  });

  @override
  Widget build(BuildContext context) {
    final compact = _ProfileResponsive.isCompact(context);
    final gap = compact ? 8.0 : 10.0;
    final l10n = AppLocalizations.of(context)!;

    Widget bookingsCard() {
      return Material(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onBookings,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(compact ? 14 : 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppTheme.borderColor.withValues(alpha: 0.85)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(FontAwesomeIcons.calendarCheck,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.myBookings,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.profileBookingsCardSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textTertiary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textTertiary),
              ],
            ),
          ),
        ),
      );
    }

    Widget badgesCard() {
      return Material(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onBadges,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(compact ? 14 : 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppTheme.borderColor.withValues(alpha: 0.85)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB020).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(FontAwesomeIcons.trophy,
                      color: Color(0xFFB45309), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.myBadges,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.profileBadgesCardSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textTertiary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textTertiary),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 380;
        final tileW = narrow
            ? c.maxWidth
            : (c.maxWidth - gap).clamp(0.0, double.infinity) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(width: tileW, child: bookingsCard()),
            SizedBox(width: tileW, child: badgesCard()),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String meta;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.meta,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = _ProfileResponsive.isCompact(context);
    final small = _ProfileResponsive.isSmallPhone(context);
    final child = Container(
      constraints: BoxConstraints(minHeight: small ? 78 : (compact ? 84 : 92)),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: small ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios_rounded,
                    size: small ? 11 : 12, color: AppTheme.textTertiary.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: small ? 20 : 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            meta,
            style: TextStyle(
              fontSize: small ? 10 : 11,
              color: AppTheme.textTertiary,
              height: 1.25,
            ),
            maxLines: small ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    if (onTap != null) {
      return Semantics(
        button: true,
        label: '$label: $value. $meta',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: child,
          ),
        ),
      );
    }
    return child;
  }
}

class _ProfileAccountDetails extends StatelessWidget {
  final ProfileProvider profile;
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController cityController;
  final TextEditingController bioController;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _ProfileAccountDetails({
    required this.profile,
    required this.isEditing,
    required this.nameController,
    required this.usernameController,
    required this.emailController,
    required this.cityController,
    required this.bioController,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.accountDetails,
          caption: l10n.privateOnDevice,
        ),
        const SizedBox(height: 10),
        if (isEditing)
          Container(
            padding:
                EdgeInsets.all(_ProfileResponsive.isCompact(context) ? 14 : 18),
            decoration: _profileCardDecoration(),
            child: Column(
              children: [
                _FormField(
                    label: l10n.fullName,
                    controller: nameController,
                    enabled: true,
                    placeholder: l10n.yourName),
                const SizedBox(height: 14),
                _FormField(
                    label: l10n.username,
                    controller: usernameController,
                    enabled: true,
                    placeholder: l10n.usernamePlaceholder),
                const SizedBox(height: 14),
                _FormField(
                    label: l10n.emailOptional,
                    controller: emailController,
                    enabled: true,
                    placeholder: l10n.emailHint,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _FormField(
                    label: l10n.homeCity,
                    controller: cityController,
                    enabled: true,
                    placeholder: 'Tripoli, Lebanon'),
                const SizedBox(height: 14),
                _FormField(
                    label: l10n.shortNote,
                    controller: bioController,
                    enabled: true,
                    placeholder: l10n.bioPlaceholder,
                    lines: 3),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onCancel,
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.surfaceColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(l10n.saveProfile),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          _ProfileReadOnlyAccount(profile: profile),
      ],
    );
  }
}

class _ProfileReadOnlyAccount extends StatelessWidget {
  final ProfileProvider profile;

  const _ProfileReadOnlyAccount({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;

    String display(String v) => v.trim().isEmpty ? l10n.notSet : v.trim();

    return Container(
      decoration: _profileCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ProfileDetailRow(
            icon: Icons.person_outline_rounded,
            label: l10n.fullName,
            value: display(profile.name),
            valueStyle: t.bodyLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppTheme.borderColor.withValues(alpha: 0.6)),
          _ProfileDetailRow(
            icon: Icons.alternate_email_rounded,
            label: l10n.username,
            value: display(profile.username),
            valueStyle: t.bodyLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppTheme.borderColor.withValues(alpha: 0.6)),
          _ProfileDetailRow(
            icon: Icons.mail_outline_rounded,
            label: l10n.emailOptional,
            value: display(profile.email),
            valueStyle: t.bodyLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppTheme.borderColor.withValues(alpha: 0.6)),
          _ProfileDetailRow(
            icon: Icons.location_city_outlined,
            label: l10n.homeCity,
            value: display(profile.city),
            valueStyle: t.bodyLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppTheme.borderColor.withValues(alpha: 0.6)),
          _ProfileDetailRow(
            icon: Icons.notes_rounded,
            label: l10n.shortNote,
            value: display(profile.bio),
            maxLines: 5,
            valueStyle: t.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final int maxLines;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _ProfileResponsive.isCompact(context) ? 14 : 18,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppTheme.primaryColor.withValues(alpha: 0.9)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.textTertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: valueStyle ??
                      Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String placeholder;
  final TextInputType? keyboardType;
  final int lines;

  const _FormField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.placeholder,
    this.keyboardType,
    this.lines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        if (lines > 1)
          TextField(
            controller: controller,
            enabled: enabled,
            maxLines: lines,
            decoration: InputDecoration(
              hintText: placeholder,
              filled: true,
              fillColor: enabled
                  ? AppTheme.surfaceColor
                  : AppTheme.surfaceVariant.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          )
        else
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: placeholder,
              filled: true,
              fillColor: enabled
                  ? AppTheme.surfaceColor
                  : AppTheme.surfaceVariant.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String caption;

  const _SectionHeader({required this.title, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 44,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSettings extends StatelessWidget {
  final ProfileProvider profile;
  final LanguageProvider languageProvider;
  final String? authToken;
  /// Logged-in (non-guest): show AI Planner shortcut in settings.
  final bool showAccountLinks;
  /// Server-flagged admins: technical app settings (API URL, SMTP, etc.).
  final bool showTechnicalAppSettings;

  const _ProfileSettings({
    required this.profile,
    required this.languageProvider,
    this.authToken,
    this.showAccountLinks = false,
    this.showTechnicalAppSettings = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final token = authToken;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.settings,
          caption: l10n.languagePrivacyFeedback,
        ),
        const SizedBox(height: 10),
        Container(
          padding:
              EdgeInsets.all(_ProfileResponsive.isCompact(context) ? 14 : 18),
          decoration: _profileCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.language,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.chooseLanguage,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SettingsChip(
                    label: l10n.english,
                    selected: languageProvider.currentLanguage ==
                        AppLanguage.english,
                    onTap: () =>
                        languageProvider.setLanguage(AppLanguage.english),
                  ),
                  _SettingsChip(
                    label: l10n.arabic,
                    selected: languageProvider.currentLanguage ==
                        AppLanguage.arabic,
                    onTap: () =>
                        languageProvider.setLanguage(AppLanguage.arabic),
                  ),
                  _SettingsChip(
                    label: l10n.french,
                    selected: languageProvider.currentLanguage ==
                        AppLanguage.french,
                    onTap: () =>
                        languageProvider.setLanguage(AppLanguage.french),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                l10n.privacyData,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.storedLocally,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.anonymousUsageInfo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n.allowSavingStats,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                    height: 1.35,
                  ),
                ),
                value: profile.analytics,
                onChanged: (v) => profile.setAnalytics(v, authToken: token),
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.primaryColor,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.tipsHelperMessages,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n.showGentleTips,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                    height: 1.35,
                  ),
                ),
                value: profile.showTips,
                onChanged: (v) => profile.setShowTips(v, authToken: token),
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.primaryColor,
              ),
              const SizedBox(height: 8),
              Divider(height: 24, color: AppTheme.borderColor.withValues(alpha: 0.6)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.interests_rounded, color: cs.primary),
                title: Text(
                  l10n.yourInterests,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  l10n.selectInterestsSubtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/profile/interests'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.help_outline_rounded, color: cs.primary),
                title: Text(
                  l10n.help,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  l10n.helpSupportTitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/help'),
              ),
              if (showTechnicalAppSettings)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.settings_rounded, color: cs.primary),
                  title: Text(
                    l10n.openAppSettings,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings'),
                ),
              if (showAccountLinks) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.auto_awesome_rounded, color: cs.primary),
                  title: Text(
                    l10n.tripPlannerProfile,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    l10n.tripPlannerProfileSubtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/ai-planner'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SettingsChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryColor.withValues(alpha: 0.12)
                : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRateCard extends StatelessWidget {
  final ProfileProvider profile;
  final String? authToken;
  final VoidCallback onSendFeedback;

  const _ProfileRateCard({
    required this.profile,
    this.authToken,
    required this.onSendFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = _ProfileResponsive.width(context) < 380;
    return Container(
      padding: EdgeInsets.all(_ProfileResponsive.isCompact(context) ? 14 : 18),
      decoration: _profileCardDecoration(),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.rateTripoliExplorer,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context)!.shareHowItFeels,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    final filled = star <= profile.appRating;
                    return GestureDetector(
                      onTap: () => profile.setAppRating(star, authToken: authToken),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                            filled
                                ? FontAwesomeIcons.solidStar
                                : FontAwesomeIcons.star,
                            size: 20,
                            color: AppTheme.warningColor),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                _rateButton(context),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.rateTripoliExplorer,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.shareHowItFeels,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (i) {
                          final star = i + 1;
                          final filled = star <= profile.appRating;
                          return GestureDetector(
                            onTap: () => profile.setAppRating(star, authToken: authToken),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                filled
                                    ? FontAwesomeIcons.solidStar
                                    : FontAwesomeIcons.star,
                                size: 20,
                                color: AppTheme.warningColor,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                _rateButton(context),
              ],
            ),
    );
  }

  Widget _rateButton(BuildContext context) {
    return TextButton.icon(
      onPressed: onSendFeedback,
      icon: const Icon(FontAwesomeIcons.paperPlane, size: 11),
      label: Text(AppLocalizations.of(context)!.sendCalmFeedback,
          style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _ProfileSessionCard extends StatelessWidget {
  final VoidCallback onLogout;

  const _ProfileSessionCard({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = _ProfileResponsive.width(context) < 400;
    final pad = _ProfileResponsive.isCompact(context) ? 14.0 : 18.0;
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: _profileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.session,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.profileStoredLocally,
            style: TextStyle(
              fontSize: narrow ? 12 : 13,
              height: 1.35,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: narrow ? 14 : 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onLogout,
              icon: const Icon(FontAwesomeIcons.rightFromBracket, size: 16),
              label: Text(l10n.logout),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.surfaceColor,
                foregroundColor: AppTheme.textPrimary,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: narrow ? 16 : 20,
                  vertical: narrow ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.borderColor, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileListSheet extends StatelessWidget {
  final String title;
  final bool isEmpty;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const _ProfileListSheet({
    required this.title,
    required this.isEmpty,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              _ProfileResponsive.horizontalPadding(context),
              16,
              _ProfileResponsive.horizontalPadding(context),
              12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surfaceVariant,
                    minimumSize: const Size(44, 44),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(emptyIcon, size: 64, color: AppTheme.textTertiary),
                        const SizedBox(height: 16),
                        Text(emptyTitle,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        Text(emptySubtitle,
                            style: const TextStyle(
                                fontSize: 14, color: AppTheme.textTertiary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(
                        _ProfileResponsive.horizontalPadding(context)),
                    itemCount: itemCount,
                    itemBuilder: itemBuilder,
                  ),
          ),
        ],
      ),
    );
  }
}
