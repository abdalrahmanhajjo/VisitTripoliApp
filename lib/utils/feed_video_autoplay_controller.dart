import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Picks at most one feed video to autoplay (highest visible fraction).
/// Reduces network/CPU vs playing every inline video at once.
class FeedVideoAutoplayController extends ChangeNotifier {
  FeedVideoAutoplayController();

  /// Minimum visible fraction of the video cell to be a candidate.
  /// Slightly strict so only one reel is "winning" while scrolling (less flip-flop / decode work).
  static const double minVisibleFraction = 0.45;

  final Map<String, double> _visibility = <String, double>{};
  String? _activeId;

  String? get activePostId => _activeId;

  bool isActive(String postId) => _activeId == postId;

  bool _scheduled = false;

  /// Drop tracking for posts that are no longer in the list (refresh / tab change).
  void retainOnly(Set<String> allowedVideoPostIds) {
    final removed = _visibility.keys.where((id) => !allowedVideoPostIds.contains(id)).toList();
    if (removed.isEmpty) return;
    for (final id in removed) {
      _visibility.remove(id);
    }
    _scheduleResolve();
  }

  void report(String postId, VisibilityInfo info) {
    final f = info.visibleFraction;
    if (f < 0.008) {
      _visibility.remove(postId);
    } else {
      _visibility[postId] = f;
    }
    _scheduleResolve();
  }

  void _scheduleResolve() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      _resolve();
    });
  }

  void _resolve() {
    String? bestId;
    var bestF = -1.0;
    for (final e in _visibility.entries) {
      if (e.value < minVisibleFraction) continue;
      if (e.value > bestF) {
        bestF = e.value;
        bestId = e.key;
      }
    }
    if (bestId != _activeId) {
      _activeId = bestId;
      notifyListeners();
    }
  }

  /// Clear all state (e.g. leaving Community).
  void reset() {
    _visibility.clear();
    if (_activeId != null) {
      _activeId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _visibility.clear();
    _activeId = null;
    super.dispose();
  }
}
