import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripoli_explorer/l10n/app_localizations.dart';
import 'providers/app_state.dart';
import 'providers/auth_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/events_provider.dart';
import 'providers/interests_provider.dart';
import 'providers/language_provider.dart';
import 'providers/map_provider.dart';
import 'providers/places_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/tours_provider.dart';
import 'providers/trips_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/activity_log_provider.dart';
import 'providers/connectivity_provider.dart';
import 'config/api_config.dart';
import 'routes/app_router.dart';
import 'services/api_service.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';
import 'package:showcaseview/showcaseview.dart';
import 'utils/app_text_scale.dart';
import 'utils/feed_media_precache.dart';
import 'utils/places_image_precache.dart';
import 'utils/perf_trace.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PerfTrace.mark('main.start');
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // Tune image cache: limit count and bytes for smooth lists without excessive memory.
  PaintingBinding.instance.imageCache
    ..maximumSize = 200
    ..maximumSizeBytes = 200 << 20; // 200 MB

  final prefs = await PerfTrace.timeAsync('prefs.load', SharedPreferences.getInstance);
  await PerfTrace.timeAsync('apiConfig.loadOverride', () => ApiConfig.loadOverride(prefs));
  final auth = AuthProvider(prefs);
  // Set API locale before data providers load so places/categories/etc. are translated from first load.
  final languageProvider = LanguageProvider(prefs);
  ApiService.instance.setLocale(languageProvider.currentLanguage.code);

  final places = PlacesProvider();
  final categories = CategoriesProvider();
  final tours = ToursProvider();
  final events = EventsProvider();
  final interests = InterestsProvider();

  final profile = ProfileProvider(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: places),
        ChangeNotifierProvider(
            create: (context) => TripsProvider(
                prefs, Provider.of<AuthProvider>(context, listen: false))),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider.value(value: categories),
        ChangeNotifierProvider.value(value: tours),
        ChangeNotifierProvider.value(value: events),
        ChangeNotifierProvider.value(value: interests),
        ChangeNotifierProvider.value(value: profile),
        ChangeNotifierProvider(create: (_) => ActivityLogProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityNotifier()),
      ],
      child: _ProfileAccountSync(
        child: TripoliExplorerApp(authProvider: auth),
      ),
    ),
  );
  PerfTrace.mark('main.runApp');

  // Defer non-critical startup work until after first frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PerfTrace.timeAsync('profile.initializeForAuth', () {
      return profile.initializeForAuth(
        userId: auth.userId,
        isGuest: auth.isGuest,
      );
    });
    bindAuthForPushNotifications(auth);
    PerfTrace.timeAsync('push.initialize', initializePushNotifications);
  });
}

/// Keeps [ProfileProvider] in sync with the signed-in account so avatars and prefs are per-user.
class _ProfileAccountSync extends StatefulWidget {
  const _ProfileAccountSync({required this.child});

  final Widget child;

  @override
  State<_ProfileAccountSync> createState() => _ProfileAccountSyncState();
}

class _ProfileAccountSyncState extends State<_ProfileAccountSync> {
  String? _lastAccountKey;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final key = '${auth.isGuest}:${auth.userId ?? ''}';
    if (_lastAccountKey != key) {
      _lastAccountKey = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ProfileProvider>().setAccountContext(
              userId: auth.userId,
              isGuest: auth.isGuest,
            );
        context.read<PlacesProvider>().loadSavedPlacesForCurrentUser(
              authToken: auth.authToken,
              isGuest: auth.isGuest,
            );
      });
    }
    return widget.child;
  }
}

class TripoliExplorerApp extends StatefulWidget {
  const TripoliExplorerApp({super.key, required this.authProvider});

  final AuthProvider authProvider;

  @override
  State<TripoliExplorerApp> createState() => _TripoliExplorerAppState();
}

