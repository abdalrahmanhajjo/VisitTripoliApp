import '../../models/trip.dart';

/// How to order trips on the Trips screen.
enum TripSortMode {
  /// Upcoming first (soonest start), then active trips, then past (most recently ended).
  smart,

  /// All trips by start date ascending (soonest trip on top).
  startSoonest,

  /// Newest created first (legacy behavior).
  recentlyCreated,

  /// Alphabetical by trip name.
  nameAtoZ,
}

/// Whether a trip is in the future, currently running, or already finished (by calendar day).
enum TripPhase {
  upcoming,
  ongoing,
  past,
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Classify [trip] relative to [now] (typically `DateTime.now()`).
TripPhase tripPhase(Trip trip, DateTime now) {
  final today = _day(now);
  final s = _day(trip.startDate);
  final e = _day(trip.endDate);
  if (e.isBefore(today)) return TripPhase.past;
  if (s.isAfter(today)) return TripPhase.upcoming;
  return TripPhase.ongoing;
}

int _compareSmart(Trip a, Trip b, DateTime now) {
  final pa = tripPhase(a, now);
  final pb = tripPhase(b, now);
  const rank = {
    TripPhase.upcoming: 0,
    TripPhase.ongoing: 1,
    TripPhase.past: 2,
  };
  final byPhase = rank[pa]!.compareTo(rank[pb]!);
  if (byPhase != 0) return byPhase;

  switch (pa) {
    case TripPhase.upcoming:
      return a.startDate.compareTo(b.startDate);
    case TripPhase.ongoing:
      return a.endDate.compareTo(b.endDate);
    case TripPhase.past:
      return b.endDate.compareTo(a.endDate);
  }
}

/// Stable, predictable ordering for the Trips list.
List<Trip> sortTrips(List<Trip> trips, TripSortMode mode, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final copy = List<Trip>.from(trips);
  switch (mode) {
    case TripSortMode.smart:
      copy.sort((a, b) => _compareSmart(a, b, n));
      break;
    case TripSortMode.startSoonest:
      copy.sort((a, b) => a.startDate.compareTo(b.startDate));
      break;
    case TripSortMode.recentlyCreated:
      copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case TripSortMode.nameAtoZ:
      copy.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      break;
  }
  return copy;
}

/// Filter trips whose date range overlaps [day] (calendar day).
bool tripCoversCalendarDay(Trip trip, DateTime day) {
  final d = _day(day);
  final s = _day(trip.startDate);
  final e = _day(trip.endDate);
  return !d.isBefore(s) && !d.isAfter(e);
}

/// Case-insensitive substring match on trip name (and optional description).
List<Trip> filterTripsByQuery(List<Trip> trips, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return trips;
  return trips.where((t) {
    if (t.name.toLowerCase().contains(q)) return true;
    final d = t.description?.trim();
    if (d != null && d.isNotEmpty && d.toLowerCase().contains(q)) return true;
    return false;
  }).toList();
}
