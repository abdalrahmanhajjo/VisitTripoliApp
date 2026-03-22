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
import '../providers/trips_provider.dart';
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

    final hp = _ProfileResponsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        top: false,
        bottom: true,
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
                padding: EdgeInsets.fromLTRB(hp, 0, hp, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -36),
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
                    savedPlaces: savedCount,
                    onTripsTap: () => _showTripsModal(context),
                    onSavedTap: () => _showSavedPlacesModal(context),
                  ),
                  if (auth.isLoggedIn && !auth.isGuest) ...[
                    SizedBox(height: _ProfileResponsive.sectionGap(context)),
                    _ProfileBadgesSection(authToken: auth.authToken!),
                    SizedBox(height: _ProfileResponsive.sectionGap(context)),
                    _ProfileBookingsSection(authToken: auth.authToken!),
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
                    onTripPreferences: auth.isLoggedIn && !auth.isGuest
                        ? () => _showTripPreferencesDialog(profile, auth.authToken)
                        : null,
                  ),
                  SizedBox(height: _ProfileResponsive.sectionGap(context)),
                  _ProfileRateCard(
                    profile: profile,
                    authToken: auth.isGuest ? null : auth.authToken,
                    onSendFeedback: () => _sendFeedbackEmail(profile),
                  ),
                  SizedBox(height: _ProfileResponsive.sectionGap(context)),
                    _ProfileSessionCard(
                      onClear: () => _showClearProfileDialog(context, profile),
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

  String _normalizeMoodKey(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('chill')) return 'chill';
    if (s.contains('historical')) return 'historical';
    if (s.contains('food')) return 'food';
    return 'mixed';
  }

  String _normalizePaceKey(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('light')) return 'light';
    if (s.contains('full')) return 'full';
    return 'normal';
  }

  Future<void> _showTripPreferencesDialog(
    ProfileProvider profile,
    String? authToken,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    var mood = _normalizeMoodKey(profile.mood);
    var pace = _normalizePaceKey(profile.pace);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(l10n.editTripPreferences),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.mood,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButton<String>(
                  value: mood,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'mixed', child: Text(l10n.mixedBalanced)),
                    DropdownMenuItem(value: 'chill', child: Text(l10n.chillSlow)),
                    DropdownMenuItem(value: 'historical', child: Text(l10n.historicalCultural)),
                    DropdownMenuItem(value: 'food', child: Text(l10n.foodCafes)),
                  ],
                  onChanged: (v) => setSt(() => mood = v ?? mood),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.pace,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButton<String>(
                  value: pace,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'light', child: Text(l10n.lightEasy)),
                    DropdownMenuItem(value: 'normal', child: Text(l10n.normalPace)),
                    DropdownMenuItem(value: 'full', child: Text(l10n.fullButCalm)),
                  ],
                  onChanged: (v) => setSt(() => pace = v ?? pace),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.saveChanges),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;
    final ok = await profile.updateProfile(
      mood: mood,
      pace: pace,
      authToken: authToken,
    );
    if (mounted) {
      _showToast(
        context,
        ok ? l10n.tripPreferencesSaved : 'Failed to save. Check connection.',
      );
    }
  }

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

  void _showClearProfileDialog(BuildContext context, ProfileProvider profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearProfileTitle),
        content: Text(AppLocalizations.of(context)!.clearProfileMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final avatarPath = profile.avatarLocalPath;
              await profile.clearProfile();
              clearProfileAvatarFromDevice(avatarPath.isNotEmpty ? avatarPath : null);
              if (context.mounted) {
                Navigator.pop(ctx);
                _showToast(
                    context, AppLocalizations.of(context)!.localProfileReset);
              }
            },
            child: Text(AppLocalizations.of(context)!.clear,
                style: const TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _showSavedPlacesModal(BuildContext context) {
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    final saved = placesProvider.savedPlaces;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileListSheet(
        title: AppLocalizations.of(context)!.savedPlaces,
        isEmpty: saved.isEmpty,
        emptyIcon: FontAwesomeIcons.heart,
        emptyTitle: AppLocalizations.of(context)!.noSavedPlaces,
        emptySubtitle: AppLocalizations.of(context)!.favoritesAndTripPlaces,
        itemCount: saved.length,
        itemBuilder: (context, index) {
          final p = saved[index];
          return ListTile(
            leading: p.images.isNotEmpty
                ? SizedBox(
                    width: 48,
                    height: 48,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppImage(
                        src: p.images.first,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholderIcon(48),
                      ),
                    ),
                  )
                : _placeholderIcon(48),
            title: Text(p.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(p.location),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/place/${p.id}');
            },
          );
        },
      ),
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(4, topInset + 8, hp, 44),
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
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.6,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.profileScreenSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileAvatar(context, profile, 88),
              const SizedBox(width: 24),
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
          const SizedBox(height: 18),
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

class _ProfileBadgesSection extends StatefulWidget {
  final String authToken;

  const _ProfileBadgesSection({required this.authToken});

  @override
  State<_ProfileBadgesSection> createState() => _ProfileBadgesSectionState();
}

class _ProfileBadgesSectionState extends State<_ProfileBadgesSection> {
  List<dynamic> _badges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.instance.getMyBadges(widget.authToken);
      if (mounted) {
        setState(() {
          _badges = res['badges'] is List ? res['badges'] as List : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _profileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.trophy, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.myBadges,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))))
          else if (_badges.isEmpty)
            Text(AppLocalizations.of(context)!.badgesEmptyHint,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _badges.map<Widget>((b) {
                final name = b['name'] as String? ?? '';
                final icon = b['icon'] as String? ?? 'star';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_iconForName(icon), size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  IconData _iconForName(String name) {
    switch (name) {
      case 'place': return Icons.place;
      case 'explore': return Icons.explore;
      case 'hiking': return Icons.hiking;
      case 'restaurant': return Icons.restaurant;
      case 'museum': return Icons.museum;
      case 'route': return Icons.route;
      case 'people': return Icons.people;
      default: return Icons.star;
    }
  }
}

class _ProfileBookingsSection extends StatefulWidget {
  final String authToken;

  const _ProfileBookingsSection({required this.authToken});

  @override
  State<_ProfileBookingsSection> createState() => _ProfileBookingsSectionState();
}

class _ProfileBookingsSectionState extends State<_ProfileBookingsSection> {
  List<dynamic> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.instance.getBookings(widget.authToken);
      if (mounted) {
        setState(() {
          _bookings = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _profileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.calendarCheck, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.myBookings,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))))
          else if (_bookings.isEmpty)
            Text(AppLocalizations.of(context)!.bookingsEmptyHint,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4))
          else
            ..._bookings.take(5).map((b) {
              final placeName = b['place_name'] as String? ?? 'Place';
              final date = b['booking_date'] as String? ?? '';
              final status = b['status'] as String? ?? 'pending';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  ),
                  title: Text(placeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('$date • $status'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    final placeId = b['place_id'] as String?;
                    if (placeId != null) context.push('/place/$placeId');
                  },
                ),
              );
            }),
        ],
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
  final int savedPlaces;
  final VoidCallback onTripsTap;
  final VoidCallback onSavedTap;

  const _ProfileStats({
    required this.trips,
    required this.savedPlaces,
    required this.onTripsTap,
    required this.onSavedTap,
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
            label: AppLocalizations.of(context)!.savedPlaces,
            value: savedPlaces.toString(),
            meta: AppLocalizations.of(context)!.favoritesAndTripPlaces,
            onTap: onSavedTap,
          ),
        ),
      ],
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
    final child = Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: EdgeInsets.all(compact ? 14 : 16),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppTheme.textTertiary.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
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
            style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary, height: 1.25),
            maxLines: 2,
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
  final VoidCallback? onTripPreferences;

  const _ProfileSettings({
    required this.profile,
    required this.languageProvider,
    this.authToken,
    this.onTripPreferences,
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
              if (onTripPreferences != null) ...[
                const SizedBox(height: 8),
                Divider(height: 24, color: AppTheme.borderColor.withValues(alpha: 0.6)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.tune_rounded, color: cs.primary),
                  title: Text(
                    l10n.editTripPreferences,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    l10n.usedByAiPlanner,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: onTripPreferences,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _SectionHeader(
          title: l10n.profileMoreSection,
          caption: l10n.profileMoreSectionCaption,
        ),
        const SizedBox(height: 10),
        Container(
          decoration: _profileCardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _ProfileNavTile(
                icon: Icons.settings_rounded,
                title: l10n.openAppSettings,
                onTap: () => context.push('/settings'),
              ),
              Divider(height: 1, color: AppTheme.borderColor.withValues(alpha: 0.6)),
              _ProfileNavTile(
                icon: Icons.help_outline_rounded,
                title: l10n.help,
                onTap: () => context.push('/help'),
              ),
              Divider(height: 1, color: AppTheme.borderColor.withValues(alpha: 0.6)),
              _ProfileNavTile(
                icon: Icons.info_outline_rounded,
                title: l10n.about,
                onTap: () => context.push('/about'),
              ),
              if (token != null && token.isNotEmpty) ...[
                Divider(height: 1, color: AppTheme.borderColor.withValues(alpha: 0.6)),
                _ProfileNavTile(
                  icon: Icons.auto_awesome_rounded,
                  title: l10n.tripPlannerProfile,
                  subtitle: l10n.tripPlannerProfileSubtitle,
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

class _ProfileNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileNavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: subtitle != null && subtitle!.isNotEmpty
          ? Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
      onTap: onTap,
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
  final VoidCallback onClear;
  final VoidCallback onLogout;

  const _ProfileSessionCard({required this.onClear, required this.onLogout});

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
                Text(AppLocalizations.of(context)!.session,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context)!.profileStoredLocally,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _clearButton(context),
                    const SizedBox(width: 8),
                    _logoutButton(context),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.session,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.profileStoredLocally,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                _clearButton(context),
                const SizedBox(width: 8),
                _logoutButton(context),
              ],
            ),
    );
  }

  Widget _clearButton(BuildContext context) {
    return TextButton.icon(
      onPressed: onClear,
      icon: const Icon(FontAwesomeIcons.trash,
          size: 14, color: AppTheme.errorColor),
      label: Text(AppLocalizations.of(context)!.clearLocalProfile,
          style: const TextStyle(fontSize: 12, color: AppTheme.errorColor)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return TextButton.icon(
      onPressed: onLogout,
      icon: const Icon(FontAwesomeIcons.rightFromBracket,
          size: 14, color: AppTheme.textPrimary),
      label: Text(AppLocalizations.of(context)!.logout,
          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
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
