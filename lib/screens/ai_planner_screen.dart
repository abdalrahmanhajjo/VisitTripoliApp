import 'dart:async';

// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, curly_braces_in_flow_control_structures, prefer_single_quotes, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/places_provider.dart';
import '../providers/trips_provider.dart';
import '../providers/interests_provider.dart';
import '../providers/activity_log_provider.dart';
import '../models/interest.dart';
import '../models/place.dart';
import '../models/trip.dart';
import '../services/ai_planner_service.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_bottom_nav.dart';

const _keyPlannerDays = 'planner_days';
const _keyPlannerPlacesPerDay = 'planner_places_per_day';
const _keyPlannerPrefsSet = 'planner_prefs_set';

/// One message in the chat (user or assistant; assistant may include a plan).
class _ChatMessage {
  final bool isUser;
  final String text;
  final List<AIPlannerSlot>? slots;
  final List<Place>? places;
  /// When true, show a "Try again" button (for error replies).
  final bool isRetryable;

  const _ChatMessage({
    required this.isUser,
    required this.text,
    this.slots,
    this.places,
    this.isRetryable = false,
  });
}

class AIPlannerScreen extends StatefulWidget {
  const AIPlannerScreen({super.key});

  @override
  State<AIPlannerScreen> createState() => _AIPlannerScreenState();
}

