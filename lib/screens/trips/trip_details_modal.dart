import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/place.dart';
import '../../models/trip.dart';
import '../../providers/places_provider.dart';
import '../../providers/trips_provider.dart';
import '../../theme/app_theme.dart';
import 'trips_format.dart';
import 'trips_ui.dart';

class TripDetailsModal extends StatelessWidget {
  final Trip trip;
  final List<String> placeIds;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onOpenMap;

  const TripDetailsModal({
    super.key,
    required this.trip,
    required this.placeIds,
    required this.onEdit,
    required this.onShare,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PlacesProvider>(context);
    final tripsProvider = Provider.of<TripsProvider>(context);
    final slots = tripsProvider.getSlotsForTrip(trip);
    final places = placeIds
        .map((id) => placesProvider.getPlaceById(id))
        .whereType<Place>()
        .toList();
    final durationDays = calendarDaysInclusive(trip.startDate, trip.endDate);
    final durationText = durationDays > 1
        ? AppLocalizations.of(context)!.daysCount(durationDays)
        : AppLocalizations.of(context)!.flexibleDays;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            modalDragHandle(),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    tooltip: AppLocalizations.of(context)!.shareTrip,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      backgroundColor: AppTheme.surfaceVariant,
                      foregroundColor: AppTheme.textPrimary,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(FontAwesomeIcons.pen, size: 14),
                    tooltip: AppLocalizations.of(context)!.editTrip,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      backgroundColor: AppTheme.surfaceVariant,
                      foregroundColor: AppTheme.textPrimary,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: AppLocalizations.of(context)!.close,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      backgroundColor: AppTheme.surfaceVariant,
                      foregroundColor: AppTheme.textPrimary,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: tripsPanelDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow(AppLocalizations.of(context)!.dates,
                            formatTripDateRange(trip)),
                        const SizedBox(height: 4),
                        _detailRow(AppLocalizations.of(context)!.duration,
                            durationText),
                        const SizedBox(height: 4),
                        _detailRow(AppLocalizations.of(context)!.places,
                            '${placeIds.length}'),
                        if (trip.description != null &&
                            trip.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            trip.description!,
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: tripsPanelDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.tripMapRoute,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (trip.days.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  const Icon(FontAwesomeIcons.mapLocationDot,
                                      size: 18, color: AppTheme.borderColor),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .noPlacesAttachedYet,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...trip.days.asMap().entries.expand((dayEntry) {
                            final dayIndex = dayEntry.key;
                            final day = dayEntry.value;
                            final dayDate = DateTime.tryParse(day.date);
                            final dayLabel = dayDate != null
                                ? DateFormat('EEE, MMM d').format(dayDate)
                                : 'Day ${dayIndex + 1}';
                            return [
                              if (dayIndex > 0) const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Day ${dayIndex + 1} · $dayLabel',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              ...day.slots.asMap().entries.map((slotEntry) {
                                final i = slotEntry.key;
                                final slot = slotEntry.value;
                                final p =
                                    placesProvider.getPlaceById(slot.placeId);
                                if (p == null) return const SizedBox.shrink();
                                final isLast = i == day.slots.length - 1;
                                final timeStr = (slot.startTime != null &&
                                        slot.endTime != null)
                                    ? '${slot.startTime} – ${slot.endTime}'
                                    : (slot.startTime != null)
                                        ? 'From ${slot.startTime}'
                                        : (slot.endTime != null)
                                            ? 'Until ${slot.endTime}'
                                            : null;
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (!isLast)
                                          Container(
                                            width: 2,
                                            height: 24,
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.3),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          if (timeStr != null) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(
                                                    FontAwesomeIcons.clock,
                                                    size: 10,
                                                    color:
                                                        AppTheme.primaryColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  timeStr,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppTheme.primaryColor,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(
                                                  FontAwesomeIcons.locationDot,
                                                  size: 10,
                                                  color:
                                                      AppTheme.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(
                                                p.location,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppTheme.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ];
                          }),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onOpenMap,
                            icon: const Icon(FontAwesomeIcons.map, size: 16),
                            label: Text(
                                AppLocalizations.of(context)!.viewRouteOnMap),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: tripsPanelDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.placesInThisTrip,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (places.isEmpty)
                          Text(
                              AppLocalizations.of(context)!.noPlacesAttachedYet,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary))
                        else
                          ...places.asMap().entries.map((e) {
                            final i = e.key;
                            final p = e.value;
                            final slot = i < slots.length ? slots[i] : null;
                            final timeStr = (slot != null &&
                                    slot.startTime != null &&
                                    slot.endTime != null)
                                ? '${slot.startTime} – ${slot.endTime}'
                                : (slot?.startTime != null)
                                    ? 'From ${slot!.startTime}'
                                    : (slot?.endTime != null)
                                        ? 'Until ${slot!.endTime}'
                                        : null;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (timeStr != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(FontAwesomeIcons.clock,
                                            size: 10,
                                            color: AppTheme.primaryColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(FontAwesomeIcons.locationDot,
                                          size: 10,
                                          color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        p.location,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                  if (p.category.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(FontAwesomeIcons.tag,
                                            size: 10,
                                            color: AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          p.category,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary)),
      ],
    );
  }
}
