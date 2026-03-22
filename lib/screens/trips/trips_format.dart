import 'package:intl/intl.dart';

import '../../models/trip.dart';

/// Inclusive calendar-day span (same calendar day => 1).
int calendarDaysInclusive(DateTime start, DateTime end) {
  final s = DateTime(start.year, start.month, start.day);
  final e = DateTime(end.year, end.month, end.day);
  if (e.isBefore(s)) return 1;
  return e.difference(s).inDays + 1;
}

/// Human-readable date range for trip headers.
String formatTripDateRange(Trip trip) {
  final s = trip.startDate;
  final e = trip.endDate;
  final sameDay =
      s.year == e.year && s.month == e.month && s.day == e.day;
  if (sameDay) {
    return DateFormat.yMMMd().format(s);
  }
  return '${DateFormat.yMMMd().format(s)} – ${DateFormat.yMMMd().format(e)}';
}
