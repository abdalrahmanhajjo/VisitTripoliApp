import 'dart:async' show unawaited;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/app_share.dart';
import 'package:go_router/go_router.dart';

import '../cache/app_cache_manager.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/interests_provider.dart';
import '../services/feed_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';
import '../utils/feedback_utils.dart';
import '../utils/feed_delete_permissions.dart';
import '../utils/feed_media_precache.dart';
import '../utils/feed_video_autoplay_controller.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_profile_icon_button.dart';
import '../widgets/reel_video.dart';

import '../social/community_feed_sort.dart';
import '../social/community_tokens.dart';
import '../social/feed_ranking.dart';
import '../social/feed_image_utils.dart';
import '../social/widgets/community_banners.dart';
import '../social/widgets/community_feed_header.dart';
import '../social/widgets/community_feed_states.dart';
import '../social/widgets/feed_post_card.dart';
import '../social/widgets/comments_sheet.dart';
import '../social/widgets/create_post_sheet.dart';
import '../social/widgets/edit_post_sheet.dart';
import '../social/widgets/community_post_actions.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _scrollController = ScrollController();
  final _commentController = TextEditingController();
  final _captionController = TextEditingController();
  final FeedVideoAutoplayController _feedVideoAutoplay = FeedVideoAutoplayController();
  Set<String>? _lastVideoPostIdsForAutoplay;
  String? _lastFeedPrecacheSig;
  bool _initialLoadDone = false;
  // UX: open Community on For You (personalized) feed.
  CommunityFeedSort _sortMode = CommunityFeedSort.newest;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      final auth = context.read<AuthProvider>();
      final feed = context.read<FeedProvider>();
      // Ensure the feed is shown on first open: fetch the first page when empty.
      // When posts are already cached, do not auto-refresh — user pulls down or taps Refresh.
      if (feed.posts.isEmpty) {
        feed.loadFeed(authToken: auth.authToken, refresh: true, sort: 'recent');
      }
      if (auth.isLoggedIn && !auth.isGuest) {
        feed.loadCanPost(auth.authToken!);
      }
    }
  }

  Future<void> _refreshFeedForCurrentTab() async {
    final auth = context.read<AuthProvider>();
    final feed = context.read<FeedProvider>();
    if (_sortMode == CommunityFeedSort.saved && auth.isLoggedIn && !auth.isGuest) {
      await feed.loadSavedFeed(authToken: auth.authToken!, refresh: true);
    } else {
      await feed.loadFeed(authToken: auth.authToken, refresh: true, sort: 'recent');
    }
    if (auth.isLoggedIn && !auth.isGuest) {
      await feed.loadCanPost(auth.authToken!);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels < pos.maxScrollExtent - 200) return;

    final provider = context.read<FeedProvider>();
    final auth = context.read<AuthProvider>();

    if (_sortMode == CommunityFeedSort.saved && auth.isLoggedIn && !auth.isGuest) {
      if (provider.loadingMoreSaved || !provider.hasMoreSaved) return;
      provider.loadMoreSaved(auth.authToken!);
    } else {
      if (provider.loadingMore || !provider.hasMore) return;
      provider.loadMore(auth.authToken);
    }
  }

  @override
  void dispose() {
    _feedVideoAutoplay.dispose();
    _scrollController.dispose();
    _commentController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final feed = context.watch<FeedProvider>();

    return Scaffold(
      backgroundColor: CommunityTokens.pageBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.navCommunity,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.6,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black26,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (feed.canPost?.isBusinessOwner ?? false)
            IconButton(
              icon: const Icon(Icons.mail_outline_rounded),
              tooltip: 'Customer proposals',
              onPressed: () => context.push('/proposals'),
            ),
          const AppProfileIconButton(),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        displacement: 48,
        strokeWidth: 2.5,
        onRefresh: _refreshFeedForCurrentTab,
        child: _buildFeedBody(auth, feed),
      ),
      floatingActionButton: auth.isLoggedIn &&
              !auth.isGuest &&
              (feed.canPost?.canPost ?? false)
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                heroTag: 'community_fab_create_post',
                onPressed: () => _openCreatePost(context, feed, auth),
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 22),
                label: Text(
                  AppLocalizations.of(context)!.createPost,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            )
          : null,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  // ignore: unused_element
  void _showFullscreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  fadeInDuration: const Duration(milliseconds: 150),
                  placeholder: (_, __) => Container(
                    color: Colors.black26,
                    child: const Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFullPost(
    BuildContext context,
    FeedPost post,
    FeedProvider feed,
    AuthProvider auth,
  ) async {
    final authToken = auth.authToken;
    final isLoggedIn = auth.isLoggedIn && !auth.isGuest;
    if (post.displayImageUrls.isEmpty && post.videoUrl == null) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setState) {
            final current = feed.posts
                    .where((p) => p.id == post.id)
                    .isNotEmpty
                ? feed.posts.firstWhere((p) => p.id == post.id)
                : post;

            final l10n = AppLocalizations.of(ctx2)!;
            final authorName =
                current.authorPlaceName ?? current.authorName ?? 'Place';
            final dpr = MediaQuery.devicePixelRatioOf(ctx2);
            final sw = MediaQuery.sizeOf(ctx2).width;
            final sh = MediaQuery.sizeOf(ctx2).height;
            final imgW = (sw * dpr).round().clamp(400, 1600);
            final imgH = (sh * dpr).round().clamp(400, 2400);

            Widget media;
            final imageUrls = current.displayImageUrls;
            if (imageUrls.isNotEmpty) {
              if (imageUrls.length == 1) {
                media = CachedNetworkImage(
                  imageUrl: imageUrls.first,
                  fit: BoxFit.contain,
                  cacheManager: AppImageCacheManager.instance,
                  memCacheWidth: imgW,
                  memCacheHeight: imgH,
                  maxWidthDiskCache: imgW,
                  maxHeightDiskCache: imgH,
                  fadeInDuration: const Duration(milliseconds: 120),
                  placeholder: (_, __) => Container(
                    color: Colors.black,
                    child: const Center(
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
                );
              } else {
                media = PageView.builder(
                  itemCount: imageUrls.length,
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: imageUrls[i],
                    fit: BoxFit.contain,
                    cacheManager: AppImageCacheManager.instance,
                    memCacheWidth: imgW,
                    memCacheHeight: imgH,
                    maxWidthDiskCache: imgW,
                    maxHeightDiskCache: imgH,
                    fadeInDuration: const Duration(milliseconds: 120),
                    placeholder: (_, __) => Container(
                      color: Colors.black,
                      child: const Center(
                        child: SizedBox(
                          width: 38,
                          height: 38,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
                  ),
                );
              }
            } else if (current.videoUrl != null && current.videoUrl!.isNotEmpty) {
              media = _DialogReelVideo(
                reelId: 'fullpost-${current.id}',
                videoUrl: current.videoUrl!,
                thumbnailUrl: current.imageUrl,
              );
            } else {
              media = const SizedBox.shrink();
            }

            return Dialog(
              backgroundColor: Colors.black,
              insetPadding: EdgeInsets.zero,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: current.authorPlaceId != null
                                  ? () {
                                      Navigator.pop(ctx2);
                                      context.push('/place/${current.authorPlaceId}/posts');
                                    }
                                  : null,
                              child: Row(
                                children: [
                                if (current.authorPlaceImage != null && current.authorPlaceImage!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: ClipOval(
                                      child: SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: CachedNetworkImage(
                                          imageUrl: current.authorPlaceImage!,
                                          fit: BoxFit.cover,
                                          cacheManager: AppImageCacheManager.instance,
                                          memCacheWidth: 72,
                                          memCacheHeight: 72,
                                          maxWidthDiskCache: 72,
                                          maxHeightDiskCache: 72,
                                          placeholder: (_, __) => Container(color: Colors.white24, child: Center(child: Text((authorName.isNotEmpty ? authorName[0] : '?').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
                                          errorWidget: (_, __, ___) => Container(color: Colors.white24, child: Center(child: Text((authorName.isNotEmpty ? authorName[0] : '?').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Colors.white24,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          (authorName.isNotEmpty ? authorName[0] : '?').toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    authorName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(ctx2),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: InteractiveViewer(
                        minScale: 0.75,
                        maxScale: 4,
                        child: Center(child: media),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FullPostActionButton(
                                icon: current.likedByMe
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                iconColor: current.likedByMe
                                    ? const Color(0xFFE11D48)
                                    : AppTheme.textSecondary,
                                count: current.hideLikes && !isLoggedIn
                                    ? null
                                    : current.likeCount,
                                onTap: () {
                                  if (authToken == null || authToken.isEmpty) {
                                    Navigator.pop(ctx2);
                                    context.go(
                                        '/login?redirect=${Uri.encodeComponent('/community')}');
                                    return;
                                  }
                                  AppFeedback.selection();
                                  unawaited(feed.toggleLike(authToken, current.id));
                                },
                              ),
                              const SizedBox(width: 18),
                              FullPostActionButton(
                                icon: Icons.chat_bubble_outline_rounded,
                                iconColor: AppTheme.textSecondary,
                                count: current.commentCount,
                                onTap: () => _openComments(
                                  context,
                                  current,
                                  authToken,
                                ),
                              ),
                              const SizedBox(width: 18),
                              FullPostActionButton(
                                icon: Icons.share_rounded,
                                iconColor: AppTheme.textSecondary,
                                onTap: () => _sharePost(current),
                              ),
                              const Spacer(),
                              if (authToken != null && authToken.isNotEmpty)
                                FullPostActionButton(
                                  icon: current.savedByMe
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  iconColor: current.savedByMe
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondary,
                                  onTap: () {
                                    AppFeedback.selection();
                                    unawaited(feed.toggleSave(authToken, current.id));
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (current.caption != null &&
                              current.caption!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              current.caption!.trim(),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (current.commentCount > 0)
                            TextButton(
                              onPressed: () => _openComments(
                                context,
                                current,
                                authToken,
                              ),
                              child: Text(
                                '${current.commentCount} ${l10n.comment.toLowerCase()}',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Mark as "seen" once the user has opened the full post viewer.
    feed.markPostSeen(post.id);
  }

  Future<void> _retryFeedLoad() async {
    final auth = context.read<AuthProvider>();
    final feed = context.read<FeedProvider>();
    feed.clearError();
    if (_sortMode == CommunityFeedSort.saved && auth.isLoggedIn && !auth.isGuest) {
      await feed.loadSavedFeed(authToken: auth.authToken!, refresh: true);
    } else {
      await feed.loadFeed(authToken: auth.authToken, refresh: true, sort: 'recent');
    }
    if (auth.isLoggedIn && !auth.isGuest) {
      await feed.loadCanPost(auth.authToken!);
    }
  }

  void _onFeedModeChanged(CommunityFeedSort m, AuthProvider auth, FeedProvider feed) {
    setState(() => _sortMode = m);
    if (m == CommunityFeedSort.saved && auth.isLoggedIn && !auth.isGuest) {
      feed.loadSavedFeed(authToken: auth.authToken!, refresh: true);
    } else if (m == CommunityFeedSort.newest) {
      if (feed.posts.isEmpty) {
        feed.loadFeed(authToken: auth.authToken, refresh: true, sort: 'recent');
      }
    }
  }

  Widget _buildFeedBody(AuthProvider auth, FeedProvider feed) {
    final isSaved = _sortMode == CommunityFeedSort.saved;
    final showSaved = isSaved && auth.isLoggedIn && !auth.isGuest;
    // Listen to interests changes so the "For You" ranking updates instantly.
    final interests = context.watch<InterestsProvider>();
    final interestKeywords = [
      for (final id in interests.selectedIds)
        ...interests.interests
            .where((i) => i.id == id)
            .expand((i) => [i.name, ...i.tags]),
    ];
    final matchCount = interestKeywords.where((k) => k.trim().isNotEmpty).length;
    final posts = showSaved
        ? feed.savedPosts
        : rankDiscoverForYou(
            posts: feed.posts,
            interestKeywords: interestKeywords,
            seenPostIds: feed.seenPostIds,
          );
    final loadingMore = showSaved ? feed.loadingMoreSaved : feed.loadingMore;
    final hasMore = showSaved ? feed.hasMoreSaved : feed.hasMore;
    // Use raw feed lists for loading/skeleton — not ranked/display list — so we
    // never show a blank state while the first page is still fetching.
    final mainPostsEmpty = showSaved ? feed.savedPosts.isEmpty : feed.posts.isEmpty;
    final mainLoading = showSaved ? feed.loadingSaved : feed.loading;

    if (isSaved && !auth.isLoggedIn) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: CommunityFeedHeader(
              selectedMode: _sortMode,
              matchCount: matchCount,
              isSavedAvailable: auth.isLoggedIn && !auth.isGuest,
              onSelectedMode: (m) => _onFeedModeChanged(m, auth, feed),
              onReels: () => context.push('/community/reels'),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: CommunityDealsBanner(),
            ),
          ),
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_border_rounded, size: 64, color: AppTheme.textTertiary),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign in to view saved posts',
                    style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.go('/login?redirect=${Uri.encodeComponent('/community')}'),
                    child: Text(AppLocalizations.of(context)!.signIn),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final showLoading = mainLoading && mainPostsEmpty;
    if (showLoading) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: CommunityFeedHeader(
              selectedMode: _sortMode,
              matchCount: matchCount,
              isSavedAvailable: auth.isLoggedIn && !auth.isGuest,
              onSelectedMode: (m) => _onFeedModeChanged(m, auth, feed),
              onReels: () => context.push('/community/reels'),
            ),
          ),
          if (!showSaved)
            SliverToBoxAdapter(
              child: CommunityPullToRefreshHint(
                onRefreshTap: () => unawaited(_refreshFeedForCurrentTab()),
              ),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: CommunityDealsBanner(),
            ),
          ),
          // Fast skeleton while the first page loads (no "Loading feed..." text).
          const SliverFillRemaining(child: CommunityFeedLoadingState()),
        ],
      );
    }

    if (posts.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          if (feed.error != null)
            CommunityFeedErrorBanner(
              feed.error!,
              onRetry: _retryFeedLoad,
            ),
          SliverToBoxAdapter(
            child: CommunityFeedHeader(
              selectedMode: _sortMode,
              matchCount: matchCount,
              isSavedAvailable: auth.isLoggedIn && !auth.isGuest,
              onSelectedMode: (m) => _onFeedModeChanged(m, auth, feed),
              onReels: () => context.push('/community/reels'),
            ),
          ),
          if (!showSaved)
            SliverToBoxAdapter(
              child: CommunityPullToRefreshHint(
                onRefreshTap: () => unawaited(_refreshFeedForCurrentTab()),
              ),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: CommunityDealsBanner(),
            ),
          ),
          SliverFillRemaining(
            child: isSaved
                ? const CommunitySavedEmptyState()
                : CommunityFeedEmptyState(
                    canPost: feed.canPost?.canPost ?? false,
                    isLoggedIn: auth.isLoggedIn && !auth.isGuest,
                    onLogin: () => context.go('/login?redirect=${Uri.encodeComponent('/community')}'),
                  ),
          ),
        ],
      );
    }

    final videoPostIds = posts
        .where((p) => p.videoUrl != null && p.videoUrl!.isNotEmpty)
        .map((p) => p.id)
        .toSet();
    if (!videoPostIdsEqual(_lastVideoPostIdsForAutoplay, videoPostIds)) {
      _lastVideoPostIdsForAutoplay = Set<String>.from(videoPostIds);
      final toRetain = Set<String>.from(videoPostIds);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _feedVideoAutoplay.retainOnly(toRetain);
      });
    }

    final precacheSig = '${posts.length}_${posts.take(8).map((p) => p.id).join(',')}';
    if (precacheSig != _lastFeedPrecacheSig) {
      _lastFeedPrecacheSig = precacheSig;
      scheduleFeedMediaPrecache(context, posts);
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      // Smaller than default: fewer off-screen feed cells + platform views to build.
      cacheExtent: 380,
      slivers: [
        if (feed.error != null)
          CommunityFeedErrorBanner(
            feed.error!,
            onRetry: _retryFeedLoad,
          ),
        SliverToBoxAdapter(
          child: CommunityFeedHeader(
            selectedMode: _sortMode,
            matchCount: matchCount,
            isSavedAvailable: auth.isLoggedIn && !auth.isGuest,
            onSelectedMode: (m) => _onFeedModeChanged(m, auth, feed),
            onReels: () => context.push('/community/reels'),
          ),
        ),
        if (!showSaved)
          SliverToBoxAdapter(
            child: CommunityPullToRefreshHint(
              onRefreshTap: () => unawaited(_refreshFeedForCurrentTab()),
            ),
          ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
            child: CommunityDealsBanner(),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == posts.length) {
                if (loadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
              final post = posts[index];
              return FeedPostCard(
                key: ValueKey<String>('feed_card_${post.id}'),
                post: post,
                feedVideoAutoplay: _feedVideoAutoplay,
                authToken: auth.authToken,
                isOwner: _isPostOwner(post, auth),
                canPost: feed.canPost?.canPost ?? false,
                onLike: () => feed.toggleLike(auth.authToken!, post.id),
                onSave: () => feed.toggleSave(auth.authToken!, post.id),
                onShare: () => _sharePost(post),
                onComment: () => _openComments(context, post, auth.authToken),
                onEdit: () => _openEditPost(context, post, feed, auth),
                onDelete: () => _confirmDelete(context, post, feed, auth),
                onReport: () => _reportPost(context, post, auth),
                onImageTap: (_) => _openFullPost(context, post, feed, auth),
                onShowOptions: () => _showPostOptionsMenu(context, post, feed, auth),
              );
            },
            childCount: posts.length + (hasMore ? 1 : 0),
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
          ),
        ),
      ],
    );
  }

  bool _isPostOwner(FeedPost post, AuthProvider auth) {
    if (!auth.isLoggedIn || auth.isGuest) return false;
    final uid = auth.userId;
    return uid != null && post.authorId == uid;
  }

  Future<void> _sharePost(FeedPost post) async {
    final text = post.caption ?? '';
    final postUrl = '${ApiConfig.appBaseUrl}/feed/${post.id}';
    final shareText = text.isNotEmpty ? '$text\n$postUrl' : postUrl;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.45,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
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
              const SizedBox(height: 6),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: Text(l10n.communityShare),
                onTap: () async {
                  Navigator.pop(ctx);
                  await sharePlainText(
                    shareText,
                    subject: l10n.sharePostSubject,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_rounded),
                title: Text(l10n.communityCopyLink),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Clipboard.setData(ClipboardData(text: postUrl));
                  if (mounted) AppSnackBars.showSuccess(context, l10n.linkCopied);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openComments(BuildContext context, FeedPost post, String? authToken) {
    if (authToken == null || authToken.isEmpty) {
      context.go('/login?redirect=${Uri.encodeComponent('/community')}');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CommentsSheet(
        post: post,
        authToken: authToken,
      ),
    );
  }

  Future<void> _openCreatePost(
      BuildContext context, FeedProvider feed, AuthProvider auth) async {
    final canPost = feed.canPost;
    if (canPost == null || !canPost.canPost) return;
    if (canPost.ownedPlaces.isEmpty && !canPost.isAdmin) {
      if (mounted) {
        AppSnackBars.showError(context, AppLocalizations.of(context)!.selectPlaceToPost);
      }
      return;
    }

    final result = await Navigator.push<FeedPost?>(
      context,
      MaterialPageRoute(
        builder: (ctx) => CreatePostSheet(
          ownedPlaces: canPost.ownedPlaces,
          isAdmin: canPost.isAdmin,
          authToken: auth.authToken!,
          userName: auth.userName,
        ),
      ),
    );
    if (result != null && mounted) {
      feed.prependPost(result);
    }
  }

  void _openEditPost(
      BuildContext context, FeedPost post, FeedProvider feed, AuthProvider auth) {
    Navigator.push<FeedPost?>(
      context,
      MaterialPageRoute(
        builder: (ctx) => EditPostSheet(
          post: post,
          authToken: auth.authToken!,
        ),
      ),
    ).then((updated) {
      if (updated != null) feed.updatePostLocally(updated);
    });
  }

  void _reportPost(BuildContext context, FeedPost post, AuthProvider auth) {
    if (auth.authToken == null || auth.authToken!.isEmpty) {
      context.go('/login?redirect=${Uri.encodeComponent('/community')}');
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityReportPost),
        content: Text(l10n.reportPostConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FeedService.instance.reportPost(
                  authToken: auth.authToken!,
                  postId: post.id,
                );
                if (context.mounted) AppSnackBars.showSuccess(context, l10n.postReportedThanks);
              } catch (e) {
                if (context.mounted) AppSnackBars.showError(context, e.toString());
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: Text(l10n.communityReport),
          ),
        ],
      ),
    );
  }

  void _showPostOptionsMenu(
    BuildContext context,
    FeedPost post,
    FeedProvider feed,
    AuthProvider auth,
  ) {
    final isOwner = _isPostOwner(post, auth);
    final canDelete = canDeleteFeedPost(
      post: post,
      canPost: feed.canPost,
      isAuthor: isOwner,
    );
    final postUrl = '${ApiConfig.appBaseUrl}/feed/${post.id}';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const SizedBox(height: 10),
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
              const SizedBox(height: 6),
              if (canDelete)
                PostOptionTile(
                  label: AppLocalizations.of(context)!.delete,
                  icon: Icons.delete_outline_rounded,
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(context, post, feed, auth);
                  },
                ),
              if (isOwner) ...[
                PostOptionTile(
                  label: AppLocalizations.of(context)!.edit,
                  icon: Icons.edit_outlined,
                  onTap: () {
                    Navigator.pop(ctx);
                    _openEditPost(context, post, feed, auth);
                  },
                ),
                PostOptionTile(
                  label: post.hideLikes
                      ? AppLocalizations.of(context)!.postShowLikeCountToOthers
                      : AppLocalizations.of(context)!.postHideLikeCountToOthers,
                  icon: Icons.favorite_border_rounded,
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final updated = await FeedService.instance.updatePostOptions(
                        authToken: auth.authToken!,
                        postId: post.id,
                        hideLikes: !post.hideLikes,
                      );
                      feed.updatePostLocally(updated);
                      if (context.mounted) {
                        AppSnackBars.showSuccess(
                          context,
                          post.hideLikes
                              ? AppLocalizations.of(context)!.postLikeCountVisibleSnackbar
                              : AppLocalizations.of(context)!.postLikeCountHiddenSnackbar,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) AppSnackBars.showError(context, e.toString());
                    }
                  },
                ),
                PostOptionTile(
                  label: post.commentsDisabled
                      ? AppLocalizations.of(context)!.postTurnOnCommenting
                      : AppLocalizations.of(context)!.postTurnOffCommenting,
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final updated = await FeedService.instance.updatePostOptions(
                        authToken: auth.authToken!,
                        postId: post.id,
                        commentsDisabled: !post.commentsDisabled,
                      );
                      feed.updatePostLocally(updated);
                      if (context.mounted) {
                        AppSnackBars.showSuccess(
                          context,
                          post.commentsDisabled
                              ? AppLocalizations.of(context)!.postCommentsOnSnackbar
                              : AppLocalizations.of(context)!.postCommentsOffSnackbar,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) AppSnackBars.showError(context, e.toString());
                    }
                  },
                ),
              ],
              if (auth.authToken != null && !isOwner) ...[
                PostOptionTile(
                  label: AppLocalizations.of(context)!.communityReport,
                  icon: Icons.flag_outlined,
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _reportPost(context, post, auth);
                  },
                ),
                PostOptionTile(
                  label: post.savedByMe
                      ? AppLocalizations.of(context)!.postRemoveFromFavorites
                      : AppLocalizations.of(context)!.postAddToFavorites,
                  icon: post.savedByMe ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await feed.toggleSave(auth.authToken!, post.id);
                  },
                ),
              ],
              PostOptionTile(
                label: AppLocalizations.of(context)!.communityGoToPost,
                icon: Icons.open_in_new_rounded,
                onTap: () {
                  Navigator.pop(ctx);
                  _openComments(context, post, auth.authToken);
                },
              ),
              PostOptionTile(
                label: AppLocalizations.of(context)!.communityShareTo,
                icon: Icons.share_rounded,
                onTap: () {
                  Navigator.pop(ctx);
                  _sharePost(post);
                },
              ),
              PostOptionTile(
                label: AppLocalizations.of(context)!.communityCopyLink,
                icon: Icons.link_rounded,
                onTap: () async {
                  Navigator.pop(ctx);
                  await Clipboard.setData(ClipboardData(text: postUrl));
                  if (context.mounted) {
                    AppSnackBars.showSuccess(context, AppLocalizations.of(context)!.linkCopied);
                  }
                },
              ),
              PostOptionTile(
                label: AppLocalizations.of(context)!.communityEmbed,
                icon: Icons.code_rounded,
                onTap: () {
                  Navigator.pop(ctx);
                  _showEmbedDialog(context, postUrl);
                },
              ),
              if (post.authorPlaceId != null)
                PostOptionTile(
                  label: AppLocalizations.of(context)!.viewPlacePosts,
                  icon: Icons.grid_view_rounded,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/place/${post.authorPlaceId}/posts');
                  },
                ),
              PostOptionTile(
                label: AppLocalizations.of(context)!.cancel,
                icon: Icons.close_rounded,
                onTap: () => Navigator.pop(ctx),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEmbedDialog(BuildContext context, String postUrl) {
    final l10n = AppLocalizations.of(context)!;
    final embedCode = '<iframe src="$postUrl" width="400" height="500" frameborder="0"></iframe>';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityEmbed),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.communityEmbedInstructions),
            const SizedBox(height: 12),
            SelectableText(embedCode, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: embedCode));
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (context.mounted) AppSnackBars.showSuccess(context, l10n.embedCodeCopied);
            },
            child: Text(l10n.communityCopyCode),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, FeedPost post, FeedProvider feed, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete),
        content: Text(AppLocalizations.of(context)!.deletePostConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FeedService.instance.deletePost(
                  authToken: auth.authToken!,
                  postId: post.id,
                );
                feed.removePostLocally(post.id);
                if (context.mounted) {
                  AppSnackBars.showSuccess(context, AppLocalizations.of(context)!.postDeleted);
                }
              } catch (e) {
                if (context.mounted) AppSnackBars.showError(context, e.toString());
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
}

/// Full-screen post dialog: owns mute state and shows on-video mute (Reels use the action rail instead).
class _DialogReelVideo extends StatefulWidget {
  final String reelId;
  final String videoUrl;
  final String? thumbnailUrl;

  const _DialogReelVideo({
    required this.reelId,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<_DialogReelVideo> createState() => _DialogReelVideoState();
}

class _DialogReelVideoState extends State<_DialogReelVideo> {
  bool _muted = true;

  @override
  Widget build(BuildContext context) {
    return ReelVideo(
      reelId: widget.reelId,
      videoUrl: widget.videoUrl,
      thumbnailUrl: widget.thumbnailUrl,
      isActive: true,
      isMuted: _muted,
      onMuteToggled: () => setState(() => _muted = !_muted),
      showMuteButton: true,
    );
  }
}
