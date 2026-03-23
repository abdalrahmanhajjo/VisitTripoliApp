import 'dart:math' as math;

import '../services/feed_service.dart';

/// **For You** feed ranking: recency-first personalization (Discover).
///
/// ### Model
/// Each post gets a score **S** (higher = earlier in the list). Reels (`type == video`)
/// are excluded here (they live under Reels).
///
/// **S = R^α × E × I × U**
///
/// - **R** — *Recency* in (0,1]: `exp(-ageHours / τ)` with half-life-style decay `τ = 38h`.
///   New posts always beat stale ones unless age is similar.
/// - **α = 1.12** — slightly sharpens recency so time order stays meaningful.
/// - **E** — *Engagement* multiplier `1 + λ · normLog(likes + 2×comments)` capped so
///   viral posts surface within the same age band without beating much newer content.
/// - **I** — *Interest* boost when user keywords match caption or place name.
/// - **U** — *Unseen* slight preference for posts not yet opened in this session.
///
/// Tie-break: higher [FeedPost.id] (stable with server ULIDs / time-sortable ids).
List<FeedPost> rankDiscoverForYou({
  required List<FeedPost> posts,
  required List<String> interestKeywords,
  required Set<String> seenPostIds,
}) {
  if (posts.isEmpty) return const [];

  const tauHours = 38.0;
  const recencySharpness = 1.12;
  const engagementWeight = 0.24;
  const engagementCap = 500.0;
  const interestBoost = 1.14;
  const seenDownrank = 0.94;

  final nonReels = posts.where((p) => p.type != 'video').toList();
  if (nonReels.isEmpty) return const [];

  final keywords = interestKeywords
      .map((k) => k.trim().toLowerCase())
      .where((k) => k.isNotEmpty)
      .toList();

  double recencyFactor(double ageHours) {
    return math.exp(-ageHours / tauHours);
  }

  double engagementFactor(FeedPost p) {
    final raw = (1 + p.likeCount + 2 * p.commentCount).toDouble();
    final norm = math.log(raw + 1) / math.log(engagementCap + 1);
    return 1.0 + engagementWeight * norm.clamp(0.0, 1.0);
  }

  double interestFactor(FeedPost p) {
    if (keywords.isEmpty) return 1.0;
    final cap = (p.caption ?? '').toLowerCase();
    final place = (p.authorPlaceName ?? '').toLowerCase();
    for (final k in keywords) {
      if (cap.contains(k) || place.contains(k)) return interestBoost;
    }
    return 1.0;
  }

  double unseenFactor(String id) {
    return seenPostIds.contains(id) ? seenDownrank : 1.0;
  }

  double ageHoursUtc(FeedPost p) {
    final dt = DateTime.tryParse(p.createdAt)?.toUtc();
    if (dt == null) return 72.0;
    final diff = DateTime.now().toUtc().difference(dt);
    return (diff.inMinutes / 60.0).clamp(0.0, 8760.0);
  }

  double scoreOf(FeedPost p) {
    final r = recencyFactor(ageHoursUtc(p));
    final rPow = math.pow(r, recencySharpness).toDouble();
    return rPow *
        engagementFactor(p) *
        interestFactor(p) *
        unseenFactor(p.id);
  }

  // Precompute scores once — O(n) — avoids repeated work in sort comparators.
  final scored = nonReels.map((p) => MapEntry(p, scoreOf(p))).toList(growable: false);
  scored.sort((a, b) {
    final c = b.value.compareTo(a.value);
    if (c != 0) return c;
    return b.key.id.compareTo(a.key.id);
  });

  return List<FeedPost>.unmodifiable(scored.map((e) => e.key));
}
