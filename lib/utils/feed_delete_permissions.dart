import '../services/feed_service.dart';

/// Whether the current user may manage this feed post (edit/delete/options).
bool canManageFeedPost({
  required FeedPost post,
  required CanPostResponse? canPost,
  required bool isAuthor,
}) {
  if (canPost?.isAdmin == true) return true;
  if (isAuthor) return true;
  final pid = post.authorPlaceId;
  if (pid == null || pid.isEmpty) return false;
  return canPost?.ownedPlaces.any((o) => o.id == pid) ?? false;
}

bool canDeleteFeedPost({
  required FeedPost post,
  required CanPostResponse? canPost,
  required bool isAuthor,
}) {
  return canManageFeedPost(post: post, canPost: canPost, isAuthor: isAuthor);
}
