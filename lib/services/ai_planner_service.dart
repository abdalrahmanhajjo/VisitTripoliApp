import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../data/ai_planner_training_data.dart';
import '../data/tripoli_history.dart';
import '../models/category.dart' as models;
import '../models/place.dart';

/// Thrown when the AI API fails. Use [userMessage] for display to the user.
class AIPlannerApiException implements Exception {
  final String userMessage;
  final int? statusCode;
  final String? detail;

  AIPlannerApiException(this.userMessage, {this.statusCode, this.detail});

  @override
  String toString() => userMessage;
}

/// Result slot from AI: place ID + suggested time + optional reason + optional day (for multi-day plans).
class AIPlannerSlot {
  final String placeId;
  final String suggestedTime;
  final String? reason;
  /// 0-based day index when itinerary spans multiple days.
  final int? dayIndex;

  const AIPlannerSlot({
    required this.placeId,
    required this.suggestedTime,
    this.reason,
    this.dayIndex,
  });
}

/// Suggested place only (no time) — for the "suggest first" phase.
class AIPlannerSuggestion {
  final String placeId;
  final String? reason;

  const AIPlannerSuggestion({required this.placeId, this.reason});
}

/// Result of suggestPlaces: optional intro message when request doesn't match, plus places.
class SuggestPlacesResult {
  final String? alternativesMessage;
  final List<AIPlannerSuggestion> suggestions;

  const SuggestPlacesResult({
    this.alternativesMessage,
    required this.suggestions,
  });
}

/// One exchange in the conversation (for context).
class ConversationTurn {
  final bool isUser;
  final String text;
  final List<AIPlannerSlot>? slots;
  final List<String>? placeNames;

  const ConversationTurn({
    required this.isUser,
    required this.text,
    this.slots,
    this.placeNames,
  });
}

/// Parses place duration string (e.g. "1-2 hours", "45 min") to approximate minutes for scheduling.
int _durationToMinutes(String? durationStr) {
  if (durationStr == null || durationStr.trim().isEmpty) return 90;
  final s = durationStr.toLowerCase().trim();
  final hourMatch = RegExp(r'(\d+)\s*[-–]?\s*(\d+)?\s*h').firstMatch(s);
  if (hourMatch != null) {
    final lo = int.tryParse(hourMatch.group(1) ?? '') ?? 1;
    final hi = hourMatch.group(2) != null ? int.tryParse(hourMatch.group(2) ?? '') : null;
    if (hi != null) return ((lo + hi) / 2 * 60).round();
    return lo * 60;
  }
  final minMatch = RegExp(r'(\d+)\s*m').firstMatch(s);
  if (minMatch != null) return int.tryParse(minMatch.group(1) ?? '') ?? 60;
  final singleHour = RegExp(r'(\d+)\s*h').firstMatch(s);
  if (singleHour != null) return (int.tryParse(singleHour.group(1) ?? '') ?? 1) * 60;
  return 90;
}

/// Parses time string "9:00", "10:30" to minutes since midnight for ordering.
int _timeStringToMinutes(String s) {
  final parts = s.trim().split(RegExp(r'[:\s]'));
  if (parts.isEmpty) return 0;
  final h = int.tryParse(parts[0]) ?? 9;
  final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  return h * 60 + m;
}

/// Normalizes model output like "9:00", "09:5", "14:30" to HH:MM.
String _normalizeSuggestedTime(String raw) {
  final s = raw.trim();
  final m = RegExp(r'^(\d{1,2})\s*:\s*(\d{1,2})$').firstMatch(s);
  if (m != null) {
    final h = int.tryParse(m.group(1) ?? '') ?? 9;
    final min = int.tryParse(m.group(2) ?? '') ?? 0;
    final hc = h.clamp(0, 23);
    final mc = min.clamp(0, 59);
    return '${hc.toString().padLeft(2, '0')}:${mc.toString().padLeft(2, '0')}';
  }
  return s;
}

