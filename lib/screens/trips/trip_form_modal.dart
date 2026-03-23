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
import 'trips_ui.dart';

enum _TripArrangeMode { manual, ai }

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
  String _nameError = '';
  _TripArrangeMode _arrangeMode = _TripArrangeMode.manual;

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
      final slots = Provider.of<TripsProvider>(context, listen: false)
          .getSlotsForTrip(widget.trip!);
      for (final s in slots) {
        _orderedPlaceIds.add(s.placeId);
        _startTimes[s.placeId] = s.startTime;
        _endTimes[s.placeId] = s.endTime;
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
        borderRadius: BorderRadius.circular(16),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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

  /// Arrange 1â†’n by visit time (earliest first). Places without time go last.
  void _arrangeByTime() {
    if (_orderedPlaceIds.length < 2) return;
    final ordered = List<String>.from(_orderedPlaceIds);
    ordered.sort((a, b) {
      final ta = _startTimes[a];
      final tb = _startTimes[b];
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return ta.compareTo(tb);
    });
    setState(() {
      _orderedPlaceIds.clear();
      _orderedPlaceIds.addAll(ordered);
    });
  }

  /// Parse duration string (e.g. "2 hours", "30 min", "1-2h") to minutes.
  static int _parseDurationMinutes(String? s) {
    if (s == null || s.isEmpty) return 60; // default 1h
    final lower = s.toLowerCase();
    final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(lower);
    final minMatch = RegExp(r'(\d+)\s*m').firstMatch(lower);
    final numMatch = RegExp(r'(\d+)').firstMatch(lower);
    int hours = 0, mins = 0;
    if (hourMatch != null) hours = int.tryParse(hourMatch.group(1) ?? '0') ?? 0;
    if (minMatch != null) mins = int.tryParse(minMatch.group(1) ?? '0') ?? 0;
    if (hours == 0 && mins == 0 && numMatch != null) {
      if (lower.contains('h')) {
        hours = int.tryParse(numMatch.group(1) ?? '0') ?? 0;
      } else {
        mins = int.tryParse(numMatch.group(1) ?? '0') ?? 60;
      }
    }
    if (lower.contains('half') || lower.contains('Â½')) return 240;
    if (lower.contains('full') || lower.contains('whole')) return 480;
    return hours * 60 + (mins > 0 ? mins : (hours > 0 ? 0 : 60));
  }

  /// Prefer order by location (geographic) and time needed at place (duration).
  void _preferByLocationAndDuration(List<Place> allPlaces) {
    if (_orderedPlaceIds.length < 2) return;
    final placeMap = {for (final p in allPlaces) p.id: p};
    final ordered = List<Place>.from(
        _orderedPlaceIds.map((id) => placeMap[id]).whereType<Place>());
    ordered.sort((a, b) {
      final latA = a.latitude ?? -999;
      final latB = b.latitude ?? -999;
      final lonA = a.longitude ?? -999;
      final lonB = b.longitude ?? -999;
      if ((latA - latB).abs() > 0.001) return latA.compareTo(latB);
      if ((lonA - lonB).abs() > 0.001) return lonA.compareTo(lonB);
      final durA = _parseDurationMinutes(a.duration);
      final durB = _parseDurationMinutes(b.duration);
      return durA.compareTo(durB);
    });
    setState(() {
      _orderedPlaceIds.clear();
      _orderedPlaceIds.addAll(ordered.map((p) => p.id));
    });
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
    final start = _startTimes[placeId];
    final end = _endTimes[placeId];
    final timeStr = (start != null && end != null)
        ? '$start – $end'
        : (start != null)
            ? 'From $start'
            : (end != null)
                ? 'Until $end'
                : l10n.tapClockToSetTime;
    return ReorderableDragStartListener(
      key: ValueKey('manual_$placeId'),
      index: i,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
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
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<_TripArrangeMode>(
            segments: [
              ButtonSegment(
                value: _TripArrangeMode.manual,
                label: Text(AppLocalizations.of(context)!.tripArrangeManual),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              ButtonSegment(
                value: _TripArrangeMode.ai,
                label: Text(AppLocalizations.of(context)!.tripArrangeAiPlanner),
                icon: const Icon(Icons.auto_awesome, size: 17),
              ),
            ],
            selected: {_arrangeMode},
            onSelectionChanged: (Set<_TripArrangeMode> next) {
              setState(() => _arrangeMode = next.first);
            },
          ),
        ),
        if (_arrangeMode == _TripArrangeMode.ai) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 20, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.tripArrangeAiHint,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/ai-planner');
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(AppLocalizations.of(context)!.tripOpenAiPlanner),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_arrangeMode == _TripArrangeMode.manual &&
            _orderedPlaceIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              AppLocalizations.of(context)!.tripArrangeManualHint,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        if (_arrangeMode == _TripArrangeMode.ai) const SizedBox(height: 8),
        if (_orderedPlaceIds.isNotEmpty) ...[
          if (_arrangeMode == _TripArrangeMode.manual &&
              _orderedPlaceIds.length >= 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _arrangeByTime(),
                      icon: const Icon(FontAwesomeIcons.clock, size: 12),
                      label: Text(AppLocalizations.of(context)!.arrangeByTime),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _preferByLocationAndDuration(allPlaces),
                      icon: const Icon(FontAwesomeIcons.route, size: 12),
                      label: Text(
                          AppLocalizations.of(context)!.preferByRouteDuration),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_arrangeMode == _TripArrangeMode.manual)
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
          if (_arrangeMode == _TripArrangeMode.ai)
            ..._orderedPlaceIds.asMap().entries.map((e) {
              final i = e.key;
              final placeId = e.value;
              final p = placesProvider.getPlaceById(placeId);
              if (p == null) return const SizedBox.shrink();
              return Container(
                key: ValueKey('ai_$placeId'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
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
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.tripAiTimesInPlanner,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _orderedPlaceIds.remove(placeId);
                          _startTimes.remove(placeId);
                          _endTimes.remove(placeId);
                        });
                      },
                      icon: const Icon(Icons.remove_circle_outline,
                          size: 20, color: AppTheme.textSecondary),
                      tooltip: AppLocalizations.of(context)!.remove,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              );
            }),
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
                          } else {
                            _orderedPlaceIds.add(p.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                    borderRadius: BorderRadius.circular(14)),
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
                      borderRadius: BorderRadius.circular(14)),
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
    final slots = _orderedPlaceIds
        .map((id) => TripSlot(
              placeId: id,
              startTime: _startTimes[id],
              endTime: _endTimes[id],
            ))
        .toList();
    final days = slots.isEmpty
        ? <TripDay>[]
        : [
            TripDay(
              date: DateFormat('yyyy-MM-dd').format(_startDate),
              slots: slots,
            ),
          ];

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
