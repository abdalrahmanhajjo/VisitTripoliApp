import '../services/feed_service.dart';

/// Whether the current user may delete this feed post (matches [DELETE /api/feed/:id] rules).
bool canDeleteFeedPost({
  required FeedPost post,
  required CanPostResponse? canPost,
  required bool isAuthor,
}) {
  if (canPost?.isAdmin == true) return true;
  if (post.type != 'video') {
    return isAuthor;
  }
  final pid = post.authorPlaceId;
  if (pid == null || pid.isEmpty) return false;
  return canPost?.ownedPlaces.any((o) => o.id == pid) ?? false;
}
