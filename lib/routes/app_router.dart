import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/about_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/ai_planner_screen.dart';
import '../screens/community_screen.dart';
import '../screens/deals_screen.dart';
import '../screens/email_config_screen.dart';
import '../screens/event_detail_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/help_screen.dart';
import '../screens/interests_screen.dart';
import '../screens/intro_screen.dart';
import '../screens/language_selection_screen.dart';
import '../screens/login_screen.dart';
import '../screens/map_screen.dart';
import '../screens/place_details_screen.dart';
import '../screens/place_posts_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/proposals_screen.dart';
import '../screens/reels_screen.dart';
import '../screens/register_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tour_detail_screen.dart';
import '../screens/trips_screen.dart';
import '../screens/verify_email_screen.dart';

class AppRouter {
  static const _publicPaths = [
    '/intro',
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
    '/verify-email',
    '/settings/email',
    '/explore', // Tours, places, events visible to all without login
    '/place/',
    '/tour/',
    '/event/',
    '/map',
    '/community',
    '/deals',
  ];
  static const _guestRestrictedPaths = ['/trips', '/profile', '/ai-planner'];

  /// Paths that are valid app routes; used to preserve URL on refresh (e.g. stay on /profile).
  static bool _isAppPath(String path) {
    if (path.isEmpty || path == '/') return false;
    const validPrefixes = [
      '/intro',
      '/login',
      '/register',
      '/forgot-password',
      '/reset-password',
      '/verify-email',
      '/language',
      '/interests',
      '/explore',
      '/profile',
      '/profile/interests',
      '/trips',
      '/community',
      '/map',
      '/ai-planner',
      '/deals',
      '/settings',
      '/help',
      '/about',
      '/admin',
      '/place/',
      '/tour/',
      '/event/',
    ];
    return validPrefixes
        .any((p) => path == p || (p.endsWith('/') && path.startsWith(p)));
  }

  static String _initialLocation(AuthProvider auth) {
    // On refresh (e.g. web), keep current URL so user stays on profile/trips/explore/etc.
    if (kIsWeb) {
      // Flutter web commonly uses hash routing (/#/route). In that case, the real route
      // is stored in Uri.base.fragment and Uri.base.path is just "/".
      final fragment = Uri.base.fragment;
      if (fragment.startsWith('/')) {
        final fragUri = Uri.parse(fragment);
        if (_isAppPath(fragUri.path)) return fragment;
      }

      final path = Uri.base.path;
      final query = Uri.base.query;
      final loc = path + (query.isEmpty ? '' : '?$query');
      if (_isAppPath(path)) return loc;
    }
    return auth.isLoggedIn
        ? (auth.onboardingCompleted ? '/explore' : '/language')
        : '/intro';
  }

  static GoRouter createRouter(AuthProvider auth) {
    return GoRouter(
      refreshListenable: auth,
      initialLocation: _initialLocation(auth),
      redirect: (context, state) {
        final path = state.uri.path;
        if (path == '/' || path.isEmpty) return '/intro';
        final isPublic = _publicPaths.contains(path) ||
            _publicPaths.any((p) => p.endsWith('/') && path.startsWith(p));
        final isLoggedIn = auth.isLoggedIn;
        final isGuest = auth.isGuest;
        if (!isLoggedIn && !isPublic) {
          // When URL is /profile alone, send to login then back to profile after auth
          if (path == '/profile' || path.startsWith('/profile')) {
            return '/login?redirect=${Uri.encodeComponent('/profile')}';
          }
          return '/login';
        }
        // Only redirect away from login/register/intro when fully logged in (not guest)
        if (isLoggedIn &&
            !isGuest &&
            (path == '/login' || path == '/register' || path == '/intro')) {
          if (auth.needsEmailVerification) return '/verify-email';
          return auth.onboardingCompleted ? '/explore' : '/language';
        }
        if (auth.needsEmailVerification &&
            path != '/verify-email' &&
            path != '/login') {
          return '/verify-email';
        }
        if (isGuest && _guestRestrictedPaths.any((p) => path.startsWith(p))) {
          return '/login';
        }
        // Users who already completed onboarding skip language/interests (only once)
        if (isLoggedIn &&
            auth.onboardingCompleted &&
            (path == '/language' || path == '/interests')) {
          return '/explore';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/intro',
          builder: (context, state) => const IntroScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final token = state.uri.queryParameters['token'];
            return ResetPasswordScreen(token: token);
          },
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: '/language',
          builder: (context, state) => const LanguageSelectionScreen(),
        ),
        GoRoute(
          path: '/interests',
          builder: (context, state) => const InterestsScreen(),
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) {
            final showWelcome = state.uri.queryParameters['welcome'] == '1';
            return ExploreScreen(
              showWelcome: showWelcome,
              openEventsSheet: false,
            );
          },
        ),
        GoRoute(
          path: '/place/:id/posts',
          builder: (context, state) {
            final placeId = state.pathParameters['id']!;
            return PlacePostsScreen(placeId: placeId);
          },
        ),
        GoRoute(
          path: '/place/:id',
          builder: (context, state) {
            final placeId = state.pathParameters['id']!;
            return PlaceDetailsScreen(placeId: placeId);
          },
        ),
        GoRoute(
          path: '/trips',
          builder: (context, state) => const TripsScreen(),
        ),
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
        ),
        GoRoute(
          path: '/community/reels',
          builder: (context, state) {
            final postId = state.uri.queryParameters['postId'];
            return ReelsScreen(initialPostId: postId);
          },
        ),
        GoRoute(
          path: '/proposals',
          builder: (context, state) => const ProposalsScreen(),
        ),
        GoRoute(
          path: '/deals',
          builder: (context, state) => const DealsScreen(),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => MapScreen(
            queryParams: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: '/ai-planner',
          builder: (context, state) => const AIPlannerScreen(),
        ),
        GoRoute(
          path: '/profile/interests',
          builder: (context, state) =>
              const InterestsScreen(profileEditMode: true),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/tour/:id',
          builder: (context, state) {
            final tourId = state.pathParameters['id']!;
            return TourDetailScreen(tourId: tourId);
          },
        ),
        GoRoute(
          path: '/event/:id',
          builder: (context, state) {
            final eventId = state.pathParameters['id']!;
            return EventDetailScreen(eventId: eventId);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/settings/email',
          builder: (context, state) => const EmailConfigScreen(),
        ),
        GoRoute(
          path: '/help',
          builder: (context, state) => const HelpScreen(),
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
      ],
    );
  }
}
