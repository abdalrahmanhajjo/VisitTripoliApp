import 'dart:async' show unawaited;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config/api_config.dart';
import '../cache/app_cache_manager.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/places_provider.dart';
import '../services/feed_service.dart';
import '../utils/app_share.dart';
import '../utils/feedback_utils.dart';
import '../utils/feed_delete_permissions.dart';
import '../utils/feed_media_precache.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import 'package:tripoli_explorer/l10n/app_localizations.dart';
import '../social/community_tokens.dart';
import '../social/widgets/comments_sheet.dart';
import '../utils/snackbar_utils.dart';

enum PostSortOption { newest, oldest, popular }

/// Instagram/TikTok-style posts page for a place. Shows grid of posts from that place.
class PlacePostsScreen extends StatefulWidget {
  final String placeId;

  const PlacePostsScreen({super.key, required this.placeId});

  @override
  State<PlacePostsScreen> createState() => _PlacePostsScreenState();
}

class _PlacePostsScreenState extends State<PlacePostsScreen> {
  final ScrollController _scrollController = ScrollController();
  PostSortOption _sortOption = PostSortOption.newest;
  /// Avoids redundant precache work when [build] runs without post list changes.
  String? _lastPrecacheSig;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final feed = context.read<FeedProvider>();
      AppFeedback.tap();
      final auth = context.read<AuthProvider>();
      if (feed.hasMorePlace && feed.placePostsPlaceId == widget.placeId) {
        feed.loadMorePlacePosts(widget.placeId, auth.authToken);
      }
    }
  }

  Future<void> _loadIfNeeded() async {
    final feed = context.read<FeedProvider>();
    final auth = context.read<AuthProvider>();
    final token = auth.authToken;
    if (token != null) await feed.loadCanPost(token);
    await feed.loadPlacePosts(
      placeId: widget.placeId,
      authToken: auth.authToken,
      refresh: true,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedProvider>();
    final auth = context.watch<AuthProvider>();
    final places = context.watch<PlacesProvider>();
    final place = places.getPlaceById(widget.placeId);
    final placeInfo = feed.placeFeedInfo;
    final rawPosts = feed.placePosts;
    
    final posts = List<FeedPost>.from(rawPosts);
    switch (_sortOption) {
      case PostSortOption.newest:
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case PostSortOption.oldest:
        posts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case PostSortOption.popular:
        posts.sort((a, b) => (b.likeCount + b.commentCount).compareTo(a.likeCount + a.commentCount));
        break;
    }

    if (posts.isNotEmpty) {
      final sig = '${posts.length}:${posts.map((p) => p.id).join(',')}';
      if (sig != _lastPrecacheSig) {
        _lastPrecacheSig = sig;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          scheduleFeedMediaPrecache(context, posts);
        });
      }
    }
    
    final isLoading = feed.loadingPlace && posts.isEmpty;
    final loadError = feed.error;
    final placeName = placeInfo?.name ?? place?.name ?? 'Place';
    final placeImage = placeInfo?.image ?? (place?.images.isNotEmpty == true ? place!.images.first : null);

    final coverImageUrl = placeImage != null
        ? (placeImage.startsWith('http') ? placeImage : '${ApiConfig.effectiveBaseUrl}$placeImage')
        : null;

    return Scaffold(
      backgroundColor: CommunityTokens.pageBackground,
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () => _loadIfNeeded(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: CommunityTokens.pageBackground,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverImageUrl != null)
                    CachedNetworkImage(
                      imageUrl: coverImageUrl,
                      fit: BoxFit.cover,
                      cacheManager: AppImageCacheManager.instance,
                      memCacheWidth: 900,
                      memCacheHeight: 700,
                      maxWidthDiskCache: 1200,
                      maxHeightDiskCache: 900,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      placeholder: (_, __) => Container(color: AppTheme.surfaceVariant),
                      errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceVariant),
                    )
                  else
                    Container(color: AppTheme.primaryColor),
                  
                  // Gradient overlay for smooth contrast
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                        stops: const [0.0, 0.2, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The sleek curved bottom overlap
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(24),
              child: Container(
                height: 24,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            )
          else if (posts.isEmpty && loadError != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 52,
                        color: AppTheme.textTertiary.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to load posts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loadError,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => _loadIfNeeded(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: Text(AppLocalizations.of(context)!.retry),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.collections_outlined,
                        size: 48,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No stories yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Moments captured here will appear in the grid.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 64), // visual lift
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: _PlaceHeader(
                placeName: placeName,
                placeImage: coverImageUrl,
                postCount: posts.length,
                currentSort: _sortOption,
                onSortChanged: (val) { AppFeedback.selection(); setState(() => _sortOption = val); },
              ),
            ),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 1.5,
                crossAxisSpacing: 1.5,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = posts[index];
                  return _PostGridTile(
                    post: post,
                    onTap: () { AppFeedback.tap(); _openPost(context, post, feed, auth); },
                  );
                },
                childCount: posts.length,
              ),
            ),
            if (feed.loadingMorePlace)
              const SliverToBoxAdapter(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Bottom padding for standard scroll offset
            const SliverToBoxAdapter(
              child: SafeArea(top: false, child: SizedBox(height: 24)),
            ),
          ],
        ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  void _openPost(
    BuildContext context,
    FeedPost post,
    FeedProvider feed,
    AuthProvider auth,
  ) {
    if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
      context.push(
        Uri(
          path: '/community/reels',
          queryParameters: {'postId': post.id},
        ).toString(),
      );
    } else {
      _openFullPost(context, post, feed, auth);
    }
  }

  void _openFullPost(
    BuildContext context,
    FeedPost post,
    FeedProvider feed,
    AuthProvider auth,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: _FullPostDialog(
          post: post,
          feed: feed,
          auth: auth,
          onClose: () { AppFeedback.tap(); Navigator.of(ctx).pop(); },
        ),
      ),
    ).then((_) {
      feed.markPostSeen(post.id);
    });
  }
}