/// Calls backend which forwards to n8n webhook for trip planning.
/// Configure N8N_WEBHOOK_URL in backend .env.
class AIPlannerService {
  static String get _baseUrl {
    var url = ApiConfig.effectiveBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      url = url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  static const _timeout = Duration(seconds: 60);

  /// Call backend LLM. Pass either [prompt] (single) or both [system] and [user] for chat (model gets clear system + user messages).
  /// Returns response text (or null if empty) and optional errorDetail.
  static Future<({String? text, String? errorDetail})> _callLLM(String prompt, {double temperature = 0.5, int maxTokens = 2048, String? system, String? user}) async {
    try {
      final body = (system != null && system.isNotEmpty && user != null)
          ? <String, dynamic>{
              'system': system,
              'user': user,
              'temperature': temperature,
              'maxTokens': maxTokens,
            }
          : <String, dynamic>{
              'prompt': prompt,
              'temperature': temperature,
              'maxTokens': maxTokens,
            };
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/complete'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout, onTimeout: () {
            throw TimeoutException('AI request timed out after ${_timeout.inSeconds}s');
          });

      final bodyText = response.body;
      Map<String, dynamic>? json;
      try {
        json = jsonDecode(bodyText) as Map<String, dynamic>?;
      } catch (_) {
        json = null;
      }

      if (response.statusCode == 503) {
        final msg = json?['error'] as String? ?? 'AI not configured';
        final detail = json?['detail'] as String?;
        throw AIPlannerApiException(
          'AI is not available. $msg',
          statusCode: 503,
          detail: detail,
        );
      }

      if (response.statusCode == 400) {
        final msg = json?['error'] as String? ?? 'Invalid request';
        throw AIPlannerApiException(msg, statusCode: 400);
      }

      if (response.statusCode == 429) {
        final msg = json?['error'] as String? ?? 'AI quota exceeded';
        final detail = json?['detail'] as String?;
        throw AIPlannerApiException(
          detail ?? msg,
          statusCode: 429,
        );
      }

      if (response.statusCode >= 500) {
        final msg = json?['error'] as String? ?? 'Server error';
        final detail = json?['detail'] as String?;
        throw AIPlannerApiException(
          msg.startsWith('n8n') ? msg : 'AI service error. Please try again later.',
          statusCode: response.statusCode,
          detail: detail ?? msg,
        );
      }

      if (response.statusCode != 200) {
        final msg = json?['error'] as String? ?? json?['detail'] as String?;
        throw AIPlannerApiException(
          msg ?? 'Unexpected response (${response.statusCode}). Please try again.',
          statusCode: response.statusCode,
        );
      }

      final text = json?['text'] as String?;
      final errorDetail = json?['errorDetail'] as String?;
      final value = (text != null && text.trim().isNotEmpty) ? text : null;
      return (text: value, errorDetail: errorDetail);
    } on AIPlannerApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw AIPlannerApiException(
        'Request timed out. Check your connection and try again.',
        detail: e.message,
      );
    } catch (e, st) {
      debugPrint('AIPlannerService: $e');
      debugPrint('$st');
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Connection refused') ||
          msg.contains('Connection reset') ||
          msg.contains('Failed host lookup') ||
          msg.contains('Network is unreachable') ||
          msg.contains('ClientException') ||
          msg.contains('Connection closed') ||
          msg.contains('HandshakeException')) {
        throw AIPlannerApiException(
          'Connection failed. Ensure the backend is running (npm run dev) and reachable from this device.',
        );
      }
      throw AIPlannerApiException(
        'Something went wrong. Please try again.',
        detail: msg,
      );
    }
  }

  /// Generate itinerary using real AI. Supports refinement via previous plan + conversation.
  static Future<List<AIPlannerSlot>?> generateItinerary({
    required List<Place> places,
    required String userPrompt,
    required int durationDays,
    String budget = 'moderate',
    DateTime? selectedDate,
    List<ConversationTurn>? conversationHistory,
    List<AIPlannerSlot>? previousSlots,
    List<String>? userInterests,
    List<models.Category>? categories,
    String? activityContext,
  }) async {
    if (places.isEmpty) return null;

    final placeIds = places.map((p) => p.id).toSet();
    // Full place knowledge for AI: description, duration in minutes (for time allocation), lat/lng (for route order)
    final placesContext = places.map((p) {
      final desc = p.description.length > 600
          ? '${p.description.substring(0, 600)}...'
          : p.description;
      final durationStr = p.duration ?? '1-2 hours';
      return {
        'id': p.id,
        'name': p.name,
        'description': desc,
        'category': p.category,
        'categoryId': p.categoryId,
        'location': p.location,
        'duration': durationStr,
        'durationMinutes': _durationToMinutes(p.duration),
        'price': p.price ?? 'varies',
        'rating': p.rating?.toStringAsFixed(1) ?? 'N/A',
        'bestTime': p.bestTime ?? 'any',
        'hours': p.hours,
        'tags': (p.tags ?? []).join(', '),
        'lat': p.latitude,
        'lng': p.longitude,
      };
    }).toList();

    final categoriesStr = categories != null && categories.isNotEmpty
        ? '\n**Categories (use to match user queries):**\n${categories.map((c) => '- ${c.id}: ${c.name} — ${c.description} [tags: ${c.tags.join(", ")}]').join("\n")}'
        : '';

    final dateStr = selectedDate != null
        ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
        : 'flexible';
    final weekday = selectedDate != null
        ? [
            'Sun',
            'Mon',
            'Tue',
            'Wed',
            'Thu',
            'Fri',
            'Sat'
          ][selectedDate.weekday % 7]
        : '';

    final isRefinement = previousSlots != null &&
        previousSlots.isNotEmpty &&
        looksLikeRefinement(userPrompt);

    final interestsStr = userInterests != null && userInterests.isNotEmpty
        ? '\n**User interests (prioritize these):** ${userInterests.join(", ")}'
        : '';

    final trainingContext = AiPlannerTrainingData.planningTrainingContext;
    final systemPrompt =
        '''You are an expert Tripoli, Lebanon travel planner. You MUST build itineraries using strict time-and-location optimization so each day is realistic and walkable.

**1) MATCH PLACES TO THE REQUEST**
Search by description, tags, category, name. Use ONLY placeIds from the provided list. Never refuse: if no exact match, pick the closest places and explain.

$trainingContext

**2) SCHEDULING ALGORITHM (follow in order)**

**A. Realistic opening times (MANDATORY)**
- Only suggest suggestedTime when the place is OPEN. Never suggest a time when the place is closed.
- Use "hours" when provided (e.g. open/close times). If a place opens at 11:00, do NOT suggest 9:00 or 10:00 for it.
- If no "hours" field: use "bestTime" (e.g. "morning" → 9–12, "afternoon" → 12–17, "lunch" → 11–14). When in doubt: souks/museums often 9–18, restaurants 11–23, mosques open early morning.
- Then apply durationMinutes + 15–20 min buffer between stops. Typical day: 9:00–18:00. Max 4–6 stops per day.

**B. Time allocation**
- Each place has "durationMinutes" (visit length). suggestedTime + durationMinutes + travel buffer ≤ next suggestedTime.
- Assign suggestedTime in 24h format: "9:00", "10:30", "12:00", "14:00". Space visits by (durationMinutes + 15–20 min).

**C. Location and route order**
- Cluster by geography (lat/lng). Same area/souk → consecutive. Order to minimize walking; respect "bestTime".

**D. Multi-day split (when durationDays > 1)**
- Split places across days evenly. Do not put all in day 0.
- For each slot output "dayIndex": 0 for first day, 1 for second, 2 for third.
- Each day gets its own time sequence (e.g. Day 0: 9:00, 11:00, 14:00; Day 1: 9:00, 11:30). suggestedTime is the time on that day.
- Balance number of stops per day (e.g. 2 days → 3–4 places day 0, 3–4 places day 1).

**3) OUTPUT FORMAT**
JSON array only. Each item:
- "placeId": string (MUST be from the list)
- "suggestedTime": string, e.g. "9:00", "11:30"
- "reason": string, why this place and time (brief)
- "dayIndex": number, 0-based (optional; required when trip is multiple days. Omit or 0 for single day.)

Example single day: [{"placeId":"id1","suggestedTime":"9:00","reason":"..."},{"placeId":"id2","suggestedTime":"11:00","reason":"..."}]
Example two days: [{"placeId":"id1","suggestedTime":"9:00","reason":"...","dayIndex":0},{"placeId":"id2","suggestedTime":"11:00","reason":"...","dayIndex":0},{"placeId":"id3","suggestedTime":"9:00","reason":"...","dayIndex":1}]

Use ONLY placeIds from the list. 4–6 slots per day. No markdown.''';

    // Support up to 100 Q&A pairs (200 turns) for context
    final historyStr = conversationHistory != null &&
            conversationHistory.isNotEmpty
        ? '\n**Conversation so far:**\n${conversationHistory.take(200).map((t) {
            if (t.isUser) return 'User: ${t.text}';
            String s = 'You: ${t.text}';
            if (t.placeNames != null && t.placeNames!.isNotEmpty) {
              s +=
                  '\n(Last plan included: ${t.placeNames!.take(12).join(", ")})';
            }
            return s;
          }).join('\n')}'
        : '';

    final refinementStr = isRefinement
        ? '\n**Current itinerary (user wants to modify):**\n${previousSlots.asMap().entries.map((e) {
            final idx = e.key + 1;
            final s = e.value;
            return '$idx. ${s.placeId} at ${s.suggestedTime} – ${s.reason ?? ""}';
          }).join('\n')}\n**Modify according to user request. Keep what works, change what they asked for.**'
        : '';

    final fewShot = AiPlannerTrainingData.buildFewShotPrompt(userPrompt, maxExamples: 8);
    final userMessage = '''
Available places (use ONLY these placeIds). Each has: id, name, description, duration, durationMinutes, bestTime, hours (opening times – only suggest times when the place is open!), lat, lng, price, category, tags:
${jsonEncode(placesContext)}
$categoriesStr

**Relevant training examples:** $fewShot

**User request:** $userPrompt
**Trip duration:** $durationDays day(s)${durationDays > 1 ? ' — split places across days and set dayIndex 0, 1, ... for each slot' : ''}
**Budget:** $budget
**Date:** $dateStr $weekday
$interestsStr
${activityContext != null && activityContext.isNotEmpty ? '\n$activityContext\n' : ''}
$historyStr
$refinementStr

Apply time allocation (durationMinutes + buffer) and location ordering (lat/lng). Return JSON array of slots only. No markdown.
''';

    try {
      final result = await _callLLM(
        '$systemPrompt\n\n$userMessage',
        temperature: 0.7,
        maxTokens: 2048,
      );
      final text = result.text;
      if (text == null || text.isEmpty) return null;

      String jsonStr = text.trim();
      final codeBlockMatch =
          RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
      if (codeBlockMatch != null) {
        jsonStr = codeBlockMatch.group(1)!.trim();
      }

      final list = jsonDecode(jsonStr) as List<dynamic>;

      final slots = <AIPlannerSlot>[];
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final placeId = map['placeId'] as String?;
        if (placeId == null || !placeIds.contains(placeId)) continue;
        final dayIndexRaw = map['dayIndex'];
        final dayIndex = dayIndexRaw is int ? dayIndexRaw : (dayIndexRaw is num ? dayIndexRaw.toInt() : null);
        slots.add(AIPlannerSlot(
          placeId: placeId,
          suggestedTime:
              (map['suggestedTime'] as String?) ?? '${9 + slots.length}:00',
          reason: map['reason'] as String?,
          dayIndex: dayIndex,
        ));
      }

      // If user asked for multiple days but AI didn't set dayIndex, split slots across days ourselves
      if (durationDays > 1 && slots.isNotEmpty && slots.every((s) => s.dayIndex == null || s.dayIndex == 0)) {
        final n = slots.length;
        final perDay = (n / durationDays).ceil().clamp(1, n);
        final newSlots = <AIPlannerSlot>[];
        for (var i = 0; i < slots.length; i++) {
          final dayIdx = (i / perDay).floor().clamp(0, durationDays - 1);
          final slotInDay = i - (dayIdx * perDay);
          final startHour = 9 + slotInDay; // Each day starts at 9:00
          newSlots.add(AIPlannerSlot(
            placeId: slots[i].placeId,
            suggestedTime: '$startHour:00',
            reason: slots[i].reason,
            dayIndex: dayIdx,
          ));
        }
        slots
          ..clear()
          ..addAll(newSlots);
      }

      // Clamp dayIndex to 0..durationDays-1 so saved trips never exceed the requested length
      if (durationDays > 1 && slots.isNotEmpty) {
        for (var i = 0; i < slots.length; i++) {
          final s = slots[i];
          final raw = s.dayIndex ?? 0;
          final c = raw.clamp(0, durationDays - 1);
          if (raw != c) {
            slots[i] = AIPlannerSlot(
              placeId: s.placeId,
              suggestedTime: s.suggestedTime,
              reason: s.reason,
              dayIndex: c,
            );
          }
        }
      }

      // Sort by day then time so multi-day itineraries display in order
      if (slots.length > 1) {
        slots.sort((a, b) {
          final d0 = a.dayIndex ?? 0;
          final d1 = b.dayIndex ?? 0;
          if (d0 != d1) return d0.compareTo(d1);
          return _timeStringToMinutes(a.suggestedTime).compareTo(_timeStringToMinutes(b.suggestedTime));
        });
      }

      return slots.isNotEmpty ? slots : null;
    } on AIPlannerApiException catch (e) {
      if (e.statusCode == 429) {
        debugPrint('AIPlannerService: quota exceeded, falling back to local matching');
        return null;
      }
      rethrow;
    } catch (e, st) {
      debugPrint('AIPlannerService.generateItinerary: $e');
      debugPrint('$st');
      return null;
    }
  }

  /// Suggest places that match the user's request — no times, for user to accept before planning.
  /// When the request doesn't match (e.g. beaches, ski), returns alternativesMessage first, then closest places.
  static Future<SuggestPlacesResult?> suggestPlaces({
    required List<Place> places,
    required String userPrompt,
    List<AIPlannerSuggestion>? previousSuggestions,
    bool isReplaceRequest = false,
    int? placeCount,
    int? groupSize,
    List<models.Category>? categories,
    String? activityContext,
  }) async {
    if (places.isEmpty) return null;
    final placeIds = places.map((p) => p.id).toSet();
    final placesContext = places.map((p) {
      final desc = p.description.length > 500
          ? '${p.description.substring(0, 500)}...'
          : p.description;
      return {
        'id': p.id,
        'name': p.name,
        'description': desc,
        'tags': (p.tags ?? []).join(', '),
        'category': p.category,
        'categoryId': p.categoryId,
        'location': p.location,
        'duration': p.duration,
        'price': p.price,
        'bestTime': p.bestTime,
      };
    }).toList();

    final categoriesStr = categories != null && categories.isNotEmpty
        ? '\n**Categories:** ${categories.map((c) => '${c.id}=${c.name}[${c.tags.join(",")}]').join("; ")}'
        : '';

    final trainingContext = AiPlannerTrainingData.planningTrainingContext;
    final systemPrompt =
        '''You suggest Tripoli places for the user. You have FULL knowledge of ALL places. Search by description, tags, category, or name.

$trainingContext

**Search:** Match user queries by scanning place descriptions, tags, and categories. Any place can match if it fits the request.

**If we DON'T have it (beaches, ski, etc.):** Set "alternativesMessage" explaining and suggest closest matches (e.g. Citadel for sea views, seafood for beach vibes).

**If we have matches:** Leave alternativesMessage null.

**Place count:** Suggest the number requested. Default 4–6. Use ONLY placeIds from the list.

**Output:** JSON: {"alternativesMessage": null or "text", "places": [{"placeId":"id","reason":"why"}]}.''';

    final replaceStr = isReplaceRequest && previousSuggestions != null
        ? '\n**User wants to replace one place. Suggest alternatives.**'
        : '';

    final fewShot = AiPlannerTrainingData.buildFewShotPrompt(userPrompt, maxExamples: 8);
    final userMessage = '''
Places (search ALL; use ONLY these placeIds):
${jsonEncode(placesContext)}
$categoriesStr

**Relevant training examples for this request:**
$fewShot

**User request:** $userPrompt
**Preferences:** ${placeCount != null ? "$placeCount places" : "4–6 places"}${groupSize != null ? ", $groupSize people" : ""}
${activityContext != null && activityContext.isNotEmpty ? '\n$activityContext\n' : ''}
$replaceStr

Return JSON: {"alternativesMessage": null or "text", "places": [{"placeId":"exact_id","reason":"why"}]}.
''';

    try {
      final result = await _callLLM(
        '$systemPrompt\n\n$userMessage',
        temperature: 0.3,
        maxTokens: 1024,
      );
      final text = result.text;
      if (text == null || text.isEmpty) return null;
      String jsonStr = text;
      final m = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
      if (m != null) jsonStr = m.group(1)!.trim();
      final decoded = jsonDecode(jsonStr);
      final map = decoded is Map<String, dynamic> ? decoded : null;
      if (map == null) return null;
      final alternativesMessage =
          (map['alternativesMessage'] as String?)?.trim();
      final list = map['places'] as List<dynamic>?;
      if (list == null) return null;
      final suggestions = <AIPlannerSuggestion>[];
      for (final item in list) {
        final itemMap = item as Map<String, dynamic>;
        final placeId = itemMap['placeId'] as String?;
        if (placeId == null || !placeIds.contains(placeId)) continue;
        suggestions.add(AIPlannerSuggestion(
          placeId: placeId,
          reason: itemMap['reason'] as String?,
        ));
      }
      return suggestions.isNotEmpty
          ? SuggestPlacesResult(
              alternativesMessage: alternativesMessage?.isNotEmpty == true
                  ? alternativesMessage
                  : null,
              suggestions: suggestions,
            )
          : null;
    } on AIPlannerApiException catch (e) {
      if (e.statusCode == 429) {
        debugPrint('AIPlannerService: quota exceeded, falling back to local matching');
        return null;
      }
      rethrow;
    } catch (e, st) {
      debugPrint('AIPlannerService.suggestPlaces: $e');
      debugPrint('$st');
      return null;
    }
  }

  /// Respond intelligently to anything—full conversational AI. Can discuss any topic.
  /// Uses Tripoli verified facts when relevant; otherwise draws on general knowledge.
  static Future<String?> respondIntelligently(String userMessage) async {
    final chatTraining = AiPlannerTrainingData.chatTrainingContext;
    final prompt =
        '''You are an intelligent, friendly assistant. You can talk about anything—general knowledge, travel, Tripoli, other cities, advice, casual chat, jokes, or random topics.

**Tripoli specialty:** When the topic is Tripoli Lebanon (history, places, culture, travel), use the verified facts below when they apply. For anything else, use your general knowledge.

$chatTraining

**Style:** Natural, warm, concise (usually 2–6 sentences). Match the user's tone. No JSON or bullet lists unless asked. Understand typos and short messages. Be helpful and engaging—you're a companion, not a rigid bot. Prefer accurate, specific answers; if a fact is uncertain, say so briefly instead of guessing.''';

    final fullPrompt =
        '$prompt\n\n---\n**Verified Tripoli history facts (use when relevant):**\n$tripoliHistoryKnowledge\n\n---\nUser: $userMessage\n\nReply:';

    try {
      final result = await _callLLM(fullPrompt, temperature: 0.45, maxTokens: 896);
      return result.text;
    } on AIPlannerApiException {
      rethrow;
    } catch (e, st) {
      debugPrint('AIPlannerService.respondIntelligently: $e');
      debugPrint('$st');
      return null;
    }
  }

  /// Chat for trip planning: accepts any message, returns reply text and optionally a plan (slots).
  /// Conversation history: list of {"role": "user"|"assistant", "content": "..."}. Assistant may have included a plan.
  /// When the AI wants to propose an itinerary it appends "\\nPLAN_JSON:" then a JSON array of {placeId, suggestedTime, reason, dayIndex?}.
  /// Preferred language for AI responses: 'en', 'ar', or 'fr'.
  static const List<String> supportedResponseLanguages = ['en', 'ar', 'fr'];

  static Future<({String text, List<AIPlannerSlot>? slots})> chatForTripPlan({
    required List<Map<String, String>> conversationHistory,
    required String userMessage,
    required List<Place> places,
    int durationDays = 1,
    int? placesPerDay,
    String budget = 'moderate',
    DateTime? selectedDate,
    List<String>? userInterests,
    String? activityContext,
    String responseLanguage = 'en',
    List<AIPlannerSlot>? previousSlots,
    List<Place>? previousPlaces,
    /// When set, user is replacing only this index in the flat plan array; model must keep all other slots identical.
    int? singleReplaceSlotIndex,
  }) async {
    final lang = supportedResponseLanguages.contains(responseLanguage) ? responseLanguage : 'en';
    final languageInstruction = lang == 'ar'
        ? 'You must reply ONLY in Arabic (العربية). Write all your messages in Arabic.'
        : lang == 'fr'
            ? 'You must reply ONLY in French (Français). Write all your messages in French.'
            : 'You must reply ONLY in English. Write all your messages in English.';
    final dbLocaleNote = lang == 'ar'
        ? 'The place names and categories in the list below come from the app database in Arabic—use those exact names in your explanations and in each slot\'s "reason" field.'
        : lang == 'fr'
            ? 'Les noms des lieux et les catégories viennent de la base en français : utilisez exactement ces libellés dans le texte et dans chaque "reason".'
            : 'Place names and categories in the list are in English from the database—use those exact names in your text and in each slot\'s "reason" field.';
    final placeIds = places.map((p) => p.id).toSet();
    // Keep payload small so n8n/Groq don't time out or hit limits (id + name + category only; max 40 places)
    final placesContext = places.take(40).map((p) => {
      'id': p.id,
      'name': p.name,
      'category': p.category,
    }).toList();

    final fewShot = AiPlannerTrainingData.buildFewShotPrompt(userMessage, maxExamples: 10);
    const qualityRules = AiPlannerTrainingData.plannerQualityRules;

    final historyStr = conversationHistory.isEmpty
        ? ''
        : conversationHistory
            .take(30)
            .map((e) => '${e['role'] == 'user' ? 'User' : 'Assistant'}: ${e['content'] ?? ''}')
            .join('\n');

    final exactCountNote = placesPerDay != null && placesPerDay > 0
        ? '''
CRITICAL - EXACT PLACE COUNT: You MUST suggest EXACTLY $placesPerDay places per day. Total: ${durationDays * placesPerDay} slots.
- Day 0: exactly $placesPerDay places
- Day 1: exactly $placesPerDay places (if duration > 1)
- Day 2: exactly $placesPerDay places (if duration > 2)
- etc. Never suggest fewer or more. Count your slots before outputting.'''
        : '';

    final planInstruction = '''
When you have enough information (e.g. days, interests, or the user asks for a plan), you MAY propose an itinerary. To do that, end your reply with a single newline then exactly: PLAN_JSON:
Then a JSON array of objects with placeId, suggestedTime, reason; add dayIndex (0,1,...) if multiple days. Use ONLY placeIds from the list. Example: [{"placeId":"id1","suggestedTime":"9:00","reason":"...","dayIndex":0}]
If the user wants 2 or more days, you MUST set dayIndex on every slot: 0 = first day, 1 = second day, etc. Spread places evenly across days.$exactCountNote
If you are just chatting or asking for more details, do NOT include PLAN_JSON.''';

    final multiDayNote = durationDays >= 2
        ? '\n\nIMPORTANT: The user wants $durationDays days. You MUST assign dayIndex (0, 1, ...) to each slot and spread the plan across $durationDays days.'
        : '';

    const tripoliOnly = '''
You ONLY help with Tripoli, Lebanon. Answer only about Tripoli—trip planning, its places, food, culture, history, and visiting Tripoli. If the user asks about anything unrelated to Tripoli (other cities, general knowledge, etc.), politely say you can only help with Tripoli and ask how you can help with their Tripoli visit. Never discuss other destinations.''';

    String currentPlanBlock = '';
    if (previousSlots != null && previousPlaces != null && previousSlots.isNotEmpty && previousPlaces.isNotEmpty) {
      final idToName = {for (final p in previousPlaces) p.id: p.name};
      final lines = <String>[];
      var dayIdx = -1;
      for (var i = 0; i < previousSlots.length; i++) {
        final s = previousSlots[i];
        final d = s.dayIndex ?? 0;
        final name = idToName[s.placeId] ?? s.placeId;
        if (d != dayIdx) {
          dayIdx = d;
          lines.add('Day ${d + 1}: ${s.suggestedTime} $name');
        } else {
          lines.add('  ${s.suggestedTime} $name');
        }
      }
      var replaceOneStopNote = '''
When the user asks to add a place, remove one, reorder, or "do the plan again", output an updated PLAN_JSON that applies their requested change and adjusts times/order as needed. Keep as much of the current plan as they did not ask to change.
If the user asks to change or replace ONLY ONE stop (they name one place, time, or day), output a full PLAN_JSON array where every slot is identical to the current plan except that single slot: only that slot's placeId (and reason) may change to a different place from the list. Keep the same suggestedTime and dayIndex for all slots unless they explicitly asked to change a time. Preserve order and count.''';

      if (singleReplaceSlotIndex != null &&
          singleReplaceSlotIndex >= 0 &&
          singleReplaceSlotIndex < previousSlots.length) {
        replaceOneStopNote = '''

MANDATORY — SINGLE SLOT REPLACE (app-enforced):
- The user is replacing ONLY the stop at slot index $singleReplaceSlotIndex (0-based) in the plan array above.
- Your PLAN_JSON MUST contain EXACTLY ${previousSlots.length} slots — the same count as the current plan.
- For every index i where i ≠ $singleReplaceSlotIndex: copy the current plan exactly — same placeId, suggestedTime, dayIndex, and reason as in the current plan (no changes).
- Only index $singleReplaceSlotIndex may use a new placeId from the list (and an updated reason). Keep suggestedTime and dayIndex for that slot the same as the current plan unless the user explicitly asked to change the time.
- Do not reorder slots. Do not add or remove slots.''';
      }

      currentPlanBlock = '''

CURRENT PLAN (user may have edited it; they want you to update it):
${lines.join('\n')}
$replaceOneStopNote''';
    }

    final systemPrompt = '''You are an expert Tripoli, Lebanon trip planner—accurate, helpful, and concise.

$languageInstruction
$dbLocaleNote
$tripoliOnly

$qualityRules

**Intent examples (match user wording loosely):**
$fewShot

You MUST never say the user "didn't ask a question" or "haven't shared any information"—treat "hello", "plan trip", "start", "plan", "i want a plan" as valid. The user has already set their number of days and places per day (see Trip context below). Reply by asking about interests (food, culture, history, shopping) or suggest a plan using the places list.

Chat naturally. When you have enough to suggest a plan (or the user asks for one), propose it and output it using PLAN_JSON as instructed below. Use the Trip context (days and places per day) exactly.

$planInstruction

Available places (use ONLY these placeIds): ${jsonEncode(placesContext)}

Trip context: $durationDays day(s)${placesPerDay != null && placesPerDay > 0 ? ', exactly $placesPerDay places per day' : ''}, budget $budget${selectedDate != null ? ', date ${selectedDate.day}/${selectedDate.month}' : ''}${userInterests != null && userInterests.isNotEmpty ? ', interests: ${userInterests.join(", ")}' : ''}
${activityContext != null && activityContext.isNotEmpty ? '\n$activityContext\n' : ''}$multiDayNote$currentPlanBlock''';

    final userPrompt = historyStr.isEmpty
        ? 'User: $userMessage\n\nAssistant:'
        : '$historyStr\n\nUser: $userMessage\n\nAssistant:';

    // Lower temperature when structure matters (refine / single-slot) to reduce hallucinations and JSON errors.
    final plannerTemperature = singleReplaceSlotIndex != null
        ? 0.32
        : (previousSlots != null && previousSlots.isNotEmpty ? 0.42 : 0.52);

    try {
      final result = await _callLLM(
        '', // not used when system+user provided
        temperature: plannerTemperature,
        maxTokens: 2048,
        system: systemPrompt,
        user: userPrompt,
      );
      final raw = result.text;
      if (raw == null || raw.isEmpty) {
        final hint = result.errorDetail != null && result.errorDetail!.isNotEmpty
            ? ' ${result.errorDetail}'
            : ' If this keeps happening, check that the planner workflow is active in n8n and that Groq is responding.';
        return (text: 'Sorry, I couldn\'t reply.$hint', slots: null);
      }

      String text = raw.trim();
      List<AIPlannerSlot>? slots;

      final planLabel = RegExp(r'PLAN_JSON\s*:', caseSensitive: false);
      final planIdx = planLabel.firstMatch(text);
      if (planIdx != null) {
        final beforePlan = text.substring(0, planIdx.start).trim();
        final afterLabel = text.substring(planIdx.end).trim();
        final arrStart = afterLabel.indexOf('[');
        if (arrStart >= 0) {
          var depth = 0;
          var end = -1;
          for (var i = arrStart; i < afterLabel.length; i++) {
            final c = afterLabel[i];
            if (c == '[') {
              depth++;
            } else if (c == ']') {
              depth--;
              if (depth == 0) {
                end = i;
                break;
              }
            }
          }
          if (end >= 0) {
            text = beforePlan;
            try {
              final list = jsonDecode(afterLabel.substring(arrStart, end + 1)) as List<dynamic>;
              slots = [];
              for (final item in list) {
                final map = item as Map<String, dynamic>;
                final placeIdRaw = map['placeId'] ?? map['place_id'];
                final placeId = placeIdRaw is String ? placeIdRaw : null;
                if (placeId == null || !placeIds.contains(placeId)) continue;
                final dayIndexRaw = map['dayIndex'] ?? map['day_index'];
                final dayIndex = dayIndexRaw is int ? dayIndexRaw : (dayIndexRaw is num ? dayIndexRaw.toInt() : null);
                final timeStr = (map['suggestedTime'] ?? map['suggested_time']) as String?;
                slots.add(AIPlannerSlot(
                  placeId: placeId,
                  suggestedTime: _normalizeSuggestedTime(
                    (timeStr != null && timeStr.isNotEmpty) ? timeStr : '9:00',
                  ),
                  reason: (map['reason'] as String?),
                  dayIndex: dayIndex,
                ));
              }
              if (slots.isEmpty) slots = null;
            } catch (_) {
              slots = null;
            }
          }
        }
      }

      return (text: text.isNotEmpty ? text : 'Here’s a plan for you!', slots: slots);
    } on AIPlannerApiException {
      rethrow;
    } catch (e, st) {
      debugPrint('AIPlannerService.chatForTripPlan: $e');
      debugPrint('$st');
      return (text: 'Something went wrong. Please try again.', slots: null);
    }
  }

  /// Respond to conversational/small-talk. Delegates to respondIntelligently for unified intelligence.
  static Future<String?> respondConversationally(String userMessage) async =>
      respondIntelligently(userMessage);

  /// Respond to history questions. Delegates to respondIntelligently (uses verified facts + general knowledge).
  static Future<String?> respondToHistoryQuestion(String userMessage) async =>
      respondIntelligently(userMessage);

  static bool looksLikeRefinement(String prompt) {
    final lower = prompt.toLowerCase();
    const refinements = [
      'add',
      'more',
      'less',
      'swap',
      'change',
      'replace',
      'remove',
      'shorter',
      'longer',
      'indoor',
      'outdoor',
      'instead',
      'different',
      'alternative',
      'skip',
      'include',
      'budget',
      'cheaper',
      'free',
      'rain',
      'weather',
      'kids',
      'family',
      'solo',
      'photography',
    ];
    return refinements.any((r) => lower.contains(r)) ||
        lower.startsWith('replace ') ||
        lower.contains('replace ');
  }

  static bool get isAvailable => true; // LLM runs on backend
}
