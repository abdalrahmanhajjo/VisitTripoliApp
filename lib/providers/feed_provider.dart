import 'package:flutter/foundation.dart';

import '../cache/app_cache_manager.dart';
import '../services/feed_service.dart';

class FeedProvider extends ChangeNotifier {
  final FeedService _service = FeedService.instance;

  List<FeedPost> _posts = [];
  /// Session memory: posts opened in full viewer (used by For You ranking).
  final Set<String> _seenPostIds = <String>{};
  /// `recent` = chronological cursor feed; `trending` = server engagement ranking + offset pages.
  String _feedSort = 'recent';
  int? _nextTrendingOffset;
  String? _nextCursor;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  CanPostResponse? _canPost;

  List<FeedPost> _savedPosts = [];
  String? _savedNextCursor;
  bool _loadingSaved = false;
  bool _loadingMoreSaved = false;

  List<FeedPost> _likedPosts = [];
  String? _likedNextCursor;
  bool _loadingLiked = false;
  bool _loadingMoreLiked = false;

  List<FeedPost> _placePosts = [];
  String? _placePlaceId;
  PlaceFeedInfo? _placeFeedInfo;
  String? _placeNextCursor;
  bool _loadingPlace = false;
  bool _loadingMorePlace = false;

  List<FeedPost> _reels = [];
  String? _reelsNextCursor;
  bool _loadingReels = false;
  bool _loadingMoreReels = false;

  List<FeedPost> get posts => List.unmodifiable(_posts);

  /// Which API sort the main [_posts] list was loaded with (`recent` | `trending`).
  String get feedSort => _feedSort;

  Set<String> get seenPostIds => Set.unmodifiable(_seenPostIds);

  void markPostSeen(String postId) {
    if (_seenPostIds.add(postId)) {
      notifyListeners();
    }
  }

  List<FeedPost> get savedPosts => List.unmodifiable(_savedPosts);
  List<FeedPost> get likedPosts => List.unmodifiable(_likedPosts);

  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get loadingSaved => _loadingSaved;
  bool get loadingMoreSaved => _loadingMoreSaved;
  bool get loadingLiked => _loadingLiked;
  bool get loadingMoreLiked => _loadingMoreLiked;

  String? get error => _error;
  CanPostResponse? get canPost => _canPost;
  bool get hasMore =>
      _feedSort == 'trending' ? (_nextTrendingOffset != null) : (_nextCursor != null);
  bool get hasMoreSaved => _savedNextCursor != null;
  bool get hasMoreLiked => _likedNextCursor != null;

  List<FeedPost> get placePosts => List.unmodifiable(_placePosts);
  String? get placePostsPlaceId => _placePlaceId;
  PlaceFeedInfo? get placeFeedInfo => _placeFeedInfo;
  bool get loadingPlace => _loadingPlace;
  bool get loadingMorePlace => _loadingMorePlace;
  bool get hasMorePlace => _placeNextCursor != null;

  List<FeedPost> get reels => List.unmodifiable(_reels);
  bool get loadingReels => _loadingReels;

  /// Latest in-memory copy of a post (any list), for UI that opened with a snapshot.
  FeedPost? postById(String postId) {
    for (final p in _posts) {
      if (p.id == postId) return p;
    }
    for (final p in _savedPosts) {
      if (p.id == postId) return p;
    }
    for (final p in _likedPosts) {
      if (p.id == postId) return p;
    }
    for (final p in _reels) {
      if (p.id == postId) return p;
    }
    for (final p in _placePosts) {
      if (p.id == postId) return p;
    }
    return null;
  }
  bool get loadingMoreReels => _loadingMoreReels;
  bool get hasMoreReels => _reelsNextCursor != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  static const int _initialLimit = 10;
  static const int _pageLimit = 15;

  /// First occurrence wins (API order); prevents duplicate keys if pages overlap.
  static List<FeedPost> _dedupeById(List<FeedPost> list) {
    final seen = <String>{};
    final out = <FeedPost>[];
    for (final p in list) {
      if (p.id.isEmpty) continue;
      if (seen.add(p.id)) out.add(p);
    }
    return out;
  }

