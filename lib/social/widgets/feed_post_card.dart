import 'dart:async' show Timer, unawaited;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../cache/app_cache_manager.dart';
import '../community_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../services/feed_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/feed_video_autoplay_controller.dart';
import '../../widgets/reel_video.dart';

String _placeInitial(FeedPost post) {
  final name = post.authorPlaceName ?? post.authorName;
  if (name != null && name.isNotEmpty) return name[0].toUpperCase();
  return '?';
}

/// Returns a human-friendly relative time string e.g. "2h ago", "Just now".
String _relativeTime(String rawDate) {
  try {
    final dt = DateTime.parse(rawDate).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  } catch (_) {
    return rawDate;
  }
}

class _PlaceAvatarFallback extends StatelessWidget {
  final String initial;
  final bool usePlaceIcon;

  const _PlaceAvatarFallback({required this.initial, this.usePlaceIcon = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.25),
            AppTheme.primaryColor.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: usePlaceIcon
            ? const Icon(Icons.store_rounded, size: 24, color: AppTheme.primaryColor)
            : Text(
                initial,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
      ),
    );
  }
}


class FeedPostCard extends StatelessWidget {
  final FeedPost post;
  final FeedVideoAutoplayController feedVideoAutoplay;
  final String? authToken;
  final bool isOwner;
  final bool canPost;
  final Future<bool> Function() onLike;
  final Future<bool> Function() onSave;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final void Function(String url) onImageTap;
  final VoidCallback onShowOptions;

  const FeedPostCard({super.key, 
    required this.post,
    required this.feedVideoAutoplay,
    required this.authToken,
    required this.isOwner,
    required this.canPost,
    required this.onLike,
    required this.onSave,
    required this.onShare,
    required this.onComment,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
    required this.onImageTap,
    required this.onShowOptions,
  });

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final l10n = AppLocalizations.of(context)!;
    final hasCreativeMeta = post.customLocation != null ||
        post.soundName != null ||
        post.taggedPeople.isNotEmpty ||
        post.stickerLabel != null;

