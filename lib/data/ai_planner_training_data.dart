/// Training dataset for AI Planner: example user messages and expected behaviors.
/// Used for few-shot in-context learning to improve response quality and intent recognition.
/// Add more examples here to "train" the AI on new message patterns.
library;

class AiPlannerTrainingData {
  AiPlannerTrainingData._();

  /// Example user inputs → expected AI behavior (for prompt injection).
  /// Format: "User: X" → "AI should: Y" or example response pattern.
  static const List<({String user, String aiBehavior})> planningExamples = [
    (user: '5 places for 2 people', aiBehavior: 'Parse: 5 places, 2 people. Suggest 5 places matching user interests.'),
    (user: '4', aiBehavior: 'Parse as place count. If no group size, ask or assume 1-2.'),
    (user: '6 places', aiBehavior: 'Suggest 6 diverse places. Use routing logic.'),
    (user: 'I want to see museums and history', aiBehavior: 'Match: Citadel, Great Mosque, Taynal, museums, khans. Prioritize historical sites.'),
    (user: 'food tour', aiBehavior: 'Match: Hallab, Rahal, souks, fish market, traditional cafes, restaurants.'),
    (user: 'knefe and sweets', aiBehavior: 'Match: Hallab, Rahal Sweets, sweet shops. Typos: knefe, knfe, konafa.'),
    (user: 'souk shopping', aiBehavior: 'Match: Khan al-Khayyatin, Khan al-Saboun, Gold Souk, Spice Market.'),
    (user: 'mosques and religious', aiBehavior: 'Match: Great Mosque, Taynal, Burtasiyat, Muallaq.'),
    (user: 'citadel and views', aiBehavior: 'Match: Citadel of Raymond de Saint-Gilles. Include sea views.'),
    (user: 'soap and crafts', aiBehavior: 'Match: Khan al-Saboun (soap khan).'),
    (user: 'fish and seafood', aiBehavior: 'Match: Al-Mina Fish Market, Port Seafood, Furn al-Samak.'),
    (user: 'hammam bath', aiBehavior: 'Match: Hammam al-Jadid, Ottoman hammams.'),
    (user: 'culture day', aiBehavior: 'Match: museums, citadel, mosques, khans. Morning at citadel.'),
    (user: 'morning at citadel', aiBehavior: 'Start itinerary with Citadel. Best light.'),
    (user: 'half day trip', aiBehavior: 'Suggest 3-4 places. Compact routing.'),
    (user: 'full day', aiBehavior: 'Suggest 5-6 places. Include lunch spot.'),
    (user: 'budget friendly', aiBehavior: 'Prioritize free/low-cost: souks, citadel views, walking.'),
    (user: 'luxury experience', aiBehavior: 'Include premium dining, hammam, quality spots.'),
    (user: 'with kids', aiBehavior: 'Family-friendly: citadel, souks, sweets, shorter duration.'),
    (user: 'solo traveler', aiBehavior: 'Flexible, walking-friendly. Cafes, souks, citadel.'),
    (user: 'photography spots', aiBehavior: 'Citadel, mosques, souks, golden hour.'),
    (user: 'rainy day', aiBehavior: 'Indoor: museums, khans, hammam, cafes, covered souks.'),
    (user: 'add more places', aiBehavior: 'Refinement: expand itinerary. Add 1-2 more.'),
    (user: 'swap the mosque for something else', aiBehavior: 'Refinement: replace mosque with alternative (khan, museum, cafe).'),
    (user: 'make it shorter', aiBehavior: 'Refinement: reduce to 3-4 places. Keep best.'),
    (user: 'cheaper options', aiBehavior: 'Refinement: replace expensive with free/budget.'),
    (user: 'replace hallab', aiBehavior: 'Refinement: suggest alternative sweets/cafe.'),
    (user: 'indoor only', aiBehavior: 'Refinement: filter to indoor (museums, khans, hammam, cafes).'),
    (user: 'more outdoor', aiBehavior: 'Refinement: add citadel, souks, port, walking.'),
    (user: 'traditional lebanese food', aiBehavior: 'Match: Hallab, Rahal, souks, fish market, local restaurants.'),
    (user: 'architecture', aiBehavior: 'Match: Citadel, mosques, khans, Mamluk/Ottoman buildings.'),
    (user: 'morning only', aiBehavior: 'Suggest 2-3 places. Morning slots. Citadel best early.'),
    (user: 'afternoon', aiBehavior: 'Suggest 2-3 places. Afternoon. Souks, cafes, museums.'),
    (user: 'free things', aiBehavior: 'Prioritize: citadel views, souk walking, free entry spots.'),
    (user: 'hidden gems', aiBehavior: 'Less touristy: Burtasiyat, smaller khans, local cafes.'),
    (user: 'instagrammable', aiBehavior: 'Photogenic: citadel, mosques, souks, colorful spots.'),
    (user: 'quick visit', aiBehavior: '2-3 places. 2-3 hours total. Compact.'),
    (user: 'relaxing', aiBehavior: 'Cafes, hammam, gentle souk stroll. No rush.'),
    (user: 'adventure', aiBehavior: 'Citadel climb, souk exploration, port, active spots.'),
    (user: 'change only one stop', aiBehavior: 'Refinement: replace exactly one slot; keep all other placeIds and times unchanged.'),
    (user: 'keep the rest', aiBehavior: 'Refinement: only change what the user named; preserve every other stop.'),
    (user: 'wrong place', aiBehavior: 'Refinement: apologize briefly and swap that stop for a better match from the list.'),
    (user: 'too crowded', aiBehavior: 'Refinement: suggest quieter alternatives (smaller khans, off-peak times).'),
    (user: 'not interested in food', aiBehavior: 'Refinement: remove or replace food stops with culture/history/souks.'),
  ];

