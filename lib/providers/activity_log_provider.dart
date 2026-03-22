import 'package:flutter/foundation.dart';

/// Single activity event for AI context.
class ActivityEvent {
  final String type;
  final String label;
  final DateTime at;

  const ActivityEvent({
    required this.type,
    required this.label,
    required this.at,
  });
}

/// Logs in-app user activity so the AI can personalize recommendations.
/// Keeps last [maxEvents]; summary is injected into the planner prompt.
class ActivityLogProvider extends ChangeNotifier {
  ActivityLogProvider() : _maxEvents = 120;

  final int _maxEvents;
  final List<ActivityEvent> _events = [];

  List<ActivityEvent> get events => List.unmodifiable(_events);

  /// Remove event by index (for edit UI). Index 0 = oldest.
  void removeAt(int index) {
    if (index < 0 || index >= _events.length) return;
    _events.removeAt(index);
    notifyListeners();
  }

  /// Clear all events.
  void clear() {
    _events.clear();
    notifyListeners();
  }

  void _add(String type, String label) {
    _events.add(ActivityEvent(type: type, label: label, at: DateTime.now()));
    if (_events.length > _maxEvents) {
      _events.removeRange(0, _events.length - _maxEvents);
    }
    notifyListeners();
  }

  void placeViewed(String placeId, String placeName) {
    _add('place_viewed', '$placeName ($placeId)');
  }

  void categoryBrowsed(String categoryId, String categoryName) {
    _add('category_browsed', categoryName);
  }

  void search(String query) {
    if (query.trim().isEmpty) return;
    _add('search', query.trim());
  }

  void tabVisited(String tabName) {
    _add('tab_visited', tabName);
  }

  void plannerThemeSelected(String themeLabel) {
    _add('planner_theme', themeLabel);
  }

  void plannerRun(String promptSummary) {
    _add('planner_run', promptSummary);
  }

  void tripSaved(List<String> placeNames) {
    if (placeNames.isEmpty) return;
    _add('trip_saved', placeNames.take(8).join(', '));
  }

  void interestsSelected(List<String> interestNames) {
    if (interestNames.isEmpty) return;
    _add('interests', interestNames.take(10).join(', '));
  }

  void placeSaved(String placeName) {
    _add('place_saved', placeName);
  }

  void placeUnsaved(String placeName) {
    _add('place_unsaved', placeName);
  }

  void tourSaved(String tourName) {
    _add('tour_saved', tourName);
  }

  void tourUnsaved(String tourName) {
    _add('tour_unsaved', tourName);
  }

  void eventSaved(String eventName) {
    _add('event_saved', eventName);
  }

  void eventUnsaved(String eventName) {
    _add('event_unsaved', eventName);
  }

  void filterUsed(String filterLabel) {
    _add('filter_used', filterLabel);
  }

  void directionsRequested(String destinationName) {
    _add('directions', destinationName);
  }

  void shared(String what) {
    _add('shared', what);
  }

  void bookingStarted(String placeName) {
    _add('booking', placeName);
  }

  void checkInDone(String placeName) {
    _add('check_in', placeName);
  }

  void addToTrip(String placeName, String tripName) {
    _add('add_to_trip', '$placeName → $tripName');
  }

  void screenViewed(String screenName) {
    _add('screen_viewed', screenName);
  }

  /// Summary string to inject into the AI prompt. Uses last 120 events (full log).
  String getContextForAI() {
    if (_events.isEmpty) return '';

    final recent = _events.length > _maxEvents ? _events.sublist(_events.length - _maxEvents) : _events;
    final byType = <String, List<String>>{};
    for (final e in recent) {
      byType.putIfAbsent(e.type, () => []).add(e.label);
    }

    final parts = <String>[];

    final placeViewed = byType['place_viewed'];
    if (placeViewed != null && placeViewed.isNotEmpty) {
      final unique = placeViewed.toSet().take(25).toList();
      parts.add('Places the user viewed: ${unique.join("; ")}.');
    }

    final category = byType['category_browsed'];
    if (category != null && category.isNotEmpty) {
      final unique = category.toSet().take(10).toList();
      parts.add('Categories they browsed: ${unique.join(", ")}.');
    }

    final searchQueries = byType['search'];
    if (searchQueries != null && searchQueries.isNotEmpty) {
      final unique = searchQueries.toSet().take(10).toList();
      parts.add('Searches: ${unique.join(", ")}.');
    }

    final tabVisited = byType['tab_visited'];
    if (tabVisited != null && tabVisited.isNotEmpty) {
      final recentTabs = tabVisited.reversed.take(30).toList();
      parts.add('Tabs/screens opened (recent): ${recentTabs.join(", ")}.');
    }

    final trips = byType['trip_saved'];
    if (trips != null && trips.isNotEmpty) {
      parts.add('Trips they saved (places): ${trips.last}.');
    }

    final interests = byType['interests'];
    if (interests != null && interests.isNotEmpty) {
      parts.add('Selected interests: ${interests.last}.');
    }

    final plannerThemes = byType['planner_theme'];
    if (plannerThemes != null && plannerThemes.isNotEmpty) {
      parts.add('Recent planner themes: ${plannerThemes.take(5).join(", ")}.');
    }

    final placeSaved = byType['place_saved'];
    if (placeSaved != null && placeSaved.isNotEmpty) {
      parts.add('Places they saved: ${placeSaved.take(15).join(", ")}.');
    }
    final tourSaved = byType['tour_saved'];
    if (tourSaved != null && tourSaved.isNotEmpty) {
      parts.add('Tours they saved: ${tourSaved.take(10).join(", ")}.');
    }
    final filterUsed = byType['filter_used'];
    if (filterUsed != null && filterUsed.isNotEmpty) {
      parts.add('Filters they used: ${filterUsed.take(10).join(", ")}.');
    }
    final directions = byType['directions'];
    if (directions != null && directions.isNotEmpty) {
      parts.add('Directions requested to: ${directions.take(5).join(", ")}.');
    }

    if (parts.isEmpty) return '';
    return '**What we know from the user\'s activity in the app (last 120 actions):**\n${parts.join("\n")}\nUse this to personalize the plan when relevant.';
  }

  /// Short summary for the UI (e.g. "Based on 12 actions").
  String getSummaryForUI() {
    if (_events.isEmpty) return 'No activity yet';
    final uniqueTypes = _events.map((e) => e.type).toSet().length;
    final count = _events.length;
    return 'Based on $count actions ($uniqueTypes types)';
  }
}