  Future<void> loadFeed({
    String? authToken,
    bool refresh = false,
    String sort = 'recent',
  }) async {
    final normalized = sort == 'trending' ? 'trending' : 'recent';
    if (_loading && !refresh) return;

    if (normalized != _feedSort) {
      if (_posts.isNotEmpty) {
        await AppImageCacheManager.evictUrlsForPosts(_posts);
      }
      _feedSort = normalized;
      _nextCursor = null;
      _nextTrendingOffset = null;
      _posts = [];
    } else if (refresh) {
      _nextCursor = null;
      _nextTrendingOffset = null;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (refresh && _posts.isNotEmpty) {
        await AppImageCacheManager.evictUrlsForPosts(_posts);
      }
      final FeedResponse res;
      if (_feedSort == 'trending') {
        res = await _service.getFeed(
          authToken: authToken,
          limit: _initialLimit,
          sort: 'trending',
          offset: 0,
        );
        _posts = _dedupeById(res.posts);
        _nextTrendingOffset = res.nextOffset;
        _nextCursor = null;
      } else {
        res = await _service.getFeed(
          authToken: authToken,
          before: null,
          limit: _initialLimit,
          sort: 'recent',
        );
        _posts = _dedupeById(res.posts);
        _nextCursor = res.nextCursor;
        _nextTrendingOffset = null;
      }
    } on FeedException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore(String? authToken) async {
    if (_feedSort == 'trending') {
      if (_loadingMore || _nextTrendingOffset == null) return;
    } else {
      if (_loadingMore || _nextCursor == null) return;
    }
    _loadingMore = true;
    notifyListeners();

    try {
      final FeedResponse res;
      if (_feedSort == 'trending') {
        res = await _service.getFeed(
          authToken: authToken,
          limit: _pageLimit,
          sort: 'trending',
          offset: _nextTrendingOffset,
        );
        _posts = _dedupeById([..._posts, ...res.posts]);
        _nextTrendingOffset = res.nextOffset;
      } else {
        res = await _service.getFeed(
          authToken: authToken,
          before: _nextCursor,
          limit: _pageLimit,
          sort: 'recent',
        );
        _posts = _dedupeById([..._posts, ...res.posts]);
        _nextCursor = res.nextCursor;
      }
    } catch (_) {
      // ignore
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedFeed({required String authToken, bool refresh = false}) async {
    if (refresh) _savedNextCursor = null;
    if (_loadingSaved && !refresh) return;
    _loadingSaved = true;
    _error = null;
    notifyListeners();

    try {
      if (refresh && _savedPosts.isNotEmpty) {
        await AppImageCacheManager.evictUrlsForPosts(_savedPosts);
      }
      final limit = _savedPosts.isEmpty ? _initialLimit : _pageLimit;
      final res = await _service.getSavedFeed(
        authToken: authToken,
        before: refresh ? null : _savedNextCursor,
        limit: limit,
      );
      if (refresh) {
        _savedPosts = res.posts;
      } else {
        _savedPosts = [..._savedPosts, ...res.posts];
      }
      _savedNextCursor = res.nextCursor;
    } on FeedException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingSaved = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSaved(String authToken) async {
    if (_loadingMoreSaved || _savedNextCursor == null) return;
    _loadingMoreSaved = true;
    notifyListeners();

    try {
      final res = await _service.getSavedFeed(
        authToken: authToken,
        before: _savedNextCursor,
        limit: _pageLimit,
      );
      _savedPosts = [..._savedPosts, ...res.posts];
      _savedNextCursor = res.nextCursor;
    } catch (_) {
      // ignore
    } finally {
      _loadingMoreSaved = false;
      notifyListeners();
    }
  }

  Future<void> loadLikedFeed({required String authToken, bool refresh = false}) async {
    if (refresh) _likedNextCursor = null;
    if (_loadingLiked && !refresh) return;
    _loadingLiked = true;
    _error = null;
    notifyListeners();

    try {
      if (refresh && _likedPosts.isNotEmpty) {
        await AppImageCacheManager.evictUrlsForPosts(_likedPosts);
      }
      final limit = _likedPosts.isEmpty ? _initialLimit : _pageLimit;
      final res = await _service.getLikedFeed(
        authToken: authToken,
        before: refresh ? null : _likedNextCursor,
        limit: limit,
      );
      if (refresh) {
        _likedPosts = res.posts;
      } else {
        _likedPosts = [..._likedPosts, ...res.posts];
      }
      _likedNextCursor = res.nextCursor;
    } on FeedException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingLiked = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreLiked(String authToken) async {
    if (_loadingMoreLiked || _likedNextCursor == null) return;
    _loadingMoreLiked = true;
    notifyListeners();

    try {
      final res = await _service.getLikedFeed(
        authToken: authToken,
        before: _likedNextCursor,
        limit: _pageLimit,
      );
      _likedPosts = [..._likedPosts, ...res.posts];
      _likedNextCursor = res.nextCursor;
    } catch (_) {
      // ignore
    } finally {
      _loadingMoreLiked = false;
      notifyListeners();
    }
  }

  Future<void> loadReels({String? authToken, bool refresh = false}) async {
    if (refresh) _reelsNextCursor = null;
    if (_loadingReels && !refresh) return;
    _loadingReels = true;
    _error = null;
    notifyListeners();

    try {
      if (refresh && _reels.isNotEmpty) {
        await AppImageCacheManager.evictUrlsForPosts(_reels);
      }
      final res = await _service.getReels(
        authToken: authToken,
        before: refresh ? null : _reelsNextCursor,
        limit: _pageLimit,
      );
      if (refresh) {
        _reels = res.posts;
      } else {
        _reels = [..._reels, ...res.posts];
      }
      _reelsNextCursor = res.nextCursor;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingReels = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreReels({String? authToken}) async {
    if (_loadingMoreReels || _reelsNextCursor == null) return;
    _loadingMoreReels = true;
    notifyListeners();

    try {
      final res = await _service.getReels(
        authToken: authToken,
        before: _reelsNextCursor,
        limit: _pageLimit,
      );
      _reels = [..._reels, ...res.posts];
      _reelsNextCursor = res.nextCursor;
    } catch (_) {
    } finally {
      _loadingMoreReels = false;
      notifyListeners();
    }
  }

  Future<void> loadPlacePosts({required String placeId, String? authToken, bool refresh = true}) async {
    if (refresh) {
      _placeNextCursor = null;
      _placePlaceId = placeId;
    }
    if (_loadingPlace && !refresh) return;
    _loadingPlace = true;
    _error = null;
    notifyListeners();

    try {
      if (refresh && _placePosts.isNotEmpty) {
        await AppImageCacheManager.evictUrlsForPosts(_placePosts);
      }
      final limit = _placePosts.isEmpty ? _initialLimit : _pageLimit;
      final res = await _service.getPlacePosts(
        placeId: placeId,
        authToken: authToken,
        before: refresh ? null : _placeNextCursor,
        limit: limit,
      );
      if (refresh) {
        _placePosts = res.posts;
        _placeFeedInfo = res.place;
      } else {
        _placePosts = [..._placePosts, ...res.posts];
      }
      _placeNextCursor = res.nextCursor;
    } on FeedException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingPlace = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePlacePosts(String placeId, String? authToken) async {
    if (_loadingMorePlace || _placeNextCursor == null || _placePlaceId != placeId) return;
    _loadingMorePlace = true;
    notifyListeners();

    try {
      final res = await _service.getPlacePosts(
        placeId: placeId,
        authToken: authToken,
        before: _placeNextCursor,
        limit: _pageLimit,
      );
      _placePosts = [..._placePosts, ...res.posts];
      _placeNextCursor = res.nextCursor;
    } catch (_) {
      // ignore
    } finally {
      _loadingMorePlace = false;
      notifyListeners();
    }
  }

  Future<void> loadCanPost(String authToken) async {
    try {
      _canPost = await _service.canPost(authToken);
      notifyListeners();
    } catch (_) {
      _canPost = null;
      notifyListeners();
    }
  }

  Future<bool> toggleLike(String authToken, String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    final placeIdx = _placePosts.indexWhere((p) => p.id == postId);
    final reelIdx = _reels.indexWhere((p) => p.id == postId);
    final likedIdx = _likedPosts.indexWhere((p) => p.id == postId);
    final old = idx >= 0 ? _posts[idx] : (placeIdx >= 0 ? _placePosts[placeIdx] : (reelIdx >= 0 ? _reels[reelIdx] : (likedIdx >= 0 ? _likedPosts[likedIdx] : null)));
    if (old == null) return false;

    // ── Optimistic update: flip instantly in UI ──
    final optimistic = old.copyWith(
      likedByMe: !old.likedByMe,
      likeCount: old.likedByMe ? (old.likeCount - 1).clamp(0, 999999) : old.likeCount + 1,
    );
    void _apply(FeedPost p) {
      if (idx >= 0) { _posts = List.from(_posts); _posts[idx] = p; }
      if (placeIdx >= 0) { _placePosts = List.from(_placePosts); _placePosts[placeIdx] = p; }
      if (reelIdx >= 0) { _reels = List.from(_reels); _reels[reelIdx] = p; }
      if (likedIdx >= 0) { _likedPosts = List.from(_likedPosts); _likedPosts[likedIdx] = p; }
    }
    _apply(optimistic);
    notifyListeners();

    try {
      final res = await _service.toggleLike(authToken: authToken, postId: postId);
      final confirmed = old.copyWith(likedByMe: res.liked, likeCount: res.likeCount);
      _apply(confirmed);
      // Remove from likedPosts if unliked
      if (!res.liked && likedIdx >= 0) {
        _likedPosts = _likedPosts.where((p) => p.id != postId).toList();
      }
      notifyListeners();
      return res.liked;
    } catch (_) {
      // Rollback on failure
      _apply(old);
      notifyListeners();
      return old.likedByMe;
    }
  }

  Future<bool> toggleSave(String authToken, String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    final savedIdx = _savedPosts.indexWhere((p) => p.id == postId);
    final likedIdx = _likedPosts.indexWhere((p) => p.id == postId);
    final placeIdx = _placePosts.indexWhere((p) => p.id == postId);
    final reelIdx = _reels.indexWhere((p) => p.id == postId);
    final old = idx >= 0
        ? _posts[idx]
        : (savedIdx >= 0
            ? _savedPosts[savedIdx]
            : (likedIdx >= 0
                ? _likedPosts[likedIdx]
                : (placeIdx >= 0
                    ? _placePosts[placeIdx]
                    : (reelIdx >= 0 ? _reels[reelIdx] : null))));
    if (old == null) return false;

    final optimistic = old.copyWith(savedByMe: !old.savedByMe);
    void apply(FeedPost p) {
      if (idx >= 0) {
        _posts = List.from(_posts);
        _posts[idx] = p;
      }
      if (savedIdx >= 0 && !p.savedByMe) {
        _savedPosts = _savedPosts.where((x) => x.id != postId).toList();
      } else if (savedIdx >= 0) {
        _savedPosts = List.from(_savedPosts);
        _savedPosts[savedIdx] = p;
      }
      if (likedIdx >= 0) {
        _likedPosts = List.from(_likedPosts);
        _likedPosts[likedIdx] = p;
      }
      if (placeIdx >= 0) {
        _placePosts = List.from(_placePosts);
        _placePosts[placeIdx] = p;
      }
      if (reelIdx >= 0) {
        _reels = List.from(_reels);
        _reels[reelIdx] = p;
      }
    }

    apply(optimistic);
    notifyListeners();

    try {
      final res = await _service.toggleSave(authToken: authToken, postId: postId);
      final confirmed = old.copyWith(savedByMe: res.saved);
      apply(confirmed);
      if (savedIdx >= 0 && !res.saved) {
        _savedPosts = _savedPosts.where((p) => p.id != postId).toList();
      }
      notifyListeners();
      return res.saved;
    } catch (_) {
      apply(old);
      notifyListeners();
      return old.savedByMe;
    }
  }

  void updatePostLocally(FeedPost updated) {
    void _upd(List<FeedPost> target, void Function(List<FeedPost>) setter) {
      final i = target.indexWhere((p) => p.id == updated.id);
      if (i >= 0) {
        final list = List<FeedPost>.from(target);
        list[i] = updated;
        setter(list);
      }
    }
    _upd(_posts, (l) { _posts = l; });
    _upd(_savedPosts, (l) => _savedPosts = l);
    _upd(_likedPosts, (l) => _likedPosts = l);
    _upd(_reels, (l) => _reels = l);
    _upd(_placePosts, (l) => _placePosts = l);
    notifyListeners();
  }

  void removePostLocally(String postId) {
    _posts = _posts.where((p) => p.id != postId).toList();
    _savedPosts = _savedPosts.where((p) => p.id != postId).toList();
    _likedPosts = _likedPosts.where((p) => p.id != postId).toList();
    _reels = _reels.where((p) => p.id != postId).toList();
    _placePosts = _placePosts.where((p) => p.id != postId).toList();
    notifyListeners();
  }

  void prependPost(FeedPost post) {
    _posts = [post, ..._posts];
    if (post.type == 'video') {
      _reels = [post, ..._reels];
    }
    notifyListeners();
  }

  void incrementCommentCount(String postId) {
    void _inc(List<FeedPost> target, void Function(List<FeedPost>) setter) {
      final i = target.indexWhere((p) => p.id == postId);
      if (i >= 0) {
        final list = List<FeedPost>.from(target);
        list[i] = list[i].copyWith(commentCount: list[i].commentCount + 1);
        setter(list);
      }
    }
    _inc(_posts, (l) { _posts = l; });
    _inc(_savedPosts, (l) => _savedPosts = l);
    _inc(_likedPosts, (l) => _likedPosts = l);
    _inc(_reels, (l) => _reels = l);
    _inc(_placePosts, (l) => _placePosts = l);
    notifyListeners();
  }

  void decrementCommentCount(String postId) {
    void _dec(List<FeedPost> target, void Function(List<FeedPost>) setter) {
      final i = target.indexWhere((p) => p.id == postId);
      if (i >= 0) {
        final list = List<FeedPost>.from(target);
        list[i] = list[i].copyWith(commentCount: (list[i].commentCount - 1).clamp(0, 999999));
        setter(list);
      }
    }
    _dec(_posts, (l) { _posts = l; });
    _dec(_savedPosts, (l) => _savedPosts = l);
    _dec(_likedPosts, (l) => _likedPosts = l);
    _dec(_reels, (l) => _reels = l);
    _dec(_placePosts, (l) => _placePosts = l);
    notifyListeners();
  }
}
