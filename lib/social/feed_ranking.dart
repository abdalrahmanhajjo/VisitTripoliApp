import '../services/feed_service.dart';

/// Web-parity Discover ordering:
/// - Preserve API order (`sort=recent` already applied by backend).
/// - Keep reels out of the feed tab.
/// - Move unseen posts before seen posts, while preserving relative order.
List<FeedPost> rankDiscoverForYou({
  required List<FeedPost> posts,
  required Set<String> seenPostIds,
}) {
  if (posts.isEmpty) return const [];

  final unseen = <FeedPost>[];
  final seen = <FeedPost>[];
  for (final p in posts) {
    if (p.type == 'video') continue;
    if (seenPostIds.contains(p.id)) {
      seen.add(p);
    } else {
      unseen.add(p);
    }
  }
  return List<FeedPost>.unmodifiable([...unseen, ...seen]);
}