  /// Injected into the planner system prompt — reduces hallucinated IDs and sloppy JSON.
  static const String plannerQualityRules = '''
**Accuracy & JSON (mandatory):**
- Never invent a placeId. Copy each "id" exactly from the "Available places" list — character-for-character.
- Before emitting PLAN_JSON, count slots: they must match the trip (days × places per day) when that is set.
- suggestedTime must be plausible (e.g. 9:00–18:00 for most sites); respect opening hours when you know them.
- Spread variety: mix categories (heritage, food, souks, views) when the user did not ask for a single theme.
- Multi-day: set dayIndex on every slot; balance stops across days; do not duplicate the same placeId on the same day unless the user asked.
- If the user message is vague ("ok", "yes", "do it"), infer from trip context and interests — still only use listed placeIds.
- Short user typos (knefe, souk, citdel) — map intent to Tripoli places from the list, do not refuse.
''';

  /// Typos and variations → correct interpretation.
  static const List<({String typo, String correct})> typoExamples = [
    (typo: 'knfe', correct: 'knefe'),
    (typo: 'knefeh', correct: 'knefe'),
    (typo: 'halab', correct: 'Hallab'),
    (typo: 'citdel', correct: 'citadel'),
    (typo: 'suk', correct: 'souk'),
    (typo: 'souq', correct: 'souk'),
    (typo: 'museam', correct: 'museum'),
    (typo: 'mosk', correct: 'mosque'),
    (typo: 'se', correct: 'sea'),
    (typo: 'fod', correct: 'food'),
    (typo: 'histry', correct: 'history'),
    (typo: 'culure', correct: 'culture'),
    (typo: 'swets', correct: 'sweets'),
    (typo: 'soap', correct: 'soap (Khan al-Saboun)'),
    (typo: 'fish markt', correct: 'fish market'),
    (typo: 'hamam', correct: 'hammam'),
    (typo: 'cafe', correct: 'cafe'),
    (typo: 'cofee', correct: 'coffee'),
  ];

  /// General chat / non-planning → expected response style.
  static const List<({String user, String aiStyle})> chatExamples = [
    (user: 'what is tripoli known for?', aiStyle: 'Brief, factual. Mention: citadel, souks, sweets, Mamluk architecture, history.'),
    (user: 'best time to visit?', aiStyle: 'Spring/fall. Morning for citadel. Avoid midday heat.'),
    (user: 'is it safe?', aiStyle: 'Balanced, practical. General travel advice.'),
    (user: 'how many days?', aiStyle: '1-2 days for highlights. 3+ for deep dive.'),
    (user: 'tell me a joke', aiStyle: 'Light, friendly. Can be travel-related.'),
    (user: 'thanks', aiStyle: 'Warm, brief. Offer to help more.'),
    (user: 'hello', aiStyle: 'Friendly greeting. Invite to plan or chat.'),
    (user: 'hi', aiStyle: 'Same as hello.'),
    (user: 'help', aiStyle: 'Explain: can plan trips, suggest places, chat about Tripoli.'),
    (user: 'what can you do?', aiStyle: 'List: plan itineraries, suggest places, answer questions.'),
    (user: 'recommend something', aiStyle: 'Ask: what interests? Or suggest top 3 (citadel, souks, sweets).'),
    (user: 'random', aiStyle: 'Suggest a random highlight: e.g. Khan al-Saboun or Citadel.'),
    (user: 'surprise me', aiStyle: 'Pick 4-5 diverse places. Mix food, history, souks.'),
    (user: 'something different', aiStyle: 'Suggest less-known: Burtasiyat, Hammam, a specific khan.'),
    (user: 'romantic spots', aiStyle: 'Citadel sunset, cafes, souks, sea views.'),
    (user: 'we have 3 hours', aiStyle: '2-3 places. Compact. Citadel + one souk + sweets.'),
    (user: 'we have 6 hours', aiStyle: '4-5 places. Full morning + lunch + afternoon.'),
    (user: 'no preferences', aiStyle: 'Suggest classic: citadel, souks, Hallab, mosque.'),
    (user: 'whatever you think', aiStyle: 'Curate best-of. 5 places. Balanced.'),
  ];