class _PlaceHeader extends StatelessWidget {
  final String placeName;
  final String? placeImage;
  final int postCount;
  final PostSortOption currentSort;
  final ValueChanged<PostSortOption> onSortChanged;

  const _PlaceHeader({
    required this.placeName,
    this.placeImage,
    required this.postCount,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Elevated Circle Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4), // white border
            child: ClipOval(
              child: SizedBox(
                width: 82,
                height: 82,
                child: placeImage != null && placeImage!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: placeImage!,
                        fit: BoxFit.cover,
                        cacheManager: AppImageCacheManager.instance,
                        memCacheWidth: 200,
                        memCacheHeight: 200,
                        maxWidthDiskCache: 200,
                        maxHeightDiskCache: 200,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (_, __) => Container(
                          color: AppTheme.surfaceVariant,
                          child: const Icon(Icons.storefront_rounded, size: 36, color: AppTheme.textTertiary),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.surfaceVariant,
                          child: const Icon(Icons.storefront_rounded, size: 36, color: AppTheme.textTertiary),
                        ),
                      )
                    : Container(
                        color: AppTheme.surfaceVariant,
                        child: const Icon(Icons.storefront_rounded, size: 36, color: AppTheme.textTertiary),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  placeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$postCount',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            postCount == 1 ? l10n.feedPostSingular : l10n.feedPostPlural,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<PostSortOption>(
                      initialValue: currentSort,
                      onSelected: onSortChanged,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      elevation: 8,
                      position: PopupMenuPosition.under,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.surfaceVariant),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sort_rounded, size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              currentSort == PostSortOption.newest
                                  ? AppLocalizations.of(context)!.postSortNewest
                                  : currentSort == PostSortOption.oldest
                                      ? AppLocalizations.of(context)!.postSortOldest
                                      : AppLocalizations.of(context)!.postSortPopular,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return [
                          PopupMenuItem(
                            value: PostSortOption.newest,
                            child: Text(l10n.postSortNewestFirst, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          PopupMenuItem(
                            value: PostSortOption.popular,
                            child: Text(l10n.postSortMostPopular, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          PopupMenuItem(
                            value: PostSortOption.oldest,
                            child: Text(l10n.postSortOldestFirst, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostGridTile extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onTap;

  const _PostGridTile({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hasImage = post.displayImageUrls.isNotEmpty;
    final imageUrl = hasImage ? post.displayImageUrls.first : null;
    final isVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;
    final isOwner = post.authorId != null &&
        auth.userId != null &&
        post.authorId == auth.userId;
    final canSeeLikes = !post.hideLikes || isOwner;
    final multiImage = post.displayImageUrls.length > 1;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: AppImageCacheManager.resolveNetworkImageUrl(imageUrl),
                fit: BoxFit.cover,
                cacheManager: AppImageCacheManager.instance,
                memCacheWidth: 400,
                memCacheHeight: 400,
                maxWidthDiskCache: 400,
                maxHeightDiskCache: 400,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                filterQuality: FilterQuality.medium,
                placeholder: (_, __) => Container(color: AppTheme.surfaceVariant),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.surfaceVariant,
                  child: const Icon(Icons.broken_image_outlined, color: AppTheme.textTertiary),
                ),
              )
            else
              Container(
                color: const Color(0xFF1E1E1E),
                child: const Icon(Icons.movie_creation_outlined, color: Colors.white38, size: 36),
              ),

            // Bottom readability gradient + engagement hint
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),

            if (multiImage)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: const Icon(Icons.layers_rounded, color: Colors.white, size: 14),
                ),
              ),

            if (!isVideo && canSeeLikes)
              Positioned(
                left: 6,
                bottom: 5,
                right: 6,
                child: Row(
                  children: [
                    Icon(
                      post.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 13,
                      color: post.likedByMe ? const Color(0xFFFF8FA3) : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(post.likeCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              )
            else if (!isVideo && !canSeeLikes)
              Positioned(
                left: 6,
                bottom: 6,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),

            if (isVideo) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.6,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _FullPostDialog extends StatefulWidget {
  final FeedPost post;
  final FeedProvider feed;
  final AuthProvider auth;
  final VoidCallback onClose;

  const _FullPostDialog({
    required this.post,
    required this.feed,
    required this.auth,
    required this.onClose,
  });

  @override
  State<_FullPostDialog> createState() => _FullPostDialogState();
}

class _FullPostDialogState extends State<_FullPostDialog> {
  FeedPost _resolved() {
    for (final p in widget.feed.placePosts) {
      if (p.id == widget.post.id) return p;
    }
    return widget.post;
  }

  String _loginRedirectPath() {
    final placeId = widget.post.authorPlaceId;
    if (placeId != null && placeId.isNotEmpty) {
      return '/place/$placeId/posts';
    }
    return '/community';
  }

  void _onLike(FeedPost current) {
    final auth = widget.auth;
    if (!auth.isLoggedIn || auth.isGuest) {
      if (!mounted) return;
      context.go('/login?redirect=${Uri.encodeComponent(_loginRedirectPath())}');
      return;
    }
    final token = auth.authToken;
    if (token == null) return;
    unawaited(widget.feed.toggleLike(token, current.id));
  }

  void _onDoubleTapLike(FeedPost current) {
    if (current.likedByMe) return;
    _onLike(current);
  }

  void _onSave(FeedPost current) {
    final auth = widget.auth;
    if (!auth.isLoggedIn || auth.isGuest) {
      if (!mounted) return;
      context.go('/login?redirect=${Uri.encodeComponent(_loginRedirectPath())}');
      return;
    }
    final token = auth.authToken;
    if (token == null) return;
    unawaited(widget.feed.toggleSave(token, current.id));
  }

  void _openComments(BuildContext context, FeedPost current) {
    final auth = widget.auth;
    if (!auth.isLoggedIn || auth.isGuest) {
      context.go('/login?redirect=${Uri.encodeComponent(_loginRedirectPath())}');
      return;
    }
    if (current.commentsDisabled) {
      AppSnackBars.showSuccess(context, AppLocalizations.of(context)!.commentsDisabledForPost);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CommentsSheet(
        post: current,
        authToken: auth.authToken!,
      ),
    );
  }

  Future<void> _showPostOptions(BuildContext context, FeedPost current) async {
    final auth = widget.auth;
    final feed = widget.feed;
    final isOwner = current.authorId != null && auth.userId != null && current.authorId == auth.userId;
    final canManage = canDeleteFeedPost(
      post: current,
      canPost: feed.canPost,
      isAuthor: isOwner,
    );

    if (!canManage) return;

    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
              title: Text(l10n.postDeleteTitle, style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(ctx, 'delete'); AppFeedback.tap(); },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (result == 'delete' && context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.postDeleteTitle),
          content: Text(l10n.deletePostConfirm),
          actions: [
            TextButton(onPressed: () { AppFeedback.tap(); Navigator.pop(ctx, false); }, child: Text(l10n.cancel)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
              onPressed: () { AppFeedback.tap(); Navigator.pop(ctx, true); },
              child: Text(l10n.delete),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        try {
          await FeedService.instance.deletePost(authToken: auth.authToken!, postId: current.id);
          if (context.mounted) {
            AppSnackBars.showSuccess(context, l10n.postDeleted);
            widget.onClose();
            feed.removePostLocally(current.id);
          }
        } catch (e) {
          if (context.mounted) AppSnackBars.showError(context, e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: widget.feed,
      builder: (context, _) {
        final current = _resolved();
        final auth = widget.auth;
        final isOwner = current.authorId != null && auth.userId != null && current.authorId == auth.userId;
        final canManage = canDeleteFeedPost(
          post: current,
          canPost: widget.feed.canPost,
          isAuthor: isOwner,
        );
        final canSeeLikes = !current.hideLikes || isOwner;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: Container(
                decoration: CommunityTokens.cardDecoration.copyWith(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (current.displayImageUrls.isNotEmpty)
                      Flexible(
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: PageView.builder(
                            itemCount: current.displayImageUrls.length,
                            itemBuilder: (_, i) {
                              final url = current.displayImageUrls[i].startsWith('http')
                                  ? current.displayImageUrls[i]
                                  : '${ApiConfig.effectiveBaseUrl}${current.displayImageUrls[i]}';
                              return GestureDetector(
                                onDoubleTap: auth.authToken != null && !auth.isGuest
                                    ? () {
                                        AppFeedback.selection();
                                        _onDoubleTapLike(current);
                                      }
                                    : null,
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  cacheManager: AppImageCacheManager.instance,
                                  memCacheWidth: 1000,
                                  memCacheHeight: 1250,
                                  maxWidthDiskCache: 1000,
                                  maxHeightDiskCache: 1250,
                                  fadeInDuration: Duration.zero,
                                  fadeOutDuration: Duration.zero,
                                  filterQuality: FilterQuality.medium,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _PillStat(
                                      label: l10n.like,
                                      icon: current.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      iconColor: current.likedByMe ? const Color(0xFFE11D48) : AppTheme.textSecondary,
                                      count: canSeeLikes ? current.likeCount : null,
                                      countLabel: canSeeLikes ? null : 'Hidden',
                                      backgroundColor: current.likedByMe ? const Color(0xFFFFF1F2) : AppTheme.surfaceVariant,
                                      accentColor: current.likedByMe ? const Color(0xFFE11D48) : AppTheme.textPrimary,
                                      onTap: () {
                                        AppFeedback.selection();
                                        _onLike(current);
                                      },
                                    ),
                                    _PillStat(
                                      label: l10n.comment,
                                      icon: Icons.chat_bubble_outline_rounded,
                                      iconColor: current.commentsDisabled ? AppTheme.textTertiary : AppTheme.textSecondary,
                                      count: current.commentCount,
                                      isLoading: false,
                                      onTap: current.commentsDisabled
                                          ? () {
                                              AppFeedback.selection();
                                              if (auth.isLoggedIn && !auth.isGuest) {
                                                AppSnackBars.showSuccess(context, 'Comments are turned off for this post');
                                              } else {
                                                context.go('/login?redirect=${Uri.encodeComponent(_loginRedirectPath())}');
                                              }
                                            }
                                          : () {
                                              AppFeedback.selection();
                                              _openComments(context, current);
                                            },
                                    ),
                                    _PillStat(
                                      label: l10n.share,
                                      icon: Icons.share_rounded,
                                      iconColor: AppTheme.primaryColor,
                                      count: null,
                                      isLoading: false,
                                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                                      onTap: () {
                                        AppFeedback.selection();
                                        final url = '${ApiConfig.appBaseUrl}/feed/${current.id}';
                                        sharePlainText(
                                          url,
                                          subject: 'Check out this post from Visit Tripoli',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (auth.isLoggedIn && !auth.isGuest)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                    child: Tooltip(
                                    message: l10n.save,
                                    child: IconButton(
                                      onPressed: () {
                                        AppFeedback.selection();
                                        _onSave(current);
                                      },
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppTheme.surfaceVariant,
                                        padding: const EdgeInsets.all(10),
                                      ),
                                      icon: Icon(
                                        current.savedByMe ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                        size: 22,
                                        color: current.savedByMe ? AppTheme.primaryColor : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              if (canManage)
                                IconButton(
                                  onPressed: () {
                                    AppFeedback.tap();
                                    _showPostOptions(context, current);
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppTheme.surfaceVariant,
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  icon: const Icon(Icons.more_horiz_rounded, size: 22, color: AppTheme.textPrimary),
                                ),
                              IconButton(
                                onPressed: widget.onClose,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceVariant,
                                  padding: const EdgeInsets.all(8),
                                ),
                                icon: const Icon(Icons.close_rounded, size: 22, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          if (current.caption != null && current.caption!.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              current.caption!,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Compact pill-style stat used in the place post lightbox (aligned with feed cards).
class _PillStat extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final int? count;
  final String? countLabel;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? accentColor;
  final BoxBorder? border;
  final VoidCallback? onTap;

  const _PillStat({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.count,
    this.countLabel,
    this.isLoading = false,
    this.backgroundColor,
    this.accentColor,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: border,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(icon, size: 22, color: iconColor),
                const SizedBox(width: 8),
                if (count != null)
                  Text(
                    '$count',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: accentColor ?? AppTheme.textPrimary,
                    ),
                  )
                else if (countLabel != null)
                  Text(
                    countLabel!,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: accentColor ?? AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
