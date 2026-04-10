import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tripoli_explorer/l10n/app_localizations.dart';
import '../providers/activity_log_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/feedback_utils.dart';
import 'themed_showcase.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, this.currentIndex = 0});

  static const _guestRestrictedIndices = {3, 4}; // AI Planner, Trips

  static final GlobalKey exploreKey = GlobalKey();
  static final GlobalKey communityKey = GlobalKey();
  static final GlobalKey mapKey = GlobalKey();
  static final GlobalKey aiPlannerKey = GlobalKey();
  static final GlobalKey tripsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context);
    final isGuest = auth.isGuest;

    return SafeArea(
      child: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        selectedIndex: currentIndex.clamp(0, 4),
        onDestinationSelected: (index) {
            AppFeedback.selection();
            if (isGuest && _guestRestrictedIndices.contains(index)) {
              final router = GoRouter.of(context);
              final message =
                  index == 3 ? l10n.signInToAccessAi : l10n.signInToAccessTrips;
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.loginRequired),
                  content: Text(message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        router.go('/login');
                      },
                      child: Text(l10n.signIn),
                    ),
                  ],
                ),
              );
              return;
            }
            final activityLog =
                Provider.of<ActivityLogProvider>(context, listen: false);
            final tabLabels = [
              l10n.navExplore,
              l10n.navCommunity,
              l10n.navMap,
              l10n.navAiPlanner,
              l10n.navTrips,
            ];
            if (index >= 0 && index < tabLabels.length) {
              activityLog.tabVisited(tabLabels[index]);
            }
            switch (index) {
              case 0:
                context.go('/explore');
                break;
              case 1:
                context.go('/community');
                break;
              case 2:
                context.go('/map');
                break;
              case 3:
                context.go('/ai-planner');
                break;
              case 4:
                context.go('/trips');
                break;
            }
        },
        destinations: [
            ThemedShowcase(
              showcaseKey: exploreKey,
              title: l10n.navExplore,
              description: l10n.appTutorialNavExploreDesc,
              child: NavigationDestination(
                icon: const Icon(Icons.explore_outlined),
                selectedIcon: const Icon(Icons.explore),
                label: l10n.navExplore,
              ),
            ),
            ThemedShowcase(
              showcaseKey: communityKey,
              title: l10n.navCommunity,
              description: l10n.appTutorialNavCommunityDesc,
              child: NavigationDestination(
                icon: const Icon(Icons.dynamic_feed_outlined),
                selectedIcon: const Icon(Icons.dynamic_feed_rounded),
                label: l10n.navCommunity,
              ),
            ),
            ThemedShowcase(
              showcaseKey: mapKey,
              title: l10n.navMap,
              description: l10n.appTutorialNavMapDesc,
              child: NavigationDestination(
                icon: const Icon(Icons.map_outlined),
                selectedIcon: const Icon(Icons.map),
                label: l10n.navMap,
              ),
            ),
            ThemedShowcase(
              showcaseKey: aiPlannerKey,
              title: l10n.navAiPlanner,
              description: l10n.appTutorialNavAiDesc,
              child: NavigationDestination(
                icon: const Icon(Icons.auto_awesome_outlined),
                selectedIcon: const Icon(Icons.auto_awesome),
                label: l10n.navAiPlanner,
              ),
            ),
            ThemedShowcase(
              showcaseKey: tripsKey,
              title: l10n.navTrips,
              description: l10n.appTutorialNavTripsDesc,
              child: NavigationDestination(
                icon: const Icon(Icons.route_outlined),
                selectedIcon: const Icon(Icons.route),
                label: l10n.navTrips,
              ),
            ),
        ],
      ),
    );
  }
}
