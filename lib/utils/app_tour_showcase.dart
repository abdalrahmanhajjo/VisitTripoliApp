import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import '../providers/app_tour_segment.dart';
import '../providers/app_state.dart';
import '../providers/auth_provider.dart';
import 'app_tutorial_prefs.dart';

/// Runs a Showcase sequence; optionally advances the full multi-page tour.
void startAppTourShowcase({
  required BuildContext context,
  required List<GlobalKey> keys,
  required SharedPreferences prefs,
  /// When non-null and [AppStateProvider.isFullAppTourActive], advances to the next tab/route.
  AppTourSegment? advanceFromSegment,
}) {
  if (keys.isEmpty || !context.mounted) return;
  final ShowcaseView view;
  try {
    view = ShowcaseView.get();
  } catch (_) {
    return;
  }
  var finished = false;
  late void Function() onFinish;
  late void Function(GlobalKey?) onDismiss;

  void complete() {
    if (finished) return;
    finished = true;
    view.removeOnFinishCallback(onFinish);
    view.removeOnDismissCallback(onDismiss);
  }

  onFinish = () {
    complete();
    _afterTourStep(context, prefs, advanceFromSegment);
  };

  onDismiss = (GlobalKey? _) {
    complete();
    _afterTourStep(context, prefs, advanceFromSegment);
  };

  view.addOnFinishCallback(onFinish);
  view.addOnDismissCallback(onDismiss);
  view.startShowCase(
    keys,
    delay: const Duration(milliseconds: 400),
  );
}

void _afterTourStep(
  BuildContext context,
  SharedPreferences prefs,
  AppTourSegment? advanceFromSegment,
) {
  if (!context.mounted) return;
  final appState = context.read<AppStateProvider>();
  final auth = context.read<AuthProvider>();

  final fullTour = appState.isFullAppTourActive && advanceFromSegment != null;
  if (!fullTour) {
    AppTutorialPrefs.markResolved(prefs);
    return;
  }

  final next = appState.advanceFullTourAfter(advanceFromSegment,
      isGuest: auth.isGuest);
  if (!appState.isFullAppTourActive) {
    AppTutorialPrefs.markResolved(prefs);
  }
  if (next != null) {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (context.mounted) context.go(next);
    });
  }
}
