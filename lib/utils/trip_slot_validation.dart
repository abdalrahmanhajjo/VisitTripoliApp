import '../models/trip.dart';

int? _minutes(String? s) {
  if (s == null || s.isEmpty) return null;
  final parts = s.trim().split(RegExp(r'[:\s]'));
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return null;
  }
  return h * 60 + m;
}

/// Inclusive range [startMin, endMin) for overlap check; default 1h window if end missing.
List<int> slotTimeRange(TripSlot s) {
  final start = _minutes(s.startTime) ?? 8 * 60;
  var end = _minutes(s.endTime);
  if (end == null) end = start + 60;
  if (end <= start) end = start + 60;
  return [start, end];
}

/// True if any two slots with a start time overlap on the same day.
bool hasOverlappingTimeSlots(List<TripSlot> slots) {
  final timed = slots
      .where((s) => s.startTime != null && s.startTime!.trim().isNotEmpty)
      .toList();
  if (timed.length < 2) return false;
  final ranges = timed.map(slotTimeRange).toList()
    ..sort((a, b) => a[0].compareTo(b[0]));
  for (var i = 1; i < ranges.length; i++) {
    if (ranges[i - 1][1] > ranges[i][0]) return true;
  }
  return false;
}

/// `dateStr` is yyyy-MM-dd.
bool tripCoversCalendarDate(Trip trip, String dateStr) {
  try {
    final d = DateTime.parse(dateStr);
    final day = DateTime(d.year, d.month, d.day);
    final start = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
    final end = DateTime(
      trip.endDate.year,
      trip.endDate.month,
      trip.endDate.day,
    );
    return !day.isBefore(start) && !day.isAfter(end);
  } catch (_) {
    return false;
  }
}
