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
import 'trips_list_logic.dart';
import 'trips_ui.dart';

BoxDecoration _detailSectionDecoration() {
  return BoxDecoration(
    color: AppTheme.surfaceColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: AppTheme.borderColor.withValues(alpha: 0.55),
    ),
    boxShadow: [
      BoxShadow(
        color: AppTheme.textPrimary.withValues(alpha: 0.04),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripPhaseBadge extends StatelessWidget {
  final TripPhase phase;

  const _TripPhaseBadge({required this.phase});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (phase) {
      case TripPhase.upcoming:
        label = l10n.tripStatusUpcoming;
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
        break;
      case TripPhase.ongoing:
        label = l10n.tripStatusOngoing;
        bg = AppTheme.successColor.withValues(alpha: 0.12);
        fg = AppTheme.successColor;
        break;
      case TripPhase.past:
        label = l10n.tripStatusPast;
        bg = AppTheme.surfaceVariant;
        fg = AppTheme.textSecondary;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: fg,
        ),
      ),
    );
  }
}

class TripDetailsModal extends StatelessWidget {
  final Trip trip;
  final List<String> placeIds;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onOpenMap;
  /// Opens place details (e.g. `/place/:id`).
  final ValueChanged<String> onOpenPlace;

  const TripDetailsModal({
    super.key,
    required this.trip,
    required this.placeIds,
    required this.onEdit,
    required this.onShare,
    required this.onOpenMap,
    required this.onOpenPlace,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final placesProvider = Provider.of<PlacesProvider>(context);
    final tripsProvider = Provider.of<TripsProvider>(context);
    final slots = tripsProvider.getSlotsForTrip(trip);
    final places = placeIds
        .map((id) => placesProvider.getPlaceById(id))
        .whereType<Place>()
        .toList();
    final durationDays = calendarDaysInclusive(trip.startDate, trip.endDate);
    final durationText = durationDays > 1
        ? l10n.daysCount(durationDays)
        : l10n.flexibleDays;
    final placesCountLabel = placeIds.length == 1
        ? l10n.placeCount(placeIds.length)
        : l10n.placesCount(placeIds.length);
    final phase = tripPhase(trip, DateTime.now());

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.45,
      maxChildSize: 0.96,
      builder: (_, scrollController) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            modalDragHandle(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          trip.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            height: 1.2,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: onShare,
                        icon: const Icon(Icons.ios_share_rounded, size: 20),
                        tooltip: l10n.shareTrip,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(42, 42),
                          padding: EdgeInsets.zero,
                          foregroundColor: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        onPressed: onEdit,
                        icon: const Icon(FontAwesomeIcons.pen, size: 15),
                        tooltip: l10n.editTrip,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(42, 42),
                          padding: EdgeInsets.zero,
                          foregroundColor: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 22),
                        tooltip: l10n.close,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(42, 42),
                          padding: EdgeInsets.zero,
                          foregroundColor: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        icon: Icons.calendar_month_rounded,
                        label: formatTripDateRange(trip),
                      ),
                      _TripPhaseBadge(phase: phase),
                      _MetaChip(
                        icon: Icons.schedule_rounded,
                        label: durationText,
                      ),
                      _MetaChip(
                        icon: Icons.place_outlined,
                        label: placesCountLabel,
                      ),
                    ],
                  ),
                  if (trip.description != null &&
                      trip.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      trip.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    l10n.tripMapRoute,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _detailSectionDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (trip.days.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.alt_route_rounded,
                                    size: 28,
                                    color: AppTheme.textTertiary,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.noPlacesAttachedYet,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: AppTheme.textSecondary,
                                    ),
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
                              if (dayIndex > 0) const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Day ${dayIndex + 1} · $dayLabel',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...day.slots.asMap().entries.map((slotEntry) {
                                final i = slotEntry.key;
                                final slot = slotEntry.value;
                                final p = placesProvider.getPlaceById(
                                  slot.placeId,
                                );
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
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (!isLast)
                                            Container(
                                              width: 2,
                                              height: 28,
                                              margin:
                                                  const EdgeInsets.only(top: 2),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(1),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    AppTheme.primaryColor
                                                        .withValues(alpha: 0.45),
                                                    AppTheme.primaryColor
                                                        .withValues(alpha: 0.1),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => onOpenPlace(p.id),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppTheme.surfaceVariant
                                                    .withValues(alpha: 0.65),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          p.name,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppTheme
                                                                .textPrimary,
                                                          ),
                                                        ),
                                                        if (timeStr != null) ...[
                                                          const SizedBox(
                                                              height: 6),
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                FontAwesomeIcons
                                                                    .clock,
                                                                size: 12,
                                                                color: AppTheme
                                                                    .primaryColor,
                                                              ),
                                                              const SizedBox(
                                                                  width: 6),
                                                              Expanded(
                                                                child: Text(
                                                                  timeStr,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: AppTheme
                                                                        .primaryColor,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.chevron_right_rounded,
                                                    size: 22,
                                                    color: AppTheme.textTertiary,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ];
                          }),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onOpenMap,
                            icon: const Icon(FontAwesomeIcons.map, size: 16),
                            label: Text(l10n.viewRouteOnMap),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.placesInThisTrip,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: _detailSectionDecoration(),
                    child: places.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                l10n.noPlacesAttachedYet,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: places.asMap().entries.map((e) {
                              final i = e.key;
                              final p = e.value;
                              final slot =
                                  i < slots.length ? slots[i] : null;
                              final timeStr = (slot != null &&
                                      slot.startTime != null &&
                                      slot.endTime != null)
                                  ? '${slot.startTime} – ${slot.endTime}'
                                  : (slot?.startTime != null)
                                      ? 'From ${slot!.startTime}'
                                      : (slot?.endTime != null)
                                          ? 'Until ${slot!.endTime}'
                                          : null;
                              final isLast = i == places.length - 1;
                              return Column(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => onOpenPlace(p.id),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                FontAwesomeIcons.locationDot,
                                                size: 14,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p.name,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppTheme.textPrimary,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (timeStr != null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      timeStr,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: AppTheme
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              size: 22,
                                              color: AppTheme.textTertiary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Divider(
                                      height: 1,
                                      indent: 56,
                                      color: AppTheme.borderColor
                                          .withValues(alpha: 0.6),
                                    ),
                                ],
                              );
                            }).toList(),
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
}