class _AIPlannerScreenState extends State<AIPlannerScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isGenerating = false;
  DateTime? _selectedDate;
  int _duration = 1;
  /// Places per day (set once via dialog, then used for every plan).
  int _placesPerDay = 4;
  String _budget = 'moderate';
  List<String> _selectedInterests = [];
  int? _preferredPlaceCount;
  int? _groupSize;
  /// AI response language: follows app language (no selector).
  String _aiLanguage = 'en';
  final List<_ChatMessage> _chatMessages = [];
  /// Last user message that led to an error; used for "Try again".
  String? _lastFailedUserMessage;
  /// Last plan (from AI or after user edits) so "do the plan again with X" uses it.
  List<AIPlannerSlot>? _lastPlanSlots;
  List<Place>? _lastPlanPlaces;

  String _greetingL10n(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final h = DateTime.now().hour;
    if (h < 12) return l10n.goodMorning;
    if (h < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  static const _moodCards = [
    (
      icon: FontAwesomeIcons.landmark,
      label: 'Culture day',
      prompt:
          'A cultural day with museums, art, and heritage—morning at the citadel, then museums'
    ),
    (
      icon: FontAwesomeIcons.utensils,
      label: 'Foodie tour',
      prompt:
          'Best traditional Lebanese food—souks, Hallab sweets, local lunch spots'
    ),
    (
      icon: FontAwesomeIcons.mosque,
      label: 'History & faith',
      prompt:
          'Historical sites and beautiful mosques, citadel first for morning light'
    ),
    (
      icon: FontAwesomeIcons.store,
      label: 'Souk explorer',
      prompt:
          'Explore old souks and khans, textile market, soap khan, local crafts'
    ),
    (
      icon: FontAwesomeIcons.wandMagicSparkles,
      label: 'Surprise me',
      prompt:
          'A varied day—one iconic site, one food stop, one hidden gem, one cultural spot'
    ),
  ];

  void _showPlacesGroupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (c) => _PlacesGroupPicker(
        placeCount: _preferredPlaceCount,
        groupSize: _groupSize,
        onChanged: (places, people) {
          setState(() {
            _preferredPlaceCount = places;
            _groupSize = people;
          });
          _scheduleAutoRun();
          Navigator.pop(c);
        },
      ),
    );
  }

  void _showInterestsSheet(BuildContext context) {
    final ip = Provider.of<InterestsProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => _InterestsPicker(
        selectedIds: _selectedInterests,
        interests: ip.interests,
        onChanged: (ids) {
          setState(() => _selectedInterests = ids);
          ip.setSelected(ids);
          _scheduleAutoRun();
          Navigator.pop(c);
        },
      ),
    );
  }

  void _showInputsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Configure your plan', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Set your trip details so the AI creates the perfect plan.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded),
                title: const Text('Date'),
                subtitle: Text(_selectedDate != null ? DateFormat('MMM d, y').format(_selectedDate!) : 'Not set'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickDate();
                },
              ),
              ListTile(
                leading: const Icon(Icons.today_rounded),
                title: Text(AppLocalizations.of(context)!.duration),
                subtitle: Text('$_duration ${_duration == 1 ? AppLocalizations.of(context)!.day : AppLocalizations.of(context)!.days}'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDurationPicker(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.place_rounded),
                title: const Text('Places per day'),
                subtitle: Text('Exactly $_placesPerDay places each day'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPlacesPerDayPicker(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_rounded),
                title: Text(AppLocalizations.of(context)!.budget),
                subtitle: Text(_budget),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    builder: (c) => _BudgetPicker(
                      value: _budget,
                      onChanged: (v) {
                        setState(() => _budget = v);
                        _scheduleAutoRun();
                        Navigator.pop(c);
                      },
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.groups_rounded),
                title: Text(AppLocalizations.of(context)!.placesAndGroup),
                subtitle: Text('${_preferredPlaceCount ?? '?'} places · ${_groupSize ?? '?'} people'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPlacesGroupSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.interests_rounded),
                title: Text(AppLocalizations.of(context)!.yourInterests),
                subtitle: Text(_selectedInterests.isEmpty ? 'None' : '${_selectedInterests.length} selected'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showInterestsSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('View / Edit activity log'),
                subtitle: const Text('Last 120 actions — remove items or clear'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showActivityLogSheet(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Consumer<ActivityLogProvider>(
          builder: (_, activityLog, __) => _ActivityLogEditor(
            events: activityLog.events,
            onRemoveAt: (index) => activityLog.removeAt(index),
            onClearAll: () {
              activityLog.clear();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  void _showDurationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (c) => _DurationPicker(
        value: _duration,
        onChanged: (v) async {
          setState(() => _duration = v);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_keyPlannerDays, v);
          await prefs.setBool(_keyPlannerPrefsSet, true);
          if (c.mounted) Navigator.pop(c);
        },
      ),
    );
  }

  void _showPlacesPerDayPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (c) => _PlacesPerDayPicker(
        value: _placesPerDay,
        onChanged: (v) async {
          setState(() => _placesPerDay = v);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_keyPlannerPlacesPerDay, v);
          await prefs.setBool(_keyPlannerPrefsSet, true);
          if (c.mounted) Navigator.pop(c);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final interestsProvider =
        Provider.of<InterestsProvider>(context, listen: false);
    _selectedInterests = List.from(interestsProvider.selectedIds);
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _preferredPlaceCount = 5;
    _groupSize = 2;
    if (_chatMessages.isEmpty) {
      _chatMessages.add(const _ChatMessage(
        isUser: false,
        text: 'Hi! I can help you plan your trip to Tripoli. Tell me how many days you have, what you like (food, history, culture, shopping), or just say what you want to do—I’ll suggest a plan.',
      ));
    }
    // Ensure places are loaded from the database (via backend) so the planner has data.
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    if (placesProvider.places.isEmpty) {
      placesProvider.loadPlaces();
    }
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    _aiLanguage = langProvider.currentLanguage.code;
    _loadPlannerPrefs();
  }

  Future<void> _loadPlannerPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPrefs = prefs.getBool(_keyPlannerPrefsSet) ?? false;
    if (hasPrefs) {
      final d = prefs.getInt(_keyPlannerDays);
      final p = prefs.getInt(_keyPlannerPlacesPerDay);
      if (mounted) {
        setState(() {
          if (d != null && d >= 1 && d <= 7) _duration = d;
          if (p != null && p >= 1 && p <= 10) _placesPerDay = p;
        });
      }
      return;
    }
    // No dialog: use defaults (1 day, 4 places per day)
    if (mounted) {
      setState(() {
        _duration = 1;
        _placesPerDay = 4;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Enforces exactly [expectedCount] slots across [durationDays], truncating or padding as needed.
  List<AIPlannerSlot> _enforceExactSlotCount({
    required List<AIPlannerSlot> slotList,
    required List<Place> places,
    required int expectedCount,
    required int durationDays,
  }) {
    final placesPerDay = expectedCount ~/ durationDays;

    if (slotList.length >= expectedCount) {
      // Truncate: group by day, take exactly placesPerDay per day to keep balance
      final byDay = <int, List<AIPlannerSlot>>{};
      for (final s in slotList) {
        final d = s.dayIndex ?? 0;
        byDay.putIfAbsent(d, () => []).add(s);
      }
      for (final daySlots in byDay.values) {
        daySlots.sort((a, b) => a.suggestedTime.compareTo(b.suggestedTime));
      }
      final result = <AIPlannerSlot>[];
      for (var d = 0; d < durationDays; d++) {
        final daySlots = byDay[d] ?? [];
        for (var i = 0; i < placesPerDay && i < daySlots.length; i++) {
          result.add(daySlots[i]);
        }
      }
      return result;
    }

    // Pad: add more places from pool (excluding already used)
    final usedIds = slotList.map((s) => s.placeId).toSet();
    final available = places.where((p) => !usedIds.contains(p.id)).toList();
    if (available.isEmpty) return slotList;

    final result = List<AIPlannerSlot>.from(slotList);
    var slotIndex = slotList.length;
    while (result.length < expectedCount && available.isNotEmpty) {
      final dayIdx = slotIndex ~/ placesPerDay;
      if (dayIdx >= durationDays) break;
      final place = available.removeAt(0);
      final slotInDay = result.where((s) => (s.dayIndex ?? 0) == dayIdx).length;
      result.add(AIPlannerSlot(
        placeId: place.id,
        suggestedTime: '${9 + slotInDay}:00',
        reason: 'Added to complete your plan',
        dayIndex: dayIdx,
      ));
      slotIndex++;
    }
    result.sort((a, b) {
      final d0 = a.dayIndex ?? 0;
      final d1 = b.dayIndex ?? 0;
      if (d0 != d1) return d0.compareTo(d1);
      return a.suggestedTime.compareTo(b.suggestedTime);
    });
    return result;
  }

  void _retryLastMessage() {
    if (_lastFailedUserMessage == null || _lastFailedUserMessage!.isEmpty || _isGenerating) return;
    if (_chatMessages.length < 2) return;
    setState(() {
      _chatMessages.removeLast(); // remove error bubble
      _chatMessages.removeLast(); // remove user message
      _inputController.text = _lastFailedUserMessage!;
    });
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    HapticFeedback.lightImpact();
    _inputController.clear();
    setState(() {
      _chatMessages.add(_ChatMessage(isUser: true, text: text));
      _isGenerating = true;
      _lastFailedUserMessage = null;
    });
    _scrollToBottom();

    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    var places = placesProvider.places
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();
    if (places.isEmpty) places = placesProvider.places;

    if (places.isEmpty) {
      await placesProvider.loadPlaces();
      if (!mounted) return;
      places = placesProvider.places.where((p) => p.latitude != null && p.longitude != null).toList();
      if (places.isEmpty) places = placesProvider.places;
    }

    if (places.isEmpty) {
      if (!mounted) return;
      setState(() {
        _chatMessages.add(const _ChatMessage(
          isUser: false,
          text: "Couldn't load places from the database. Check your connection and that the backend is running, then try again.",
        ));
        _isGenerating = false;
      });
      _scrollToBottom();
      return;
    }

    final interestsProvider = Provider.of<InterestsProvider>(context, listen: false);
    final idToInterest = {for (final i in interestsProvider.interests) i.id: i};
    final userInterests = _selectedInterests
        .map((id) => idToInterest[id]?.name)
        .whereType<String>()
        .toList();
    final activityLog = Provider.of<ActivityLogProvider>(context, listen: false);
    final activityContext = activityLog.getContextForAI();

    final history = _chatMessages
        .where((m) => m.text.isNotEmpty)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();

    try {
      var result = await AIPlannerService.chatForTripPlan(
        conversationHistory: history,
        userMessage: text,
        places: places,
        durationDays: _duration,
        placesPerDay: _placesPerDay,
        budget: _budget,
        selectedDate: _selectedDate,
        userInterests: userInterests.isNotEmpty ? userInterests : null,
        activityContext: activityContext.isNotEmpty ? activityContext : null,
        responseLanguage: _aiLanguage,
        previousSlots: _lastPlanSlots,
        previousPlaces: _lastPlanPlaces,
      );

      List<Place>? resolvedPlaces;
      List<AIPlannerSlot>? slots = result.slots;
      if (slots != null && slots.isNotEmpty) {
        var slotList = slots;
        if (_duration > 1 && slotList.every((s) => s.dayIndex == null || s.dayIndex == 0)) {
          final perDay = (slotList.length / _duration).ceil().clamp(1, slotList.length);
          slotList = <AIPlannerSlot>[];
          for (var i = 0; i < slots.length; i++) {
            final dayIdx = (i / perDay).floor().clamp(0, _duration - 1);
            final slotInDay = i - (dayIdx * perDay);
            slotList.add(AIPlannerSlot(
              placeId: slots[i].placeId,
              suggestedTime: '${9 + slotInDay}:00',
              reason: slots[i].reason,
              dayIndex: dayIdx,
            ));
          }
        }
        final idToPlace = {for (var p in places) p.id: p};
        // Enforce exact count: duration × placesPerDay
        final expectedCount = _duration * _placesPerDay;
        if (slotList.length != expectedCount) {
          slotList = _enforceExactSlotCount(
            slotList: slotList,
            places: places,
            expectedCount: expectedCount,
            durationDays: _duration,
          );
        }
        // Only keep slots whose placeId exists in our list so places and slots stay in sync
        final validSlots = <AIPlannerSlot>[];
        final validPlaces = <Place>[];
        for (final s in slotList) {
          final p = idToPlace[s.placeId];
          if (p != null) {
            validSlots.add(s);
            validPlaces.add(p);
          }
        }
        if (validSlots.isNotEmpty) {
          slots = validSlots;
          resolvedPlaces = validPlaces;
        } else {
          slots = null;
          resolvedPlaces = null;
        }
      }

      if (!mounted) return;
      final isEmptyReply = result.text.startsWith('Sorry, I couldn\'t reply') || result.text.startsWith('Something went wrong');
      setState(() {
        _chatMessages.add(_ChatMessage(
          isUser: false,
          text: result.text,
          slots: slots,
          places: resolvedPlaces,
          isRetryable: isEmptyReply,
        ));
        if (slots != null && resolvedPlaces != null && slots.isNotEmpty && resolvedPlaces.isNotEmpty) {
          _lastPlanSlots = slots;
          _lastPlanPlaces = resolvedPlaces;
        }
        _isGenerating = false;
        if (isEmptyReply) {
          _lastFailedUserMessage = text;
        } else {
          _lastFailedUserMessage = null;
        }
      });
      _scrollToBottom();
    } on AIPlannerApiException catch (e) {
      if (!mounted) return;
      final displayMessage = e.detail != null && e.detail!.trim().isNotEmpty
          ? '${e.userMessage}\n\n${e.detail}'
          : e.userMessage;
      setState(() {
        _lastFailedUserMessage = text;
        _chatMessages.add(_ChatMessage(isUser: false, text: displayMessage, isRetryable: true));
        _isGenerating = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastFailedUserMessage = text;
        _chatMessages.add(const _ChatMessage(
          isUser: false,
          text: 'Something went wrong. Please try again.',
          isRetryable: true,
        ));
        _isGenerating = false;
      });
      _scrollToBottom();
    }
  }

  void _requestPlanFromInterestsAndActivity() {
    _inputController.text =
        'Create a plan based on my selected interests and my recent activity in the app '
        '(places I viewed, categories I browsed, searches, and tabs I opened—last 120). '
        'Suggest an itinerary I can edit.';
    _sendMessage();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scheduleAutoRun() {} // No-op for chat mode (inputs menu still updates state)

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _scheduleAutoRun();
    }
  }

  void _saveAsTrip(List<Place> places, List<AIPlannerSlot> slots) {
    if (places.isEmpty || slots.isEmpty || _selectedDate == null) return;

    // Use actual number of days from slots so we save all days, not just first
    final maxDayIndex = slots.fold<int>(0, (m, s) {
      final d = s.dayIndex ?? 0;
      return d > m ? d : m;
    });
    final dayCount = maxDayIndex + 1;

    final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
    final endDate = _selectedDate!.add(Duration(days: dayCount - 1));
    if (tripsProvider.hasDateConflict(_selectedDate!, endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have a trip on this date.'),
        ),
      );
      return;
    }

    final hasMultiDay = dayCount > 1;
    final trip = Trip(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      name: dayCount > 1
          ? 'AI Plan - ${DateFormat('MMM d').format(_selectedDate!)} – ${DateFormat('MMM d').format(endDate)}'
          : 'AI Plan - ${DateFormat('MMM d').format(_selectedDate!)}',
      startDate: _selectedDate!,
      endDate: endDate,
      days: List.generate(dayCount, (dayIndex) {
        final dayDate = _selectedDate!.add(Duration(days: dayIndex));
        final dateStr = DateFormat('yyyy-MM-dd').format(dayDate);
        List<Place> placesForDay;
        List<AIPlannerSlot> slotsForDay;
        if (hasMultiDay) {
          final indices = <int>[];
          for (var i = 0; i < slots.length; i++) {
            if ((slots[i].dayIndex ?? 0) == dayIndex) indices.add(i);
          }
          placesForDay = indices.map((i) => places[i]).toList();
          slotsForDay = indices.map((i) => slots[i]).toList();
        } else {
          placesForDay = places;
          slotsForDay = slots;
        }
        return TripDay(
          date: dateStr,
          slots: placesForDay
              .asMap()
              .entries
              .map((e) => TripSlot(
                    placeId: e.value.id,
                    startTime: e.key < slotsForDay.length
                        ? slotsForDay[e.key].suggestedTime
                        : '${9 + e.key}:00',
                    endTime: null,
                    notes: e.key < slotsForDay.length ? slotsForDay[e.key].reason : null,
                  ))
              .toList(),
        );
      }),
      createdAt: DateTime.now(),
    );
    tripsProvider.addTrip(trip);
    final placeNames = places.map((p) => p.name).toList();
    Provider.of<ActivityLogProvider>(context, listen: false).tripSaved(placeNames);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip saved!')),
    );
    context.go('/trips');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleSpacing: 0,
        title: _PlannerHeader(
          greeting: _greetingL10n(context),
          userName: Provider.of<AuthProvider>(context).userName,
          onProfileTap: () {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (auth.isGuest) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.loginRequired),
                  content: Text(AppLocalizations.of(context)!.signInToAccessProfile),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/login');
                      },
                      child: Text(AppLocalizations.of(context)!.signIn),
                    ),
                  ],
                ),
              );
            } else {
              context.push('/profile');
            }
          },
          onMenuTap: () => _showInputsMenu(context),
        ),
      ),
      body: Column(
        children: [
          _PlannerTripSetupCard(
            duration: _duration,
            placesPerDay: _placesPerDay,
            selectedDate: _selectedDate,
            onDurationTap: () => _showDurationPicker(context),
            onPlacesTap: () => _showPlacesPerDayPicker(context),
            onDateTap: _pickDate,
          ),
          Expanded(
            child: _chatMessages.length <= 1
                ? _WelcomeHero(
                    inputController: _inputController,
                    isGenerating: _isGenerating,
                    onSend: _sendMessage,
                    moodCards: _moodCards,
                    onChipTap: (prompt) {
                      _inputController.text = prompt;
                      _sendMessage();
                    },
                    onPlanFromInterestsAndActivity: _requestPlanFromInterestsAndActivity,
                    welcomeText: _chatMessages.isEmpty ? null : _chatMessages.first.text,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveUtils.isSmallPhone(context) ? 10 : 16,
                      12,
                      ResponsiveUtils.isSmallPhone(context) ? 10 : 16,
                      20,
                    ),
                    itemCount: _chatMessages.length + (_isGenerating ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _chatMessages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.primaryColor,
                                child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                              ),
                              SizedBox(width: 12),
                              _TypingDots(),
                            ],
                          ),
                        );
                      }
                      final msg = _chatMessages[index];
                      return _ChatBubble(
                        message: msg,
                        onPlaceTap: (p) => context.push('/place/${p.id}'),
                        onSaveTrip: (msg.places != null && msg.places!.isNotEmpty && msg.slots != null && msg.slots!.isNotEmpty)
                            ? (places, slots) => _saveAsTrip(places, slots)
                            : null,
                        onPlanChanged: (msg.places != null && msg.slots != null)
                            ? (slots, places) {
                                setState(() {
                                  _lastPlanSlots = slots;
                                  _lastPlanPlaces = places;
                                });
                              }
                            : null,
                        onRetry: msg.isRetryable ? _retryLastMessage : null,
                      );
                    },
                  ),
          ),
          if (_chatMessages.length > 1)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + MediaQuery.of(context).padding.bottom),
              child: SafeArea(
                top: false,
                child: _PlannerInputBar(
                  controller: _inputController,
                  isGenerating: _isGenerating,
                  onSend: _sendMessage,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

class _PlannerHeader extends StatelessWidget {
  final String greeting;
  final String? userName;
  final VoidCallback onProfileTap;
  final VoidCallback onMenuTap;

  const _PlannerHeader({
    required this.greeting,
    required this.userName,
    required this.onProfileTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (userName != null && userName!.trim().isNotEmpty)
        ? userName!.trim()
        : 'Traveler';
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 4, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.35),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Material(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onMenuTap,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.tune_rounded, size: 22, color: AppTheme.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary trip parameters for the AI — always visible, tappable, clearly labeled.
class _PlannerTripSetupCard extends StatelessWidget {
  final int duration;
  final int placesPerDay;
  final DateTime? selectedDate;
  final VoidCallback onDurationTap;
  final VoidCallback onPlacesTap;
  final VoidCallback onDateTap;

  const _PlannerTripSetupCard({
    required this.duration,
    required this.placesPerDay,
    required this.selectedDate,
    required this.onDurationTap,
    required this.onPlacesTap,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final durationValue =
        '$duration ${duration == 1 ? l10n.day : l10n.days}';
    final dateValue = selectedDate != null
        ? DateFormat('MMM d').format(selectedDate!)
        : l10n.pickDate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.route_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.plannerTripSetupTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                          color: AppTheme.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.plannerTripSetupSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppTheme.textSecondary.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 342;
                final durationW = _PlannerSetupTile(
                  label: l10n.plannerSetupDurationLabel,
                  value: durationValue,
                  icon: Icons.calendar_view_week_rounded,
                  onTap: onDurationTap,
                );
                final paceW = _PlannerSetupTile(
                  label: l10n.plannerSetupPaceLabel,
                  value: l10n.plannerPacePerDayValue(placesPerDay),
                  icon: Icons.directions_walk_rounded,
                  onTap: onPlacesTap,
                );
                final dateW = _PlannerSetupTile(
                  label: l10n.plannerSetupStartLabel,
                  value: dateValue,
                  icon: Icons.event_available_rounded,
                  onTap: onDateTap,
                  trailingIcon: Icons.edit_calendar_rounded,
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: durationW),
                          const SizedBox(width: 10),
                          Expanded(child: paceW),
                        ],
                      ),
                      const SizedBox(height: 10),
                      dateW,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: durationW),
                    const SizedBox(width: 10),
                    Expanded(child: paceW),
                    const SizedBox(width: 10),
                    Expanded(child: dateW),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannerSetupTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  const _PlannerSetupTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceVariant.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(icon, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (trailingIcon != null)
                    Icon(
                      trailingIcon,
                      size: 15,
                      color: AppTheme.textTertiary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplacePlaceSheet extends StatefulWidget {
  final List<Place> places;
  final Place currentPlace;

  const _ReplacePlaceSheet({
    required this.places,
    required this.currentPlace,
  });

  @override
  State<_ReplacePlaceSheet> createState() => _ReplacePlaceSheetState();
}

class _ReplacePlaceSheetState extends State<_ReplacePlaceSheet> {
  String _query = '';

  List<Place> get _filtered {
    if (_query.trim().isEmpty) return widget.places;
    final q = _query.trim().toLowerCase();
    return widget.places
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q) ||
            (p.category.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final safePadding = MediaQuery.of(context).padding.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Change this place',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search places...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textTertiary, size: 22),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No places match "$_query"',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + safePadding),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final place = filtered[index];
                      final isCurrent = place.id == widget.currentPlace.id;
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: isCurrent
                                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                : AppTheme.surfaceVariant,
                            child: Icon(
                              Icons.place_rounded,
                              color: isCurrent ? AppTheme.primaryColor : AppTheme.textSecondary,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            place.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isCurrent ? AppTheme.primaryColor : AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: place.location.isNotEmpty
                              ? Text(
                                  place.location,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: isCurrent
                              ? const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Text('Current', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                                )
                              : const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
                          onTap: () {
                            if (!isCurrent) Navigator.of(context).pop(place);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  final TextEditingController inputController;
  final bool isGenerating;
  final VoidCallback onSend;
  final List<({IconData icon, String label, String prompt})> moodCards;
  final void Function(String prompt) onChipTap;
  final VoidCallback? onPlanFromInterestsAndActivity;
  final String? welcomeText;

  const _WelcomeHero({
    required this.inputController,
    required this.isGenerating,
    required this.onSend,
    required this.moodCards,
    required this.onChipTap,
    this.onPlanFromInterestsAndActivity,
    this.welcomeText,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                  AppTheme.secondaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryColor, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Tripoli Plan',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AI-crafted itinerary tailored to your trip settings.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Tell the planner what you feel like—culture, food, souks, history—or start from one of the quick ideas below.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (onPlanFromInterestsAndActivity != null) ...[
                  const SizedBox(height: 18),
                  InkWell(
                    onTap: isGenerating ? null : onPlanFromInterestsAndActivity,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.interests_rounded, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Plan from your interests & activity',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Uses what you like and where you have browsed recently. You can still edit every stop.',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _PlannerInputBar(
            controller: inputController,
            isGenerating: isGenerating,
            onSend: onSend,
            large: true,
          ),
          const SizedBox(height: 28),
          Text(
            'Quick start',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: moodCards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final card = moodCards[index];
                return IgnorePointer(
                  ignoring: isGenerating,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onChipTap(card.prompt);
                      },
                      borderRadius: BorderRadius.circular(23),
                      splashColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                      highlightColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isGenerating ? 0.5 : 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(card.icon, size: 18, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                card.label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (welcomeText != null && welcomeText!.isNotEmpty) ...[
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(4),
                        topRight: const Radius.circular(18),
                        bottomLeft: const Radius.circular(18),
                        bottomRight: const Radius.circular(18),
                      ),
                    ),
                    child: Text(
                      welcomeText!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PlannerInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isGenerating;
  final VoidCallback onSend;
  final bool large;

  const _PlannerInputBar({
    required this.controller,
    required this.isGenerating,
    required this.onSend,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = large ? 28.0 : 24.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 20 : 14,
        vertical: large ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: TextStyle(
                  fontSize: large ? 16 : 15,
                  color: AppTheme.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: large ? 12 : 10,
                ),
                isDense: true,
              ),
              maxLines: large ? 2 : 3,
              minLines: 1,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: isGenerating ? null : onSend,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: large ? 48 : 44,
                height: large ? 48 : 44,
                alignment: Alignment.center,
                child: isGenerating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_controller.value + i * 0.25) % 1.0;
              final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Padding(
                padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Strips any PLAN_JSON or raw JSON from AI response so we never show it as text.
String _displayTextForMessage(_ChatMessage message) {
  String t = message.text.trim();
  final planIdx = RegExp(r'PLAN_JSON\s*:', caseSensitive: false).firstMatch(t);
  if (planIdx != null) t = t.substring(0, planIdx.start).trim();
  if (t.contains(r'"placeId"') || (t.trim().startsWith('[') && t.contains(']'))) t = '';
  if (t.isEmpty && message.slots != null && message.places != null && message.places!.isNotEmpty) {
    return 'Here’s your plan for Tripoli:';
  }
  final hasCard = message.slots != null &&
      message.slots!.isNotEmpty &&
      message.places != null &&
      message.places!.isNotEmpty;
  if (t.isEmpty && hasCard) return 'Here\'s your plan for Tripoli:';
  if (t.isEmpty || t == ' ') {
    return 'The plan couldn\'t be displayed. Try: "Suggest a 1-day itinerary for Tripoli" or tap Try again.';
  }
  return t;
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final void Function(Place) onPlaceTap;
  final void Function(List<Place> places, List<AIPlannerSlot> slots)? onSaveTrip;
  final void Function(List<AIPlannerSlot> slots, List<Place> places)? onPlanChanged;
  final VoidCallback? onRetry;

  const _ChatBubble({
    required this.message,
    required this.onPlaceTap,
    this.onSaveTrip,
    this.onPlanChanged,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = _displayTextForMessage(message);
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final planSideInset = narrow ? 6.0 : 54.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser)
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                ),
              if (!message.isUser) const SizedBox(width: 12),
              Flexible(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                      padding: EdgeInsets.symmetric(
                        horizontal: narrow ? 14 : 18,
                        vertical: narrow ? 12 : 14,
                      ),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? AppTheme.primaryColor
                            : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(message.isUser ? 20 : 6),
                          bottomRight: Radius.circular(message.isUser ? 6 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        displayText,
                        style: TextStyle(
                          color: message.isUser ? Colors.white : AppTheme.textPrimary,
                          fontSize: narrow ? 14 : 15,
                          height: narrow ? 1.42 : 1.45,
                        ),
                        maxLines: 25,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    );
                  },
                ),
              ),
              if (message.isUser) const SizedBox(width: 12),
              if (message.isUser)
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                ),
            ],
          ),
          if (message.isRetryable && onRetry != null && !message.isUser) ...[
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: planSideInset),
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onRetry!();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.primaryColor),
                label: const Text('Try again', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
              ),
            ),
          ],
          if (message.places != null && message.places!.isNotEmpty && message.slots != null) ...[
            const SizedBox(height: 18),
            Padding(
              padding: message.isUser
                  ? EdgeInsets.only(right: planSideInset)
                  : EdgeInsets.only(left: planSideInset),
              child: _EditableItineraryCard(
                slots: message.slots!,
                places: message.places!,
                onPlaceTap: onPlaceTap,
                onSaveTrip: onSaveTrip,
                onPlanChanged: onPlanChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ignore: unused_element
class _WorkflowNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final Widget? child;
  final Widget? trailing;

  const _WorkflowNode({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              if (child != null) ...[
                const SizedBox(height: 16),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _WorkflowConnector extends StatelessWidget {
  const _WorkflowConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: AppTheme.borderColor,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _TripDetailsCard extends StatelessWidget {
  final DateTime? selectedDate;
  final int duration;
  final String budget;
  final int? preferredPlaceCount;
  final int? groupSize;
  final VoidCallback onPickDate;
  final void Function(int) onDurationChanged;
  final void Function(String) onBudgetChanged;
  final VoidCallback onPlacesGroupTap;
  final VoidCallback onInterestsTap;
  final int selectedInterestsCount;

  const _TripDetailsCard({
    required this.selectedDate,
    required this.duration,
    required this.budget,
    required this.preferredPlaceCount,
    required this.groupSize,
    required this.onPickDate,
    required this.onDurationChanged,
    required this.onBudgetChanged,
    required this.onPlacesGroupTap,
    required this.onInterestsTap,
    required this.selectedInterestsCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date row
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      selectedDate != null
                          ? DateFormat('EEE, MMM d').format(selectedDate!)
                          : l10n.date,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_rounded, size: 18, color: AppTheme.textTertiary),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 20),
          // Duration
          Text(l10n.duration, style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [1, 2, 3].map((d) {
              final sel = duration == d;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: d < 3 ? 8 : 0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onDurationChanged(d),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.primaryColor.withValues(alpha: 0.12) : AppTheme.surfaceVariant.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? AppTheme.primaryColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '$d ${d == 1 ? l10n.day : l10n.days}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: sel ? AppTheme.primaryColor : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Budget
          Text(l10n.budgetLabel, style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: ['free', 'budget', 'moderate', 'luxury'].map((b) {
              final labels = {
                'free': l10n.free,
                'budget': l10n.budgetTier,
                'moderate': l10n.moderate,
                'luxury': l10n.luxury,
              };
              final sel = budget == b;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onBudgetChanged(b),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.primaryColor.withValues(alpha: 0.12) : AppTheme.surfaceVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          labels[b] ?? b,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: sel ? AppTheme.primaryColor : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Places & group + Interests
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPlacesGroupTap,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.groups_rounded, size: 20, color: AppTheme.textSecondary),
                          const SizedBox(width: 10),
                          Text(
                            '${preferredPlaceCount ?? '?'} places · ${groupSize ?? '?'} people',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onInterestsTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.interests_rounded, size: 20, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          selectedInterestsCount > 0 ? '$selectedInterestsCount' : '—',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _YourVibeCard extends StatelessWidget {
  final List<(IconData, String, String)> moodCards;
  final String selectedPrompt;
  final TextEditingController promptController;
  final VoidCallback onPromptChanged;
  final void Function(String label, String prompt) onMoodTap;

  const _YourVibeCard({
    required this.moodCards,
    required this.selectedPrompt,
    required this.promptController,
    required this.onPromptChanged,
    required this.onMoodTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: moodCards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final c = moodCards[i];
                final sel = selectedPrompt == c.$3;
                return _MoodCard(
                  icon: c.$1,
                  label: c.$2,
                  onTap: () => onMoodTap(c.$2, c.$3),
                  selected: sel,
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: promptController,
            onChanged: (_) => onPromptChanged(),
            decoration: InputDecoration(
              hintText: 'Or describe your ideal day...',
              hintStyle: const TextStyle(color: AppTheme.textTertiary),
              filled: true,
              fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _GenerateButton extends StatelessWidget {
  final bool isGenerating;
  final bool canGenerate;
  final VoidCallback onTap;

  const _GenerateButton({
    required this.isGenerating,
    required this.canGenerate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (canGenerate && !isGenerating) ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: canGenerate && !isGenerating
                  ? [const Color(0xFF0F766E), const Color(0xFF0D9488)]
                  : [AppTheme.textTertiary.withValues(alpha: 0.4), AppTheme.textTertiary.withValues(alpha: 0.3)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (canGenerate && !isGenerating ? AppTheme.primaryColor : Colors.grey).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: isGenerating
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Text('Creating your plan...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  ],
                )
              : Text(
                  'Generate my plan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: canGenerate ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _RefineChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _RefineChip({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ActivityContextCard extends StatelessWidget {
  final String summary;
  final String contextText;
  final bool expanded;
  final bool hasContext;
  final VoidCallback onTap;

  const _ActivityContextCard({
    required this.summary,
    required this.contextText,
    required this.expanded,
    required this.hasContext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0EA5E9);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasContext ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                accent.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.insights_rounded, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Context from your activity',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (hasContext)
                    Icon(
                      expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: accent,
                      size: 24,
                    ),
                ],
              ),
              if (expanded && contextText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    contextText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _MoodCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor.withValues(alpha: 0.12) : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, color: AppTheme.primaryColor, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One stop in the editable plan (place + slot), grouped by day.
class _PlanEntry {
  final Place place;
  AIPlannerSlot slot;

  _PlanEntry(this.place, this.slot);
}

/// Editable itinerary: reorder within day, remove stop, edit time. Save passes edited lists.
class _EditableItineraryCard extends StatefulWidget {
  final List<AIPlannerSlot> slots;
  final List<Place> places;
  final void Function(Place) onPlaceTap;
  final void Function(List<Place> places, List<AIPlannerSlot> slots)? onSaveTrip;
  final void Function(List<AIPlannerSlot> slots, List<Place> places)? onPlanChanged;

  const _EditableItineraryCard({
    required this.slots,
    required this.places,
    required this.onPlaceTap,
    this.onSaveTrip,
    this.onPlanChanged,
  });

  @override
  State<_EditableItineraryCard> createState() => _EditableItineraryCardState();
}

class _EditableItineraryCardState extends State<_EditableItineraryCard> {
  /// Per-day list of (place, slot). Index = dayIndex.
  late List<List<_PlanEntry>> _days;

  @override
  void initState() {
    super.initState();
    _initFromProps();
  }

  @override
  void didUpdateWidget(covariant _EditableItineraryCard oldWidget) {
    if (oldWidget.places != widget.places || oldWidget.slots != widget.slots) {
      _initFromProps();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _initFromProps() {
    final hasMultiDay = widget.slots.any((s) => s.dayIndex != null && s.dayIndex! > 0);
    if (hasMultiDay) {
      final maxDay = widget.slots.fold<int>(0, (m, s) => (s.dayIndex ?? 0) > m ? (s.dayIndex ?? 0) : m);
      _days = List.generate(maxDay + 1, (_) => []);
      for (var i = 0; i < widget.places.length; i++) {
        final dayIdx = i < widget.slots.length ? (widget.slots[i].dayIndex ?? 0) : 0;
        if (dayIdx < _days.length) {
          _days[dayIdx].add(_PlanEntry(widget.places[i], widget.slots[i]));
        }
      }
    } else {
      _days = [
        widget.places.asMap().entries.map((e) {
          final slot = e.key < widget.slots.length ? widget.slots[e.key] : AIPlannerSlot(
            placeId: e.value.id,
            suggestedTime: '${9 + e.key}:00',
            reason: null,
            dayIndex: 0,
          );
          return _PlanEntry(e.value, slot);
        }).toList(),
      ];
    }
  }

  void _remove(int dayIndex, int entryIndex) {
    setState(() {
      _days[dayIndex].removeAt(entryIndex);
      if (_days[dayIndex].isEmpty) {
        _days.removeAt(dayIndex);
      } else {
        _updateTimesForDay(dayIndex);
      }
      _notifyPlanChanged();
    });
  }

  /// Reassigns times for the day so they follow chronological order (9:00, 10:30, 12:00, ...).
  void _updateTimesForDay(int dayIndex) {
    final day = _days[dayIndex];
    if (day.isEmpty) return;
    const startMinutes = 9 * 60; // 9:00
    const slotMinutes = 90; // 1.5 hours between stops
    for (var i = 0; i < day.length; i++) {
      final totalMinutes = startMinutes + i * slotMinutes;
      final h = totalMinutes ~/ 60;
      final m = totalMinutes % 60;
      final timeStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      final entry = day[i];
      entry.slot = AIPlannerSlot(
        placeId: entry.slot.placeId,
        suggestedTime: timeStr,
        reason: entry.slot.reason,
        dayIndex: entry.slot.dayIndex,
      );
    }
  }

  void _reorder(int dayIndex, int oldIndex, int newIndex) {
    setState(() {
      final day = _days[dayIndex];
      final entry = day.removeAt(oldIndex);
      day.insert(newIndex, entry);
      _updateTimesForDay(dayIndex);
      _notifyPlanChanged();
    });
  }

  void _replacePlace(int dayIndex, int entryIndex, Place newPlace) {
    setState(() {
      final entry = _days[dayIndex][entryIndex];
      _days[dayIndex][entryIndex] = _PlanEntry(
        newPlace,
        AIPlannerSlot(
          placeId: newPlace.id,
          suggestedTime: entry.slot.suggestedTime,
          reason: 'You chose to replace',
          dayIndex: entry.slot.dayIndex,
        ),
      );
      _notifyPlanChanged();
    });
  }

  Future<void> _showReplacePlacePicker(BuildContext context, int dayIndex, int entryIndex, Place currentPlace) async {
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    List<Place> places = placesProvider.places;
    if (places.isEmpty) {
      await placesProvider.loadPlaces();
      if (!context.mounted) return;
      places = placesProvider.places;
    }
    if (places.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No places available to choose from.')),
        );
      }
      return;
    }
    final selected = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReplacePlaceSheet(
        places: places,
        currentPlace: currentPlace,
      ),
    );
    if (selected != null && mounted) _replacePlace(dayIndex, entryIndex, selected);
  }

  Future<void> _editTime(int dayIndex, int entryIndex) async {
    final entry = _days[dayIndex][entryIndex];
    final controller = TextEditingController(text: entry.slot.suggestedTime);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit time'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. 9:00, 14:30',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim().isNotEmpty ? v.trim() : null),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim().isNotEmpty ? controller.text.trim() : null),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() {
        entry.slot = AIPlannerSlot(
          placeId: entry.slot.placeId,
          suggestedTime: result,
          reason: entry.slot.reason,
          dayIndex: entry.slot.dayIndex,
        );
        _notifyPlanChanged();
      });
    }
  }

  void _notifyPlanChanged() {
    final pair = _getCurrentSlotsAndPlaces();
    if (pair != null) widget.onPlanChanged?.call(pair.$1, pair.$2);
  }

  (List<AIPlannerSlot>, List<Place>)? _getCurrentSlotsAndPlaces() {
    final places = <Place>[];
    final slots = <AIPlannerSlot>[];
    var dayIndex = 0;
    for (var d = 0; d < _days.length; d++) {
      if (_days[d].isEmpty) continue;
      for (var i = 0; i < _days[d].length; i++) {
        final e = _days[d][i];
        places.add(e.place);
        slots.add(AIPlannerSlot(
          placeId: e.slot.placeId,
          suggestedTime: e.slot.suggestedTime,
          reason: e.slot.reason,
          dayIndex: _days.length > 1 ? dayIndex : 0,
        ));
      }
      dayIndex++;
    }
    if (places.isEmpty) return null;
    return (slots, places);
  }

  void _save() {
    final places = <Place>[];
    final slots = <AIPlannerSlot>[];
    var dayIndex = 0;
    for (var d = 0; d < _days.length; d++) {
      if (_days[d].isEmpty) continue;
      for (var i = 0; i < _days[d].length; i++) {
        final e = _days[d][i];
        places.add(e.place);
        slots.add(AIPlannerSlot(
          placeId: e.slot.placeId,
          suggestedTime: e.slot.suggestedTime,
          reason: e.slot.reason,
          dayIndex: _days.length > 1 ? dayIndex : 0,
        ));
      }
      dayIndex++;
    }
    if (places.isEmpty) return;
    widget.onSaveTrip?.call(places, slots);
  }

  @override
  Widget build(BuildContext context) {
    final totalPlaces = _days.fold<int>(0, (s, d) => s + d.length);
    final tightPlan = MediaQuery.sizeOf(context).width < 360;
    const cardRadius = 24.0;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrowHeader = constraints.maxWidth < 340;
              final titleBlock = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.map_rounded, color: AppTheme.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.yourPlan,
                          style: TextStyle(
                            fontSize: narrowHeader ? 16 : 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '$totalPlaces ${totalPlaces == 1 ? 'place' : 'places'} · ${_days.length} ${_days.length == 1 ? 'day' : 'days'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final saveBtn = widget.onSaveTrip != null
                  ? FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.acceptAndSave),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    )
                  : null;
              return Container(
                padding: EdgeInsets.fromLTRB(
                  narrowHeader ? 14 : 20,
                  narrowHeader ? 14 : 20,
                  narrowHeader ? 14 : 20,
                  narrowHeader ? 14 : 18,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.08),
                      AppTheme.primaryColor.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                child: narrowHeader && saveBtn != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          titleBlock,
                          const SizedBox(height: 12),
                          saveBtn,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: titleBlock),
                          if (saveBtn != null) ...[
                            const SizedBox(width: 8),
                            saveBtn,
                          ],
                        ],
                      ),
              );
            },
          ),
          ...List.generate(_days.length, (dayIndex) {
            final dayEntries = _days[dayIndex];
            if (dayEntries.isEmpty) return const SizedBox.shrink();
            final isFirstDay = dayIndex == 0;
            return Container(
              margin: EdgeInsets.fromLTRB(
                tightPlan ? 12 : 16,
                isFirstDay ? (tightPlan ? 12 : 16) : (tightPlan ? 16 : 20),
                tightPlan ? 12 : 16,
                tightPlan ? 12 : 16,
              ),
              padding: EdgeInsets.all(tightPlan ? 12 : 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Day ${dayIndex + 1}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${dayEntries.length} ${dayEntries.length == 1 ? 'stop' : 'stops'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: dayEntries.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex--;
                      _reorder(dayIndex, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final entry = dayEntries[index];
                      final isLast = index == dayEntries.length - 1;
                      return _PlanRow(
                        key: ValueKey('${entry.place.id}-$dayIndex-$index'),
                        reorderIndex: index,
                        place: entry.place,
                        slot: entry.slot,
                        showConnector: !isLast,
                        onTap: () => widget.onPlaceTap(entry.place),
                        onTimeTap: () => _editTime(dayIndex, index),
                        onRemove: () => _remove(dayIndex, index),
                        onReplace: () => _showReplacePlacePicker(context, dayIndex, index, entry.place),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final int reorderIndex;
  final Place place;
  final AIPlannerSlot slot;
  final bool showConnector;
  final VoidCallback onTap;
  final VoidCallback onTimeTap;
  final VoidCallback onRemove;
  final VoidCallback? onReplace;

  const _PlanRow({
    super.key,
    required this.reorderIndex,
    required this.place,
    required this.slot,
    this.showConnector = true,
    required this.onTap,
    required this.onTimeTap,
    required this.onRemove,
    this.onReplace,
  });

  static bool _isModificationReason(String? reason) {
    if (reason == null || reason.isEmpty) return false;
    final lower = reason.toLowerCase();
    return lower.contains('change') || lower.contains('wanted') || lower.contains('modify') || lower.contains('replace');
  }

  @override
  Widget build(BuildContext context) {
    final isModified = _isModificationReason(slot.reason);
    return Material(
      key: key,
      color: Colors.transparent,
      child: ReorderableDragStartListener(
        index: reorderIndex,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 56,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onTimeTap,
                        child: Container(
                          width: 48,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            slot.suggestedTime,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      if (showConnector)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            width: 2,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppTheme.primaryColor.withValues(alpha: 0.4),
                                  AppTheme.primaryColor.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: -0.2,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (place.location.isNotEmpty)
                            Icon(Icons.place_outlined, size: 14, color: AppTheme.textTertiary),
                        ],
                      ),
                      if (place.location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          place.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (slot.reason != null && slot.reason!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isModified
                                ? AppTheme.primaryColor.withValues(alpha: 0.08)
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            slot.reason!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isModified ? AppTheme.primaryColor : AppTheme.textTertiary,
                              fontStyle: FontStyle.italic,
                              fontWeight: isModified ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onReplace != null)
                  IconButton(
                    onPressed: onReplace,
                    icon: Icon(
                      Icons.swap_horiz_rounded,
                      size: 22,
                      color: AppTheme.primaryColor.withValues(alpha: 0.9),
                    ),
                    tooltip: 'Change place',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 22,
                    color: AppTheme.textTertiary.withValues(alpha: 0.9),
                  ),
                  tooltip: 'Remove',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ItineraryCard extends StatelessWidget {
  final List<AIPlannerSlot> slots;
  final List<Place> places;
  final void Function(Place) onPlaceTap;
  final VoidCallback? onSaveTrip;
  final void Function(Place)? onReplacePlace;

  const _ItineraryCard({
    required this.slots,
    required this.places,
    required this.onPlaceTap,
    this.onSaveTrip,
    this.onReplacePlace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.route_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.yourPlan,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onSaveTrip != null)
                  TextButton.icon(
                    onPressed: onSaveTrip,
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: Text(AppLocalizations.of(context)!.acceptAndSave),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...() {
            final hasMultiDay = slots.any((s) => s.dayIndex != null && s.dayIndex! > 0);
            int? lastDay;
            final list = <Widget>[];
            for (var i = 0; i < places.length; i++) {
              final place = places[i];
              final slot = i < slots.length ? slots[i] : null;
              if (hasMultiDay && slot?.dayIndex != null && slot!.dayIndex != lastDay) {
                lastDay = slot.dayIndex;
                list.add(
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(14, lastDay != null ? 16 : 12, 14, 6),
                    decoration: lastDay != null
                        ? BoxDecoration(
                            border: Border(top: BorderSide(color: AppTheme.borderColor, width: 1)),
                          )
                        : null,
                    child: Text(
                      'Day ${(slot.dayIndex! + 1)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                );
              }
              list.add(
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onPlaceTap(place),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              slot?.suggestedTime ?? '${9 + i}:00',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
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
                                  place.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (slot?.reason != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    slot!.reason!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textTertiary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (onReplacePlace != null)
                            IconButton(
                              onPressed: () => onReplacePlace!(place),
                              icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                              tooltip:
                                  AppLocalizations.of(context)!.replaceWithOption,
                              style: IconButton.styleFrom(
                                minimumSize: const Size(36, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.textTertiary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            return list;
          }(),
        ],
      ),
    );
  }
}

class _PlacesGroupPicker extends StatelessWidget {
  final int? placeCount;
  final int? groupSize;
  final void Function(int?, int?) onChanged;

  const _PlacesGroupPicker({
    this.placeCount,
    this.groupSize,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        var places = placeCount;
        var people = groupSize;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.placesAndGroup,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.howManyPlacesPeople,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.places),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int?>(
                          key: ValueKey('places_$places'),
                          initialValue: places,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: null,
                                child: Text(
                                    AppLocalizations.of(context)!.anyPlaces)),
                            const DropdownMenuItem(value: 3, child: Text('3')),
                            const DropdownMenuItem(value: 4, child: Text('4')),
                            const DropdownMenuItem(value: 5, child: Text('5')),
                            const DropdownMenuItem(value: 6, child: Text('6')),
                            const DropdownMenuItem(value: 7, child: Text('7')),
                            const DropdownMenuItem(value: 8, child: Text('8')),
                          ],
                          onChanged: (v) {
                            setState(() => places = v);
                            onChanged(v, people);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.people),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int?>(
                          key: ValueKey('people_$people'),
                          initialValue: people,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: null,
                                child: Text(AppLocalizations.of(context)!.all)),
                            const DropdownMenuItem(value: 1, child: Text('1')),
                            const DropdownMenuItem(value: 2, child: Text('2')),
                            const DropdownMenuItem(value: 3, child: Text('3')),
                            const DropdownMenuItem(value: 4, child: Text('4')),
                            const DropdownMenuItem(value: 5, child: Text('5')),
                            const DropdownMenuItem(value: 6, child: Text('6')),
                            const DropdownMenuItem(value: 8, child: Text('8')),
                            const DropdownMenuItem(
                                value: 10, child: Text('10')),
                          ],
                          onChanged: (v) {
                            setState(() => people = v);
                            onChanged(places, v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.done),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _plannerSelectionChip({
  required bool selected,
  required String label,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : AppTheme.surfaceVariant.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    ),
  );
}

class _DurationPicker extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;

  const _DurationPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const maxDays = 7;
    final days = List.generate(maxDays, (i) => i + 1);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.duration,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'How many days is your trip?',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: days.map((d) {
                final sel = value == d;
                return _plannerSelectionChip(
                  selected: sel,
                  label:
                      '$d ${d == 1 ? AppLocalizations.of(context)!.day : AppLocalizations.of(context)!.days}',
                  onTap: () => onChanged(d),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacesPerDayPicker extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;

  const _PlacesPerDayPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [2, 3, 4, 5, 6, 7, 8];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Places per day',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'The AI will suggest exactly this many places each day.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((p) {
                final sel = value == p;
                return _plannerSelectionChip(
                  selected: sel,
                  label: '$p places',
                  onTap: () => onChanged(p),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityLogEditor extends StatelessWidget {
  final List<ActivityEvent> events;
  final void Function(int index) onRemoveAt;
  final VoidCallback onClearAll;
  final ScrollController scrollController;

  const _ActivityLogEditor({
    required this.events,
    required this.onRemoveAt,
    required this.onClearAll,
    required this.scrollController,
  });

  static String _typeLabel(String type) {
    switch (type) {
      case 'place_viewed':
        return 'Place';
      case 'category_browsed':
        return 'Category';
      case 'search':
        return 'Search';
      case 'tab_visited':
        return 'Tab';
      case 'trip_saved':
        return 'Trip';
      case 'interests':
        return 'Interests';
      case 'planner_theme':
        return 'Theme';
      case 'planner_run':
        return 'Plan';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reversed = events.toList().reversed.toList();
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: AppTheme.primaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity log (last 120)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Used for "Plan from interests & activity". Remove items or clear all.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: events.isEmpty ? null : onClearAll,
                  icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                  label: const Text('Clear all'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Text(
                      'No activity yet. Use the app to view places, browse, and open tabs.',
                      style: TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: reversed.length,
                    itemBuilder: (context, i) {
                      final event = reversed[i];
                      final originalIndex = events.length - 1 - i;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _typeLabel(event.type),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        title: Text(
                          event.label,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          DateFormat('MMM d, HH:mm').format(event.at),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textSecondary),
                          onPressed: () => onRemoveAt(originalIndex),
                          tooltip: 'Remove',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BudgetPicker extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  const _BudgetPicker({required this.value, required this.onChanged});

  static List<_BudgetOption> _options(BuildContext context) => [
        _BudgetOption('free', AppLocalizations.of(context)!.free,
            Icons.money_off_rounded),
        _BudgetOption('budget', AppLocalizations.of(context)!.budgetTier,
            Icons.savings_rounded),
        _BudgetOption('moderate', AppLocalizations.of(context)!.moderate,
            Icons.attach_money_rounded),
        _BudgetOption('luxury', AppLocalizations.of(context)!.luxury,
            Icons.diamond_rounded),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.budgetLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ..._options(context).map((opt) {
            final sel = value == opt.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(opt.icon),
                title: Text(opt.label),
                selected: sel,
                onTap: () => onChanged(opt.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BudgetOption {
  final String id;
  final String label;
  final IconData icon;

  const _BudgetOption(this.id, this.label, this.icon);
}

class _InterestsPicker extends StatelessWidget {
  final List<String> selectedIds;
  final List<Interest> interests;
  final void Function(List<String>) onChanged;

  const _InterestsPicker({
    required this.selectedIds,
    required this.interests,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.interestsAiPrioritize,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((i) {
              final sel = selectedIds.contains(i.id);
              return FilterChip(
                selected: sel,
                label: Text(i.name),
                onSelected: (v) {
                  final next = List<String>.from(selectedIds);
                  if (v) {
                    next.add(i.id);
                  } else {
                    next.remove(i.id);
                  }
                  onChanged(next);
                },
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                checkmarkColor: AppTheme.primaryColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
