import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/trip.dart' show Trip, TripDay;
import '../../providers/trips_provider.dart';
import '../../theme/app_theme.dart';

/// Opens the map in trip mode. If the trip has more than one day with stops,
/// shows a picker so the user chooses which day to route (directions are per day).
Future<void> openTripRouteOnMap(BuildContext context, Trip trip) async {
  final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
  final allIds = tripsProvider.getPlaceIdsForTrip(trip);
  if (allIds.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noPlacesAttachedYet),
        ),
      );
    }
    return;
  }

  final daysWithStops =
      trip.days.asMap().entries.where((e) => e.value.slots.isNotEmpty).toList();
  if (daysWithStops.length <= 1) {
    final ids = allIds.join(',');
    if (!context.mounted) return;
    context.push('/map?tripOnly=true&placeIds=$ids');
    return;
  }

  final pickedDayIndex = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TripDayPickerSheet(
      daysWithStops: daysWithStops,
    ),
  );
  if (pickedDayIndex == null || !context.mounted) return;

  final dayIds = tripsProvider.getPlaceIdsForTripDay(trip, pickedDayIndex);
  if (dayIds.isEmpty) return;
  final ids = dayIds.join(',');

  final day = trip.days[pickedDayIndex];
  DateTime? parsed;
  try {
    parsed = DateTime.parse(day.date);
  } catch (_) {
    parsed = null;
  }
  final l10n = AppLocalizations.of(context)!;
  final dateStr = parsed != null
      ? DateFormat('EEE, MMM d').format(parsed)
      : day.date;
  final label = '${l10n.day} ${pickedDayIndex + 1} · $dateStr';

  context.push(
    '/map?tripOnly=true&placeIds=$ids&tripDayLabel=${Uri.encodeComponent(label)}',
  );
}

class _TripDayPickerSheet extends StatelessWidget {
  final List<MapEntry<int, TripDay>> daysWithStops;

  const _TripDayPickerSheet({
    required this.daysWithStops,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tripMapRoute,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose which day to see on the map and get directions for.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: daysWithStops.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final entry = daysWithStops[i];
                  final dayIndex = entry.key;
                  final day = entry.value;
                  DateTime? parsed;
                  try {
                    parsed = DateTime.parse(day.date);
                  } catch (_) {
                    parsed = null;
                  }
                  final dateStr = parsed != null
                      ? DateFormat('EEE, MMM d, y').format(parsed)
                      : day.date;
                  final stopCount = day.slots.length;
                  return Material(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context, dayIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${dayIndex + 1}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${l10n.day} ${dayIndex + 1}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              stopCount == 1
                                  ? l10n.placeCount(stopCount)
                                  : l10n.placesCount(stopCount),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
