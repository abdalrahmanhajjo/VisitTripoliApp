import '../services/feed_service.dart';

/// Discover **For You**: same order as the API (`sort=recent`) — **newest first**.
/// Reel posts (`type == video`) stay in Reels only and are omitted here.
List<FeedPost> orderDiscoverFeedNewestFirst(List<FeedPost> posts) {
  if (posts.isEmpty) return const [];

  final list = posts.where((p) => p.type != 'video').toList();
  list.sort((a, b) {
    final da = DateTime.tryParse(a.createdAt)?.toUtc();
    final db = DateTime.tryParse(b.createdAt)?.toUtc();
    if (da != null && db != null) {
      final c = db.compareTo(da);
      if (c != 0) return c;
    } else if (da != null) {
      return -1;
    } else if (db != null) {
      return 1;
    }
    return b.id.compareTo(a.id);
  });

  return List<FeedPost>.unmodifiable(list);
}