    return Container(
      margin: CommunityTokens.cardMargin,
      decoration: CommunityTokens.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 4, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: post.authorPlaceId != null
                      ? () {
                          AppFeedback.tap();
                          context.push('/place/${post.authorPlaceId}/posts');
                        }
                      : null,
                  child: ClipOval(
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: post.authorPlaceImage != null &&
                              post.authorPlaceImage!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: post.authorPlaceImage!,
                              fit: BoxFit.cover,
                              cacheManager: AppImageCacheManager.instance,
                              memCacheWidth: 88,
                              memCacheHeight: 88,
                              maxWidthDiskCache: 88,
                              maxHeightDiskCache: 88,
                              fadeInDuration: const Duration(milliseconds: 120),
                              placeholder: (_, __) => _PlaceAvatarFallback(initial: _placeInitial(post)),
                              errorWidget: (_, __, ___) =>
                                  _PlaceAvatarFallback(initial: _placeInitial(post)),
                            )
                          : _PlaceAvatarFallback(initial: _placeInitial(post), usePlaceIcon: true),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: post.authorPlaceId != null
                            ? () {
                                AppFeedback.tap();
                                context.push('/place/${post.authorPlaceId}/posts');
                              }
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                post.authorPlaceName ?? post.authorName ?? 'Place',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post.authorRole == 'business_owner' ||
                                post.authorRole == 'discoverer') ...[
                              const SizedBox(width: 4),
                              const VerifiedBadge(size: 15),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _relativeTime(post.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textTertiary,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isOwner || (authToken != null && !isOwner))
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded, color: AppTheme.textSecondary, size: 24),
                    onPressed: () {
                      AppFeedback.tap();
                      onShowOptions();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
              ],
            ),
          ),
          _MediaSection(
            post: post,
            feedVideoAutoplay: feedVideoAutoplay,
            width: mediaWidth,
            onDoubleTap: authToken != null ? () {
              AppFeedback.selection();
              onLike();
            } : null,
            onTap: () {
              AppFeedback.tap();
              onImageTap(post.displayImageUrls.isNotEmpty ? post.displayImageUrls.first : (post.videoUrl ?? ''));
            },
            onVideoTap: () {
              AppFeedback.tap();
              context.push(
                Uri(
                  path: '/community/reels',
                  queryParameters: <String, String>{'postId': post.id},
                ).toString(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
                  children: [
                    _PillActionButton(
                      label: l10n.like,
                      icon: post.likedByMe
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: post.likedByMe
                          ? const Color(0xFFE11D48)
                          : AppTheme.textSecondary,
                      count: (!post.hideLikes || isOwner) ? post.likeCount : null,
                      onTap: authToken == null
                          ? () => context.go(
                                '/login?redirect=${Uri.encodeComponent('/community')}',
                              )
                          : () {
                              AppFeedback.selection();
                              unawaited(onLike());
                            },
                    ),
                    const SizedBox(width: 18),
                    _PillActionButton(
                      label: l10n.comment,
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: AppTheme.textSecondary,
                      count: post.commentCount,
                      onTap: post.commentsDisabled
                          ? () {
                              AppFeedback.selection();
                              if (authToken != null) {
                                AppSnackBars.showSuccess(
                                  context,
                                  l10n.commentsDisabledForPost,
                                );
                              } else {
                                context.go(
                                  '/login?redirect=${Uri.encodeComponent('/community')}',
                                );
                              }
                            }
                          : () {
                              AppFeedback.selection();
                              onComment();
                            },
                    ),
                    const SizedBox(width: 18),
                    _PillActionButton(
                      label: l10n.share,
                      icon: Icons.share_rounded,
                      iconColor: AppTheme.textSecondary,
                      onTap: () {
                        AppFeedback.selection();
                        onShare();
                      },
                    ),
                    const Spacer(),
                    if (authToken != null)
                      _PillActionButton(
                        label: l10n.save,
                        icon: post.savedByMe
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        iconColor: post.savedByMe ? AppTheme.primaryColor : AppTheme.textSecondary,
                        onTap: () {
                          AppFeedback.selection();
                          unawaited(onSave());
                        },
                      ),
                  ],
                ),
          ),
          if ((post.caption != null && post.caption!.isNotEmpty) || hasCreativeMeta)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MouseRegion(
                      cursor: post.authorPlaceId != null
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: post.authorPlaceId != null
                            ? () {
                                AppFeedback.tap();
                                context.push('/place/${post.authorPlaceId}/posts');
                              }
                            : null,
                        child: Text(
                          post.authorPlaceName ?? post.authorName ?? 'Place',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (hasCreativeMeta)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (post.customLocation != null &&
                                post.customLocation!.isNotEmpty)
                              _MetaPill(
                                icon: Icons.location_on_outlined,
                                label: post.customLocation!,
                              ),
                            if (post.soundName != null &&
                                post.soundName!.isNotEmpty)
                              _MetaPill(
                                icon: Icons.music_note_rounded,
                                label: post.soundName!,
                              ),
                            if (post.taggedPeople.isNotEmpty)
                              _MetaPill(
                                icon: Icons.alternate_email_rounded,
                                label:
                                    post.taggedPeople.take(3).join(', '),
                              ),
                          ],
                        ),
                      ),
                    if (post.caption != null && post.caption!.isNotEmpty)
                      _ExpandableCaption(text: post.caption!),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaSection extends StatefulWidget {
  final FeedPost post;
  final FeedVideoAutoplayController feedVideoAutoplay;
  final double width;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTap;
  /// Opens full-screen Reels on this post (For You video tap).
  final VoidCallback? onVideoTap;

  const _MediaSection({
    required this.post,
    required this.feedVideoAutoplay,
    required this.width,
    this.onDoubleTap,
    this.onTap,
    this.onVideoTap,
  });

  @override
  State<_MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<_MediaSection> {
  int _activeImageIndex = 0;

  static const double _aspectRatio = 4 / 3;

  @override
  void didUpdateWidget(covariant _MediaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _activeImageIndex = 0;
      return;
    }
    final maxIndex = widget.post.displayImageUrls.length - 1;
    if (maxIndex >= 0 && _activeImageIndex > maxIndex) {
      _activeImageIndex = maxIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.post.displayImageUrls;
    final hasImage = urls.isNotEmpty;
    final hasVideo =
        widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty;
    final height = widget.width / _aspectRatio;

    if (hasImage) {
      final cacheW = (widget.width * 2).round().clamp(200, 1200);
      final cacheH = (height * 2).round().clamp(150, 900);
      if (urls.length == 1) {
        final image = CachedNetworkImage(
          imageUrl: urls.first,
          width: widget.width,
          height: height,
          fit: BoxFit.cover,
          cacheManager: AppImageCacheManager.instance,
          memCacheWidth: cacheW,
          memCacheHeight: cacheH,
          maxWidthDiskCache: cacheW,
          maxHeightDiskCache: cacheH,
          fadeInDuration: const Duration(milliseconds: 150),
          fadeOutDuration: const Duration(milliseconds: 100),
          placeholder: (_, __) => kIsWeb
              ? Container(
                  width: widget.width,
                  height: height,
                  color: AppTheme.surfaceVariant,
                )
              : Shimmer.fromColors(
                  baseColor: const Color(0xFFE2E8F0),
                  highlightColor: const Color(0xFFF1F5F9),
                  period: const Duration(milliseconds: 900),
                  child: Container(
                    width: widget.width,
                    height: height,
                    color: Colors.white,
                  ),
                ),
          errorWidget: (_, __, ___) => _PlaceholderBox(
            width: widget.width,
            height: height,
            icon: Icons.broken_image_outlined,
          ),
        );
        return GestureDetector(
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          child: image,
        );
      }
      return GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: SizedBox(
          width: widget.width,
          height: height,
          child: Stack(
            children: [
              PageView.builder(
                itemCount: urls.length,
                onPageChanged: (i) {
                  if (!mounted) return;
                  setState(() => _activeImageIndex = i);
                },
                itemBuilder: (_, i) => CachedNetworkImage(
                  imageUrl: urls[i],
                  width: widget.width,
                  height: height,
                  fit: BoxFit.cover,
                  cacheManager: AppImageCacheManager.instance,
                  memCacheWidth: cacheW,
                  memCacheHeight: cacheH,
                  maxWidthDiskCache: cacheW,
                  maxHeightDiskCache: cacheH,
                  fadeInDuration: const Duration(milliseconds: 120),
                  placeholder: (_, __) => Container(
                    width: widget.width,
                    height: height,
                    color: AppTheme.surfaceVariant,
                  ),
                  errorWidget: (_, __, ___) => _PlaceholderBox(
                    width: widget.width,
                    height: height,
                    icon: Icons.broken_image_outlined,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_activeImageIndex + 1}/${urls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    urls.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _activeImageIndex ? 14 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: i == _activeImageIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (hasVideo) {
      return VisibilityDetector(
        key: Key('feed-video-vis-${widget.post.id}'),
        onVisibilityChanged: (info) =>
            widget.feedVideoAutoplay.report(widget.post.id, info),
        child: GestureDetector(
          onTap: widget.onVideoTap ?? widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          child: SizedBox(
            width: widget.width,
            height: height,
            child: ListenableBuilder(
              listenable: widget.feedVideoAutoplay,
              builder: (context, _) {
                return _FeedDeferredInlineVideo(
                  postId: widget.post.id,
                  videoUrl: widget.post.videoUrl ?? '',
                  thumbnailUrl: widget.post.imageUrl,
                  isActive: widget.feedVideoAutoplay.isActive(widget.post.id),
                );
              },
            ),
          ),
        ),
      );
    }

    return _PlaceholderBox(
      width: widget.width,
      height: height,
      icon: Icons.image_not_supported_outlined,
    );
  }
}

/// Avoids creating heavy HTML5 `<video>` platform views until the user scrolls
/// near the post; keeps only one feed video "active" at a time via [FeedVideoAutoplayController].
class _FeedDeferredInlineVideo extends StatefulWidget {
  final String postId;
  final String videoUrl;
  final String? thumbnailUrl;
  final bool isActive;

  const _FeedDeferredInlineVideo({
    required this.postId,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.isActive,
  });

  @override
  State<_FeedDeferredInlineVideo> createState() => _FeedDeferredInlineVideoState();
}

class _FeedDeferredInlineVideoState extends State<_FeedDeferredInlineVideo> {
  bool _playerMounted = false;
  bool _muted = true;
  Timer? _unmountPlayerTimer;

  void _toggleMute() {
    if (mounted) {
      setState(() => _muted = !_muted);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _playerMounted = true;
  }

  @override
  void didUpdateWidget(covariant _FeedDeferredInlineVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive) {
      _unmountPlayerTimer?.cancel();
      if (!_playerMounted) {
        setState(() => _playerMounted = true);
      }
    } else if (_playerMounted) {
      // Tear down the HTML5 <video> platform view shortly after scroll-away so
      // we don't accumulate many decoders/DOM nodes while browsing the feed.
      _unmountPlayerTimer?.cancel();
      _unmountPlayerTimer = Timer(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        if (!widget.isActive) {
          setState(() => _playerMounted = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _unmountPlayerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl.isEmpty) {
      return Container(
        color: const Color(0xFF0D0D0D),
        alignment: Alignment.center,
        child: const Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 40),
      );
    }
    if (!_playerMounted) {
      final mq = MediaQuery.sizeOf(context);
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final tw = (mq.width * dpr).round().clamp(200, 900);
      final th = (mq.width / (4 / 3) * dpr).round().clamp(150, 700);
      return Stack(
        fit: StackFit.expand,
        children: [
          if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.thumbnailUrl!,
              fit: BoxFit.cover,
              cacheManager: AppImageCacheManager.instance,
              memCacheWidth: tw,
              memCacheHeight: th,
              maxWidthDiskCache: tw,
              maxHeightDiskCache: th,
              fadeInDuration: Duration.zero,
            )
          else
            Container(color: const Color(0xFF0D0D0D)),
          Container(color: Colors.black26),
          Center(
            child: Icon(
              Icons.play_circle_outline_rounded,
              size: 52,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: ReelVideo(
        key: ValueKey('reel-video-${widget.postId}'),
        reelId: 'feed-${widget.postId}',
        videoUrl: widget.videoUrl,
        thumbnailUrl: widget.thumbnailUrl,
        isActive: widget.isActive,
        isMuted: _muted,
        onMuteToggled: _toggleMute,
        showMuteButton: true,
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  final double width;
  final double? height;
  final IconData icon;

  const _PlaceholderBox({required this.width, this.height, required this.icon});

  @override
  Widget build(BuildContext context) {
    final h = height ?? width;
    return Container(
      width: width,
      height: h,
      color: const Color(0xFFF1F5F9),
      child: Center(child: Icon(icon, size: 48, color: AppTheme.textTertiary)),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableCaption extends StatefulWidget {
  final String text;

  const _ExpandableCaption({required this.text});

  @override
  State<_ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<_ExpandableCaption> {
  static const int _maxChars = 120;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.text.length > _maxChars;
    final displayText = _expanded || !isLong
        ? widget.text
        : '${widget.text.substring(0, _maxChars).trim()}...';

    return GestureDetector(
      onTap: isLong ? () => setState(() => _expanded = !_expanded) : null,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w400,
          ),
          children: [
            TextSpan(text: displayText),
            if (isLong)
              TextSpan(
                text: _expanded ? ' Show less' : ' Read more',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PillActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final int? count;
  final VoidCallback? onTap;

  const _PillActionButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      child: Icon(
        key: ValueKey(icon.codePoint ^ iconColor.toARGB32()),
        icon,
        size: 22,
        color: iconColor,
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedPop(
            active: icon == Icons.favorite_rounded,
            child: iconWidget,
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: content,
        ),
      ),
    );
  }
}

class _AnimatedPop extends StatefulWidget {
  final Widget child;
  final bool active;
  const _AnimatedPop({required this.child, required this.active});

  @override
  State<_AnimatedPop> createState() => _AnimatedPopState();
}

class _AnimatedPopState extends State<_AnimatedPop> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant _AnimatedPop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF0095F6), // Unified Instagram Blue
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_rounded,
        color: Colors.white,
        size: size * 0.75,
      ),
    );
  }
}
