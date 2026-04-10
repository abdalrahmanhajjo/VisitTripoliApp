import 'package:flutter/foundation.dart';

import 'app_tour_segment.dart';

class AppStateProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _pendingTutorialSpotlight = false;

  bool _fullAppTourActive = false;
  AppTourSegment? _tourSegment;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isFullAppTourActive => _fullAppTourActive;
  AppTourSegment? get activeTourSegment => _tourSegment;

  /// Multi-page spotlight: Explore → Community → Map → (AI → Trips if signed in).
  void startFullAppTour() {
    _fullAppTourActive = true;
    _tourSegment = AppTourSegment.explore;
    _pendingTutorialSpotlight = false;
    notifyListeners();
  }

  void endFullAppTour() {
    _fullAppTourActive = false;
    _tourSegment = null;
    notifyListeners();
  }

  String? advanceFullTourAfter(
    AppTourSegment completed, {
    required bool isGuest,
  }) {
    if (!_fullAppTourActive || _tourSegment != completed) return null;
    switch (completed) {
      case AppTourSegment.explore:
        _tourSegment = AppTourSegment.community;
        notifyListeners();
        return '/community';
      case AppTourSegment.community:
        _tourSegment = AppTourSegment.map;
        notifyListeners();
        return '/map';
      case AppTourSegment.map:
        if (isGuest) {
          endFullAppTour();
          return '/explore';
        }
        _tourSegment = AppTourSegment.aiPlanner;
        notifyListeners();
        return '/ai-planner';
      case AppTourSegment.aiPlanner:
        _tourSegment = AppTourSegment.trips;
        notifyListeners();
        return '/trips';
      case AppTourSegment.trips:
        endFullAppTour();
        return '/explore';
    }
  }

  /// After [requestTutorialSpotlight], Explore consumes this and runs Showcase (Explore only).
  bool consumeTutorialSpotlightIfPending() {
    if (!_pendingTutorialSpotlight) return false;
    _pendingTutorialSpotlight = false;
    notifyListeners();
    return true;
  }

  /// Help → “Screen highlights only”: Explore page coach marks only.
  void requestTutorialSpotlight() {
    _pendingTutorialSpotlight = true;
    endFullAppTour();
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
