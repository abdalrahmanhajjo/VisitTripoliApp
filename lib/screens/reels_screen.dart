import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cache/app_cache_manager.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../services/feed_service.dart';
import '../utils/app_share.dart';
import '../utils/feedback_utils.dart';
import '../utils/feed_delete_permissions.dart';
import '../utils/snackbar_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/reel_video.dart';

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────

class ReelsScreen extends StatefulWidget {
  final String? initialPostId;
  const ReelsScreen({super.key, this.initialPostId});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  static const String _prefReelsMuted = 'reels_prefer_muted';

  PageController? _pageController;
  bool _initialLoadDone = false;
  int _currentIndex = 0;
  bool _pageControllerScheduleRequested = false;
  /// Default: sound on. User can tap the speaker to mute; choice is remembered.
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _loadMutePreference();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  Future<void> _loadMutePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isMuted = prefs.getBool(_prefReelsMuted) ?? false;
    });
  }

  Future<void> _persistMutePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefReelsMuted, _isMuted);
  }

  void _ensurePageController(List<FeedPost> videos) {
    if (_pageController != null || videos.isEmpty) return;
    var initial = 0;
    final id = widget.initialPostId;
    if (id != null && id.isNotEmpty) {
      final i = videos.indexWhere((p) => p.id == id);
      if (i >= 0) initial = i;
    }
    _pageController = PageController(initialPage: initial);
    _currentIndex = initial;
  }

  void _schedulePageControllerIfNeeded(List<FeedPost> videos) {
    if (_pageController != null || videos.isEmpty || _pageControllerScheduleRequested) return;
    _pageControllerScheduleRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final v = context.read<FeedProvider>().reels;
      if (v.isEmpty) {
        _pageControllerScheduleRequested = false;
        return;
      }
      setState(() => _ensurePageController(v));
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadIfNeeded() async {
    final feed = context.read<FeedProvider>();
    final auth = context.read<AuthProvider>();
    final token = auth.authToken;
    final futures = <Future<void>>[];
    if (token != null) futures.add(feed.loadCanPost(token));
    if (feed.reels.isEmpty && !feed.loadingReels) {
      futures.add(feed.loadReels(authToken: token, refresh: true));
    }
    if (futures.isNotEmpty) await Future.wait(futures);
    if (mounted) setState(() => _initialLoadDone = true);
  }

  Widget _buildReelsPageView(FeedProvider feed, List<FeedPost> videos, AuthProvider auth) {
    _schedulePageControllerIfNeeded(videos);
    final pc = _pageController;
    if (pc == null) {
      return const Center(
        child: SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white70)),
      );
    }
    return PageView.builder(
      controller: pc,
      scrollDirection: Axis.vertical,
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final post = videos[index];
        return _ReelPage(
          key: ValueKey(post.id),
          post: post,
          authToken: auth.authToken,
          isActive: index == _currentIndex,
          onLike: () {
            if (auth.authToken == null) {
              context.go('/login?redirect=${Uri.encodeComponent('/community/reels')}');
              return;
            }
            feed.toggleLike(auth.authToken!, post.id);
          },
          onComment: () => _openComments(post),
          onShare: () {
            final url = '${ApiConfig.appBaseUrl}/feed/${post.id}';
            sharePlainText(url, subject: post.authorPlaceName ?? post.authorName);
          },
          isMuted: _isMuted,
          onMuteToggled: () {
            setState(() => _isMuted = !_isMuted);
            _persistMutePreference();
          },
          onShowOptions: () => _showPostOptionsMenu(post),
        );
      },
      onPageChanged: (i) {
        setState(() => _currentIndex = i);
        if (i >= videos.length - 3 && feed.hasMoreReels) {
          feed.loadMoreReels(authToken: auth.authToken);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedProvider>();
    final auth = context.watch<AuthProvider>();
    final videos = feed.reels;
    final isLoading = !_initialLoadDone || (feed.loadingReels && feed.reels.isEmpty);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            AppFeedback.selection();
            context.pop();
          },
        ),
        title: const Text(
          'Reels',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white70)))
          : videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off_rounded, size: 72, color: Colors.white.withValues(alpha: 0.4)),
                      const SizedBox(height: 20),
                      const Text('No reels yet', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Video posts will appear here', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15)),
                      const SizedBox(height: 28),
                      OutlinedButton.icon(
                        onPressed: () {
                          AppFeedback.selection();
                          context.pop();
                        },
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        label: const Text('Back to feed', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)),
                      ),
                    ],
                  ),
                )
              : _buildReelsPageView(feed, videos, auth),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Future<void> _openComments(FeedPost post) async {
    AppFeedback.selection();
    final auth = context.read<AuthProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReelsCommentsSheet(
        post: post,
        authToken: auth.authToken ?? '',
        canComment: auth.isLoggedIn && !auth.isGuest,
      ),
    );
  }

  Future<void> _showPostOptionsMenu(FeedPost post) async {
    AppFeedback.selection();
    final auth = context.read<AuthProvider>();
    final feed = context.read<FeedProvider>();
    final isAuthor =
        post.authorId != null && auth.userId != null && post.authorId == auth.userId;
    final canDelete = canDeleteFeedPost(
      post: post,
      canPost: feed.canPost,
      isAuthor: isAuthor,
    );

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48)),
                title: const Text('Delete Reel', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w600)),
                onTap: () {
                  AppFeedback.selection();
                  Navigator.pop(ctx, 'delete');
                },
              ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Colors.white70),
              title: const Text('Share', style: TextStyle(color: Colors.white70)),
              onTap: () {
                AppFeedback.selection();
                Navigator.pop(ctx, 'share');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (result == 'delete' && mounted) {
      await _deleteReel(post.id);
    } else if (result == 'share' && mounted) {
      final url = '${ApiConfig.appBaseUrl}/feed/${post.id}';
      sharePlainText(url, subject: post.authorPlaceName ?? post.authorName);
    }
  }

  Future<void> _deleteReel(String postId) async {
    AppFeedback.selection();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Reel', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this reel? This cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () {
            AppFeedback.selection();
            Navigator.pop(ctx, false);
          }, child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
            onPressed: () {
              AppFeedback.selection();
              Navigator.pop(ctx, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final feed = context.read<FeedProvider>();
    try {
      await FeedService.instance.deletePost(authToken: auth.authToken!, postId: postId);
      if (!mounted) return;
      AppSnackBars.showSuccess(context, 'Reel deleted');
      feed.removePostLocally(postId);
    } catch (e) {
      if (!mounted) return;
      AppSnackBars.showError(context, e.toString());
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Reel Page (full-screen)
// ─────────────────────────────────────────────────────────────

class _ReelPage extends StatefulWidget {
  final FeedPost post;
  final String? authToken;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final bool isActive;
  final bool isMuted;
  final VoidCallback onMuteToggled;
  final VoidCallback onShowOptions;

  const _ReelPage({
    super.key,
    required this.post,
    this.authToken,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.isActive,
    required this.isMuted,
    required this.onMuteToggled,
    required this.onShowOptions,
  });

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> with TickerProviderStateMixin {
  bool _captionExpanded = false;

  // Double-tap heart burst animation
  bool _showHeart = false;
  late final AnimationController _heartCtrl;
  late final Animation<double> _heartScale;
  late final Animation<double> _heartOpacity;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut));
    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartCtrl);
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    AppFeedback.success(context, 'Post liked'); // Double tap burst
    widget.onLike();
    setState(() => _showHeart = true);
    _heartCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final placeName = post.authorPlaceName ?? post.authorName ?? 'Place';
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onDoubleTap: widget.authToken != null ? _onDoubleTap : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video ──
          ReelVideo(
            reelId: post.id,
            videoUrl: post.videoUrl ?? '',
            thumbnailUrl: post.imageUrl,
            isActive: widget.isActive,
            isMuted: widget.isMuted,
            onMuteToggled: widget.onMuteToggled,
          ),

          // ── Strong bottom gradient (behind all overlays) ──
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              height: 320,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Color(0x00000000)],
                ),
              ),
            ),
          ),

          // ── Left info overlay: author + caption ──
          Positioned(
            left: 16,
            right: 80,
            bottom: safeBottom + 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Author row
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: post.authorPlaceId != null
                      ? () {
                          HapticFeedback.selectionClick();
                          context.push('/place/${post.authorPlaceId}/posts');
                        }
                      : null,
                  child: Row(
                    children: [
                      // Avatar
                      ClipOval(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: post.authorPlaceImage != null && post.authorPlaceImage!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: post.authorPlaceImage!,
                                  fit: BoxFit.cover,
                                  cacheManager: AppImageCacheManager.instance,
                                  memCacheWidth: 80,
                                  memCacheHeight: 80,
                                  maxWidthDiskCache: 80,
                                  maxHeightDiskCache: 80,
                                  fadeInDuration: const Duration(milliseconds: 100),
                                  errorWidget: (_, __, ___) => _buildAvatarFallback(placeName),
                                )
                              : _buildAvatarFallback(placeName),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          placeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Caption
                if (post.caption != null && post.caption!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      AppFeedback.selection();
                      setState(() => _captionExpanded = !_captionExpanded);
                    },
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: _captionExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      firstChild: Text(
                        post.caption!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.45,
                          shadows: const [Shadow(blurRadius: 6, color: Colors.black45)],
                        ),
                      ),
                      secondChild: Text(
                        post.caption!.trim(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.45,
                          shadows: const [Shadow(blurRadius: 6, color: Colors.black45)],
                        ),
                      ),
                    ),
                  ),
                  if (!_captionExpanded && (post.caption?.length ?? 0) > 80)
                    GestureDetector(
                      onTap: () {
                        AppFeedback.selection();
                        setState(() => _captionExpanded = true);
                      },
                      child: const Text(
                        'more',
                        style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ],
            ),
          ),

          // ── Right-side action buttons ──
          Positioned(
            right: 12,
            bottom: safeBottom + 80,
            child: Column(
              children: [
                _ReelActionButton(
                  icon: post.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: _fmt(post.likeCount),
                  iconColor: post.likedByMe ? const Color(0xFFE11D48) : Colors.white,
                  onTap: widget.authToken != null
                      ? () {
                          AppFeedback.selection();
                          widget.onLike();
                        }
                      : () {
                          AppFeedback.selection();
                          context.go('/login?redirect=${Uri.encodeComponent('/community/reels')}');
                        },
                ),
                const SizedBox(height: 22),
                _ReelActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: _fmt(post.commentCount),
                  onTap: widget.onComment,
                ),
                const SizedBox(height: 22),
                _ReelActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: () {
                    AppFeedback.selection();
                    widget.onShare();
                  },
                ),
                const SizedBox(height: 22),
                _ReelActionButton(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  onTap: () {
                    AppFeedback.tap();
                    widget.onShowOptions();
                  },
                ),
              ],
            ),
          ),

          // ── Double-tap heart burst ──
          if (_showHeart)
            Center(
              child: AnimatedBuilder(
                animation: _heartCtrl,
                builder: (_, __) => Opacity(
                  opacity: _heartOpacity.value,
                  child: Transform.scale(
                    scale: _heartScale.value,
                    child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 100,
                        shadows: [Shadow(blurRadius: 30, color: Colors.black87)]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: Colors.white24,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ─────────────────────────────────────────────────────────────
// Right-side action button (TikTok style)
// ─────────────────────────────────────────────────────────────

class _ReelActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ReelActionButton({
    required this.icon,
    required this.label,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = iconColor ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12, width: 1),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Icon(icon, color: c, size: 28),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Comments Sheet (dark theme, TikTok style)
// ─────────────────────────────────────────────────────────────

class _ReelsCommentsSheet extends StatefulWidget {
  final FeedPost post;
  final String authToken;
  final bool canComment;

  const _ReelsCommentsSheet({
    required this.post,
    required this.authToken,
    required this.canComment,
  });

  @override
  State<_ReelsCommentsSheet> createState() => _ReelsCommentsSheetState();
}

class _ReelsCommentsSheetState extends State<_ReelsCommentsSheet> {
  List<FeedComment> _comments = [];
  bool _loading = true;
  String? _error;
  final _controller = TextEditingController();
  FeedComment? _replyTo;
  bool _submitting = false;
  String? _likingCommentId;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() { _loading = true; _error = null; });
    try {
      final page = await FeedService.instance.getComments(
        postId: widget.post.id,
        authToken: widget.authToken.isEmpty ? null : widget.authToken,
        order: 'desc',
        limit: 60,
        offset: 0,
      );
      if (mounted) {
        setState(() => _comments = page.comments.reversed.toList());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitComment() async {
    if (_submitting) return;
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    AppFeedback.tap();
    setState(() => _submitting = true);
    _controller.clear();
    try {
      await FeedService.instance.addComment(
        authToken: widget.authToken,
        postId: widget.post.id,
        body: body,
        parentCommentId: _replyTo?.id,
      );
      if (!mounted) return;
      setState(() => _replyTo = null);
      context.read<FeedProvider>().incrementCommentCount(widget.post.id);
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      AppSnackBars.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _toggleCommentLike(FeedComment c) async {
    if (_likingCommentId == c.id) return;
    AppFeedback.selection();
    setState(() => _likingCommentId = c.id);
    try {
      await FeedService.instance.toggleCommentLike(
        authToken: widget.authToken,
        commentId: c.id,
      );
      await _loadComments();
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _likingCommentId = null);
    }
  }

  Future<void> _deleteComment(FeedComment c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete comment', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () {
            AppFeedback.selection();
            Navigator.pop(ctx, false);
          }, child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
            onPressed: () {
              AppFeedback.selection();
              Navigator.pop(ctx, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      AppFeedback.tap();
      await FeedService.instance.deleteComment(authToken: widget.authToken, commentId: c.id);
      if (!mounted) return;
      AppSnackBars.showSuccess(context, 'Comment deleted');
      context.read<FeedProvider>().decrementCommentCount(widget.post.id);
      await _loadComments();
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, e.toString());
    }
  }

  Future<void> _editComment(FeedComment c) async {
    final editCtrl = TextEditingController(text: c.body);
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit comment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 14),
              TextField(
                controller: editCtrl,
                autofocus: true,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF2C2C2E),
                  border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(14))),
                  hintText: 'Edit your comment...',
                  hintStyle: TextStyle(color: Colors.white38),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      AppFeedback.selection();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 8),
                  StatefulBuilder(builder: (ctx2, setSt) => FilledButton(
                    onPressed: saving ? null : () async {
                      final newBody = editCtrl.text.trim();
                      if (newBody.isEmpty) return;
                      setSt(() => saving = true);
                      try {
                        await FeedService.instance.editComment(
                          authToken: widget.authToken,
                          commentId: c.id,
                          body: newBody,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadComments();
                      } catch (e) {
                        if (mounted) AppSnackBars.showError(context, e.toString());
                      } finally {
                        if (ctx2.mounted) setSt(() => saving = false);
                      }
                    },
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    editCtrl.dispose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 12;

    final sortedComments = List<FeedComment>.from(_comments)
      ..sort((a, b) {
        final lc = b.likeCount.compareTo(a.likeCount);
        return lc != 0 ? lc : a.createdAt.compareTo(b.createdAt);
      });

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  children: [
                    const Text('Comments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${widget.post.commentCount}',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () {
                        AppFeedback.selection();
                        Navigator.pop(context);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),

              // Comment list
              Expanded(
                child: _loading
                    ? const Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                        ),
                      )
                    : _error != null
                        ? const Center(child: Text('Could not load comments', style: TextStyle(color: Colors.white38)))
                        : sortedComments.isEmpty
                            ? const Center(child: Text('No comments yet. Be the first!', style: TextStyle(color: Colors.white38, fontSize: 15)))
                            : ListView.builder(
                                controller: scrollCtrl,
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                itemCount: sortedComments.length,
                                itemBuilder: (_, i) {
                                  final c = sortedComments[i];
                                  final isOwner = c.userId != null && auth.userId != null && c.userId == auth.userId;
                                  final isPostOwner = widget.post.authorId != null && auth.userId != null && widget.post.authorId == auth.userId;
                                  final canManage = isOwner || isPostOwner;
                                  final isReply = c.parentCommentId != null && c.parentCommentId!.isNotEmpty;
                                  return _CommentTile(
                                    comment: c,
                                    isReply: isReply,
                                    canManage: canManage,
                                    isLiking: _likingCommentId == c.id,
                                    canInteract: widget.canComment,
                                    onLike: () => _toggleCommentLike(c),
                                    onReply: () {
                                      AppFeedback.selection();
                                      setState(() {
                                        _replyTo = c;
                                        _controller.text = '@${c.authorName} ';
                                        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
                                      });
                                    },
                                    onEdit: () {
                                      AppFeedback.tap();
                                      _editComment(c);
                                    },
                                    onDelete: () {
                                      AppFeedback.tap();
                                      _deleteComment(c);
                                    },
                                  );
                                },
                              ),
              ),

              // Input
              Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white12)),
                  color: Color(0xFF1C1C1E),
                ),
                child: widget.post.commentsDisabled
                    ? const Center(
                        child: Text('Comments are turned off', style: TextStyle(color: Colors.white38, fontSize: 14)),
                      )
                    : !widget.canComment
                        ? Center(
                            child: TextButton(
                              onPressed: () {
                                AppFeedback.selection();
                                context.go('/login?redirect=${Uri.encodeComponent('/community/reels')}');
                              },
                              child: const Text('Log in to comment', style: TextStyle(color: Colors.white54)),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_replyTo != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Replying to ${_replyTo!.authorName}',
                                          style: const TextStyle(color: Colors.white60, fontSize: 13),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                        AppFeedback.selection();
                                        setState(() => _replyTo = null);
                                      },
                                        child: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      style: const TextStyle(color: Colors.white, fontSize: 15),
                                      decoration: InputDecoration(
                                        hintText: _replyTo != null ? 'Write a reply...' : 'Add a comment...',
                                        hintStyle: const TextStyle(color: Colors.white38),
                                        filled: true,
                                        fillColor: const Color(0xFF2C2C2E),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                      ),
                                      maxLines: 1,
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (_) => _submitComment(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: _submitting ? null : _submitComment,
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: _submitting
                                          ? const SizedBox.expand(
                                              child: Padding(
                                                padding: EdgeInsets.all(12),
                                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Comment tile (dark)
// ─────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final FeedComment comment;
  final bool isReply;
  final bool canManage;
  final bool isLiking;
  final bool canInteract;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.isReply,
    required this.canManage,
    required this.isLiking,
    required this.canInteract,
    required this.onLike,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  String _relativeTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${(diff.inDays / 7).floor()}w';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = comment;
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 48 : 0, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF3A3A3C),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(c.authorName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(_relativeTime(c.createdAt),
                        style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    if (canManage) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: onEdit,
                        child: const Icon(Icons.edit_outlined, color: Colors.white38, size: 16),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48), size: 16),
                      ),
                    ],
                  ],
                ),
                if (isReply && c.parentAuthorName != null)
                  Text('↩ @${c.parentAuthorName}',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(c.body, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (canInteract)
                      GestureDetector(
                        onTap: onReply,
                        child: const Text('Reply',
                            style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    const Spacer(),
                    GestureDetector(
                      onTap: canInteract ? onLike : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          isLiking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white54),
                                )
                              : _AnimatedPop(
                                  active: c.likedByMe,
                                  child: Icon(
                                    c.likedByMe
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 16,
                                    color: c.likedByMe
                                        ? const Color(0xFFE11D48)
                                        : Colors.white38,
                                  ),
                                ),
                          if (c.likeCount > 0) ...[
                            const SizedBox(width: 4),
                            Text('${c.likeCount}',
                                style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
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

class _AnimatedPop extends StatefulWidget {
  final bool active;
  final Widget child;
  const _AnimatedPop({required this.active, required this.child});

  @override
  State<_AnimatedPop> createState() => _AnimatedPopState();
}

class _AnimatedPopState extends State<_AnimatedPop> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_AnimatedPop old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale, child: widget.child);
}
