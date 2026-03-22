import 'dart:math' as math;

import '../services/feed_service.dart';

/// Ranks non-video posts for **For You**: recency, light engagement, interests, unseen.
List<FeedPost> rankForYouFeed({
  required List<FeedPost> posts,
  required List<String> interestKeywords,
  required Set<String> seenPostIds,
}) {
  if (posts.isEmpty) return const [];

  final nonReels = posts.where((p) => p.type != 'video').toList();

  double score(FeedPost p) {
    DateTime? dt;
    try {
      dt = DateTime.tryParse(p.createdAt)?.toUtc();
    } catch (_) {}
    final ageH = dt != null
        ? DateTime.now().toUtc().difference(dt).inMinutes / 60.0
        : 48.0;
    final recency = 1.0 / (1.0 + ageH / 12.0);

    final engagement = math.log(p.likeCount + 2 * p.commentCount + 1) / math.ln10;

    var interestBoost = 1.0;
    if (interestKeywords.isNotEmpty) {
      final cap = (p.caption ?? '').toLowerCase();
      final place = (p.authorPlaceName ?? '').toLowerCase();
      for (final k in interestKeywords) {
        final t = k.trim().toLowerCase();
        if (t.isEmpty) continue;
        if (cap.contains(t) || place.contains(t)) {
          interestBoost = 1.4;
          break;
        }
      }
    }

    final unseen = seenPostIds.contains(p.id) ? 0.88 : 1.0;
    return recency * (1.0 + 0.35 * engagement) * interestBoost * unseen;
  }

  nonReels.sort((a, b) {
    final cmp = score(b).compareTo(score(a));
    if (cmp != 0) return cmp;
    return b.id.compareTo(a.id);
  });

  return List<FeedPost>.unmodifiable(nonReels);
}
