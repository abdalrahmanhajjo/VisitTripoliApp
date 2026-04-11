import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/place.dart';
import '../../models/trip.dart';
import '../../providers/places_provider.dart';
import '../../providers/tours_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/trips_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/trip_slot_validation.dart';
import 'trips_ui.dart';

class TripFormModal extends StatefulWidget {
  final Trip? trip;
  final DateTime? selectedDate;
  final void Function(String message) onSaved;

  const TripFormModal({
    super.key,
    this.trip,
    this.selectedDate,
    required this.onSaved,
  });

  @override
  State<TripFormModal> createState() => TripFormModalState();
}

class TripFormModalState extends State<TripFormModal> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _searchController;
  late DateTime _startDate;
  late DateTime _endDate;
  final List<String> _orderedPlaceIds = [];
  final Map<String, String?> _startTimes = {};
  final Map<String, String?> _endTimes = {};
  /// Day index within the trip (0 = first calendar day) for each place.
  final Map<String, int> _placeDayIndex = {};
  String _nameError = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    if (widget.trip != null) {
      _nameController = TextEditingController(text: widget.trip!.name);
      _notesController =
          TextEditingController(text: widget.trip!.description ?? '');
      _startDate = widget.trip!.startDate;
      _endDate = widget.trip!.endDate;
      for (var d = 0; d < widget.trip!.days.length; d++) {
        final day = widget.trip!.days[d];
        for (final s in day.slots) {
          _orderedPlaceIds.add(s.placeId);
          _placeDayIndex[s.placeId] = d;
          _startTimes[s.placeId] = s.startTime;
          _endTimes[s.placeId] = s.endTime;
        }
      }
    } else {
      _nameController = TextEditingController();
      _notesController = TextEditingController();
      final base = widget.selectedDate ?? DateTime.now();
      _startDate = base;
      _endDate = base;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyQuickDates(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      switch (preset) {
        case 'today':
          _startDate = today;
          _endDate = today;
          break;
        case 'weekend':
          final weekday = now.weekday;
          final saturday = today.add(Duration(days: (6 - weekday) % 7));
          _startDate = saturday;
          _endDate = saturday.add(const Duration(days: 1));
          break;
        case 'week':
          _startDate = today;
          _endDate = today.add(const Duration(days: 6));
          break;
      }
    });
  }

  static String _formatDateShort(DateTime d) =>
      DateFormat('EEE, MMM d').format(d);

  /// Inclusive calendar days from [start] to [end] (date-only).
  static int calendarDayCount(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return e.difference(s).inDays + 1;
  }

  /// Splits [orderedSlots] across [dayCount] consecutive days starting at [startDate].
  static List<TripDay> buildTripDaysForRange({
    required List<TripSlot> orderedSlots,
    required DateTime startDate,
    required int dayCount,
  }) {
    if (orderedSlots.isEmpty) return [];
    if (dayCount <= 1) {
      return [
        TripDay(
          date: DateFormat('yyyy-MM-dd').format(
            DateTime(startDate.year, startDate.month, startDate.day),
          ),
          slots: orderedSlots,
        ),
      ];
    }
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final days = <TripDay>[];
    final n = orderedSlots.length;
    var base = n ~/ dayCount;
    var rem = n % dayCount;
    var idx = 0;
    for (var d = 0; d < dayCount; d++) {
      final chunk = base + (rem > 0 ? 1 : 0);
      if (rem > 0) rem--;
      final endIdx = idx + chunk;
      final safeEnd = endIdx > n ? n : endIdx;
      final daySlots =
          idx < safeEnd ? orderedSlots.sublist(idx, safeEnd) : <TripSlot>[];
      idx = safeEnd;
      final dayDate = start.add(Duration(days: d));
      days.add(TripDay(
        date: DateFormat('yyyy-MM-dd').format(dayDate),
        slots: daySlots,
      ));
    }
    return days;
  }

  static int? _minutesForTime(String? s) {
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

  /// Builds [TripDay] rows from user-chosen day per place (multi-day trips).
  static List<TripDay> buildTripDaysFromAssignments({
    required List<String> orderedPlaceIds,
    required Map<String, int> placeDayIndex,
    required Map<String, String?> startTimes,
    required Map<String, String?> endTimes,
    required DateTime startDate,
    required int dayCount,
  }) {
    if (orderedPlaceIds.isEmpty || dayCount <= 0) return [];
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final maxDay = dayCount - 1;
    final days = <TripDay>[];
    for (var d = 0; d < dayCount; d++) {
      final dateStr =
          DateFormat('yyyy-MM-dd').format(start.add(Duration(days: d)));
      final slots = <TripSlot>[];
      for (final id in orderedPlaceIds) {
        var idx = placeDayIndex[id] ?? 0;
        if (idx < 0) idx = 0;
        if (idx > maxDay) idx = maxDay;
        if (idx == d) {
          slots.add(TripSlot(
            placeId: id,
            startTime: startTimes[id],
            endTime: endTimes[id],
          ));
        }
      }
      slots.sort((a, b) {
        final ma = _minutesForTime(a.startTime) ?? 0;
        final mb = _minutesForTime(b.startTime) ?? 0;
        return ma.compareTo(mb);
      });
      days.add(TripDay(date: dateStr, slots: slots));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PlacesProvider>(context);
    final toursProvider = Provider.of<ToursProvider>(context);
    final eventsProvider = Provider.of<EventsProvider>(context);
    final allPlaces =
        _getAllPlaces(placesProvider, toursProvider, eventsProvider);
    final search = _searchController.text.trim().toLowerCase();
    final filteredPlaces = search.isEmpty
        ? allPlaces
        : allPlaces
            .where((p) =>
                p.name.toLowerCase().contains(search) ||
                p.location.toLowerCase().contains(search))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TripsLayout.sheetTopRadius),
          ),
        ),
        child: Column(
          children: [
            modalDragHandle(),
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: TripsLayout.sheetHorizontalPadding,
                  vertical: 16,
                ),
                children: [
                  _buildSection(AppLocalizations.of(context)!.tripName,
                      AppLocalizations.of(context)!.giveTripMemorableName, [
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() => _nameError = ''),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.tripNameHint,
                        errorText: _nameError.isEmpty ? null : _nameError,
                        prefixIcon: const Icon(Icons.edit_note,
                            size: 20, color: AppTheme.textTertiary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _nameError.isNotEmpty
                                  ? Colors.red.shade400
                                  : AppTheme.borderColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(AppLocalizations.of(context)!.when,
                      AppLocalizations.of(context)!.setTravelDates, [
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _chip(AppLocalizations.of(context)!.today,
                          () => _applyQuickDates('today')),
                      _chip(AppLocalizations.of(context)!.thisWeekend,
                          () => _applyQuickDates('weekend')),
                      _chip(AppLocalizations.of(context)!.nextWeek,
                          () => _applyQuickDates('week')),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _dateChip(
                              AppLocalizations.of(context)!.start, _startDate,
                              () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) setState(() => _startDate = d);
                          }),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward,
                              size: 16, color: AppTheme.textTertiary),
                        ),
                        Expanded(
                          child: _dateChip(
                              AppLocalizations.of(context)!.end, _endDate,
                              () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) setState(() => _endDate = d);
                          }),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(AppLocalizations.of(context)!.notesOptional,
                      AppLocalizations.of(context)!.addTripDetails, [
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.notesHint,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildPlacesSection(allPlaces, filteredPlaces, search),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TripsLayout.sheetHorizontalPadding,
        8,
        TripsLayout.sheetHorizontalPadding,
        16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.trip == null
                    ? AppLocalizations.of(context)!.createNewTrip
                    : AppLocalizations.of(context)!.editTripTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.trip == null
                    ? AppLocalizations.of(context)!.addDatesPlaces
                    : AppLocalizations.of(context)!.updateTripDetails,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 22),
            tooltip: AppLocalizations.of(context)!.close,
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              backgroundColor: AppTheme.surfaceVariant,
              foregroundColor: AppTheme.textPrimary,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(TripsLayout.sectionRadius),
        border: Border.all(color: AppTheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
                color: AppTheme.textPrimary.withValues(alpha: 0.05), blurRadius: 4)
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _dateChip(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TripsLayout.cardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(TripsLayout.cardRadius),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  _formatDateShort(date),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(
      BuildContext context, String placeId, bool isStart) async {
    final current = isStart ? _startTimes[placeId] : _endTimes[placeId];
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    if (current != null && current.contains(':')) {
      final parts = current.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 9;
        final m = int.tryParse(parts[1]) ?? 0;
        initial = TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
      }
    } else if (!isStart && _startTimes[placeId] != null) {
      final start = _startTimes[placeId]!;
      if (start.contains(':')) {
        final parts = start.split(':');
        if (parts.length >= 2) {
          final h = (int.tryParse(parts[0]) ?? 9) + 1;
          final m = int.tryParse(parts[1]) ?? 0;
          initial = TimeOfDay(hour: (h > 23 ? 23 : h), minute: m.clamp(0, 59));
        }
      }
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        final str =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          _startTimes[placeId] = str;
        } else {
          _endTimes[placeId] = str;
        }
      });
    }
  }

  Widget _buildManualPlaceRow(int i, PlacesProvider placesProvider) {
    final placeId = _orderedPlaceIds[i];
    final l10n = AppLocalizations.of(context)!;
    final p = placesProvider.getPlaceById(placeId);
    if (p == null) {
      return ReorderableDragStartListener(
        key: ValueKey('manual_$placeId'),
        index: i,
        child: const SizedBox(height: 0, width: 0),
      );
    }
    final daySpan = calendarDayCount(_startDate, _endDate);
    final start = _startTimes[placeId];
    final end = _endTimes[placeId];
    final timeStr = (start != null && end != null)
        ? '$start – $end'
        : (start != null)
            ? l10n.fromTime(start)
            : (end != null)
                ? l10n.untilTime(end)
                : l10n.tapClockToSetTime;
    return ReorderableDragStartListener(
      key: ValueKey('manual_$placeId'),
      index: i,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(TripsLayout.cardRadius),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.drag_handle,
                  size: 20, color: AppTheme.textTertiary),
            ),
            const SizedBox(width: 6),
            Text(
              '${i + 1}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _pickTime(context, placeId, true),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(FontAwesomeIcons.clock,
                              size: 11, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (daySpan > 1) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.tripVisitDayLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.borderColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: (_placeDayIndex[placeId] ?? 0)
                                      .clamp(0, daySpan - 1),
                                  items: List.generate(daySpan, (d) {
                                    final date = DateTime(_startDate.year,
                                            _startDate.month, _startDate.day)
                                        .add(Duration(days: d));
                                    return DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        l10n.tripDayNumberDate(
                                          d + 1,
                                          DateFormat.MMMEd(
                                            Localizations.localeOf(context)
                                                .toString(),
                                          ).format(date),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _placeDayIndex[placeId] = v);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => _pickTime(context, placeId, true),
              icon: const Icon(Icons.access_time, size: 18),
              tooltip: l10n.setStartTime,
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
            ),
            IconButton(
              onPressed: () => _pickTime(context, placeId, false),
              icon: const Icon(Icons.schedule, size: 18),
              tooltip: l10n.setEndTime,
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _orderedPlaceIds.remove(placeId);
                  _startTimes.remove(placeId);
                  _endTimes.remove(placeId);
                  _placeDayIndex.remove(placeId);
                });
              },
              icon: const Icon(Icons.remove_circle_outline,
                  size: 20, color: AppTheme.textSecondary),
              tooltip: l10n.remove,
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacesSection(
      List<Place> allPlaces, List<Place> filteredPlaces, String search) {
    final placesProvider = Provider.of<PlacesProvider>(context);
    return _buildSection(
      AppLocalizations.of(context)!.placesInThisTrip,
      _orderedPlaceIds.isEmpty
          ? AppLocalizations.of(context)!.addPlacesSubtitle
          : AppLocalizations.of(context)!
              .placesCountSubtitle(_orderedPlaceIds.length),
      [
        const SizedBox(height: 4),
        if (_orderedPlaceIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              AppLocalizations.of(context)!.tripArrangeManualHint,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        if (_orderedPlaceIds.isNotEmpty) ...[
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final id = _orderedPlaceIds.removeAt(oldIndex);
                _orderedPlaceIds.insert(newIndex, id);
              });
            },
            children: [
              for (var i = 0; i < _orderedPlaceIds.length; i++)
                _buildManualPlaceRow(i, placesProvider),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.addMorePlaces,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
        ],
        if (allPlaces.isEmpty)
          _emptyPlacesCard()
        else ...[
          if (allPlaces.length > 5)
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchPlaces,
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppTheme.textTertiary),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          if (allPlaces.length > 5) const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredPlaces.isEmpty ? 1 : filteredPlaces.length,
              itemBuilder: (context, i) {
                if (filteredPlaces.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      search.isEmpty
                          ? AppLocalizations.of(context)!.noPlacesFound
                          : AppLocalizations.of(context)!.noMatchesFor(search),
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  );
                }
                final p = filteredPlaces[i];
                final isSelected = _orderedPlaceIds.contains(p.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _orderedPlaceIds.remove(p.id);
                            _startTimes.remove(p.id);
                            _endTimes.remove(p.id);
                            _placeDayIndex.remove(p.id);
                          } else {
                            _orderedPlaceIds.add(p.id);
                            _placeDayIndex[p.id] = 0;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(TripsLayout.cardRadius),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(TripsLayout.cardRadius),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                        .withValues(alpha: 0.15)
                                    : AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isSelected
                                    ? Icons.check
                                    : FontAwesomeIcons.mapLocationDot,
                                size: 16,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppTheme.textPrimary
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.location,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (p.rating != null)
                                        Text(
                                          'â˜… ${p.rating!.toStringAsFixed(1)}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              size: 22,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _emptyPlacesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(TripsLayout.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(FontAwesomeIcons.mapLocationDot,
              size: 32, color: AppTheme.borderColor),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noPlacesYet,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.savePlacesFromExplore,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.go('/explore');
            },
            icon: const Icon(Icons.explore, size: 18),
            label: Text(AppLocalizations.of(context)!.explorePlaces),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          TripsLayout.sheetHorizontalPadding,
          16,
          TripsLayout.sheetHorizontalPadding,
          MediaQuery.of(context).padding.bottom + TripsLayout.sheetBottomPadding),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TripsLayout.controlRadius)),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _saveTrip,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TripsLayout.controlRadius)),
                  elevation: 0,
                ),
                child: Text(
                  widget.trip == null
                      ? AppLocalizations.of(context)!.createTrip
                      : AppLocalizations.of(context)!.saveChanges,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Place> _getAllPlaces(PlacesProvider placesProvider,
      ToursProvider toursProvider, EventsProvider eventsProvider) {
    final seen = <String>{};
    final result = <Place>[];

    for (final p in placesProvider.places) {
      if (seen.add(p.id)) result.add(p);
    }
    for (final p in placesProvider.savedPlaces) {
      if (seen.add(p.id)) result.add(p);
    }
    for (final t in toursProvider.tours) {
      for (final pid in t.placeIds) {
        final p = placesProvider.getPlaceById(pid);
        if (p != null && seen.add(p.id)) result.add(p);
      }
    }
    for (final e in eventsProvider.events) {
      if (e.placeId != null) {
        final p = placesProvider.getPlaceById(e.placeId!);
        if (p != null && seen.add(p.id)) result.add(p);
      }
    }
    return result;
  }

  void _saveTrip() {
    final name = _nameController.text.trim();
    setState(() => _nameError = '');
    if (name.isEmpty) {
      setState(
          () => _nameError = AppLocalizations.of(context)!.pleaseEnterTripName);
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.endDateBeforeStart)),
      );
      return;
    }

    final provider = Provider.of<TripsProvider>(context, listen: false);
    if (provider.hasDateConflict(
      _startDate,
      _endDate,
      excludeTripId: widget.trip?.id,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.tripOverlapsExistingDates,
          ),
        ),
      );
      return;
    }
    final daySpan = calendarDayCount(_startDate, _endDate);
    final days = buildTripDaysFromAssignments(
      orderedPlaceIds: _orderedPlaceIds,
      placeDayIndex: _placeDayIndex,
      startTimes: _startTimes,
      endTimes: _endTimes,
      startDate: _startDate,
      dayCount: daySpan,
    );
    for (final day in days) {
      if (hasOverlappingTimeSlots(day.slots)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.timeConflict),
          ),
        );
        return;
      }
    }

    if (widget.trip != null) {
      provider.updateTrip(Trip(
        id: widget.trip!.id,
        name: name,
        startDate: _startDate,
        endDate: _endDate,
        days: days,
        description: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.trip!.createdAt,
      ));
    } else {
      provider.addTrip(Trip(
        id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        startDate: _startDate,
        endDate: _endDate,
        days: days,
        description: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      ));
    }
    widget.onSaved(widget.trip == null
        ? AppLocalizations.of(context)!.tripCreated
        : AppLocalizations.of(context)!.tripUpdated);
  }
}