class _TripoliExplorerAppState extends State<TripoliExplorerApp> {
  late final GoRouter _router;
  String? _lastLangCode;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(widget.authProvider);
    widget.authProvider.addListener(_onAuthChangedForPush);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      syncPushTokenWithAuth(widget.authProvider);
    });
  }

  @override
  void dispose() {
    widget.authProvider.removeListener(_onAuthChangedForPush);
    super.dispose();
  }

  void _onAuthChangedForPush() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      syncPushTokenWithAuth(widget.authProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, ConnectivityNotifier>(
      builder: (context, languageProvider, connectivity, child) {
        final code = languageProvider.currentLanguage.code;
        final prevCode = _lastLangCode;
        _lastLangCode = code;
        ApiService.instance.setLocale(code);
        if (prevCode != null && prevCode != code) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            try {
              final auth = context.read<AuthProvider>();
              context
                  .read<PlacesProvider>()
                  .loadPlaces(forceRefresh: true, locale: code);
              context
                  .read<CategoriesProvider>()
                  .loadCategories(forceRefresh: true, locale: code);
              context
                  .read<ToursProvider>()
                  .loadTours(forceRefresh: true, locale: code);
              context
                  .read<EventsProvider>()
                  .loadEvents(forceRefresh: true, locale: code);
              context
                  .read<InterestsProvider>()
                  .loadInterests(forceRefresh: true, locale: code);
              context.read<PlacesProvider>().loadSavedPlacesForCurrentUser(
                    authToken: auth.authToken,
                    isGuest: auth.isGuest,
                  );
              // Feed/reels: place names come from DB translations; reload so UI matches language.
              context.read<FeedProvider>().loadFeed(
                    authToken: auth.authToken,
                    refresh: true,
                  );
              context.read<FeedProvider>().loadReels(
                    authToken: auth.authToken,
                    refresh: true,
                  );
            } catch (_) {}
          });
        }
        return MaterialApp.router(
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)?.appTitle ?? 'Visit Tripoli',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: languageProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
            Locale('fr'),
          ],
          routerConfig: _router,
          // Lighthouse a11y: ensure app root has semantic label and is treated as main content
          builder: (context, child) {
            final l10n = AppLocalizations.of(context);
            final offline = connectivity.isOffline;
            final stack = Stack(
              clipBehavior: Clip.none,
              children: [
                child ?? const SizedBox.shrink(),
                if (offline)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Material(
                      elevation: 4,
                      color: const Color(0xFFB45309),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n?.offlineBannerMessage ??
                                      'No internet — you can still browse saved content.',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
            return _FeedWarmup(
              child: _ShowcaseScope(
                child: Semantics(
                  container: true,
                  label: l10n?.appRootSemanticsLabel ??
                      'Visit Tripoli - Explore places, tours and plan your trip',
                  child: applyAppTextScale(context, stack),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Registers [ShowcaseView] for app-wide coach marks (replaces deprecated [ShowCaseWidget]).
class _ShowcaseScope extends StatefulWidget {
  const _ShowcaseScope({required this.child});

  final Widget child;

  @override
  State<_ShowcaseScope> createState() => _ShowcaseScopeState();
}

class _ShowcaseScopeState extends State<_ShowcaseScope> {
  late final ShowcaseView _view;

  @override
  void initState() {
    super.initState();
    _view = ShowcaseView.register(
      enableAutoScroll: true,
    );
  }

  @override
  void dispose() {
    _view.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Starts Discover feed fetch on app launch and precaches first images so the feed feels instant.
class _FeedWarmup extends StatefulWidget {
  const _FeedWarmup({required this.child});

  final Widget child;

  @override
  State<_FeedWarmup> createState() => _FeedWarmupState();
}

class _FeedWarmupState extends State<_FeedWarmup> {
  bool _kickScheduled = false;
  bool _precachedFirstPage = false;
  bool _precachedPlacesImages = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _kickFeedPrefetch();
    });
  }

  void _kickFeedPrefetch() {
    if (_kickScheduled) return;
    final feed = context.read<FeedProvider>();
    final auth = context.read<AuthProvider>();
    if (feed.posts.isNotEmpty || feed.loading) return;
    _kickScheduled = true;
    feed.loadFeed(authToken: auth.authToken, refresh: false, sort: 'recent');
    if (auth.isLoggedIn && !auth.isGuest && auth.authToken != null) {
      feed.loadCanPost(auth.authToken!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedProvider>();
    final places = context.watch<PlacesProvider>();
    if (!_precachedFirstPage &&
        feed.posts.isNotEmpty &&
        !feed.loading) {
      _precachedFirstPage = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        scheduleFeedMediaPrecache(context, feed.posts);
      });
    }
    if (!_precachedPlacesImages &&
        places.places.isNotEmpty &&
        !places.isLoading) {
      _precachedPlacesImages = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        schedulePlacesImagePrecache(context, places.places);
      });
    }
    return widget.child;
  }
}