  /// Out-of-scope / we don't have it → expected handling.
  static const List<({String user, String aiBehavior})> outOfScopeExamples = [
    (user: 'beach', aiBehavior: 'Explain: Tripoli is port city. Suggest: Al-Mina, seafood, sea views. No sandy beach.'),
    (user: 'skiing', aiBehavior: 'Explain: No ski in Tripoli. Suggest: winter indoor (museums, hammam, cafes).'),
    (user: 'nightclub', aiBehavior: 'Explain: Limited nightlife. Suggest: evening cafes, souk stroll, port.'),
    (user: 'hotel', aiBehavior: 'Explain: Focus on places to visit. Can mention areas to stay.'),
    (user: 'restaurant in Beirut', aiBehavior: 'Politely: I specialize in Tripoli. Redirect to Tripoli options.'),
  ];

  /// Build few-shot examples string for prompt injection.
  /// Selects examples most relevant to [userMessage].
  static String buildFewShotPrompt(String userMessage, {int maxExamples = 12}) {
    final lower = userMessage.toLowerCase();
    final examples = <String>[];

    // Add planning examples that match
    for (final e in planningExamples) {
      if (examples.length >= maxExamples) break;
      if (_matches(lower, e.user) || _matches(lower, e.aiBehavior)) {
        examples.add('User: "${e.user}" → ${e.aiBehavior}');
      }
    }

    // Add typo examples if message seems short or misspelled
    if (lower.length < 15 || _hasPossibleTypo(lower)) {
      for (final e in typoExamples.take(5)) {
        if (examples.length >= maxExamples) break;
        examples.add('Typo: "${e.typo}" means "${e.correct}"');
      }
    }

    // Add chat examples for non-planning
    for (final e in chatExamples) {
      if (examples.length >= maxExamples) break;
      if (_matches(lower, e.user) || examples.length < 4) {
        examples.add('User: "${e.user}" → ${e.aiStyle}');
      }
    }

    // Add out-of-scope handling
    for (final e in outOfScopeExamples) {
      if (examples.length >= maxExamples) break;
      if (_matches(lower, e.user)) {
        examples.add('User: "${e.user}" → ${e.aiBehavior}');
      }
    }

    // Ensure we have a base set
    if (examples.length < 6) {
      for (final e in planningExamples.take(6 - examples.length)) {
        if (!examples.any((x) => x.contains(e.user))) {
          examples.add('User: "${e.user}" → ${e.aiBehavior}');
        }
      }
    }

    return examples.take(maxExamples).join('\n');
  }

  static bool _matches(String lower, String pattern) {
    final p = pattern.toLowerCase().replaceAll('?', '').replaceAll('.', '');
    final lowerClean = lower.replaceAll('?', '').replaceAll('.', '');
    return lowerClean.contains(p) || p.contains(lowerClean);
  }

  static bool _hasPossibleTypo(String lower) {
    if (lower.length > 20) return false;
    const knownTypos = ['knfe', 'citdel', 'suk', 'mosk', 'museam', 'halab', 'se', 'fod'];
    return knownTypos.any((t) => lower.contains(t));
  }

  /// Full training context for respondIntelligently (general chat).
  static String get chatTrainingContext {
    final buf = StringBuffer();
    buf.writeln('**Example user messages and how to respond:**');
    for (final e in chatExamples.take(15)) {
      buf.writeln('- "${e.user}" → ${e.aiStyle}');
    }
    buf.writeln('**Out-of-scope (redirect kindly):**');
    for (final e in outOfScopeExamples) {
      buf.writeln('- "${e.user}" → ${e.aiBehavior}');
    }
    return buf.toString();
  }

  /// Full planning training context for generateItinerary / suggestPlaces.
  static String get planningTrainingContext {
    final buf = StringBuffer();
    buf.writeln('**Trained on these message patterns:**');
    for (final e in planningExamples.take(20)) {
      buf.writeln('- "${e.user}" → ${e.aiBehavior}');
    }
    buf.writeln('**Typo corrections:**');
    for (final e in typoExamples) {
      buf.writeln('- "${e.typo}" → ${e.correct}');
    }
    return buf.toString();
  }
}
