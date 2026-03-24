import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/feed_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_utils.dart';

/// Admin-only bottom sheet: review discoverable users’ posts (pending moderation).
Future<void> showFeedModerationSheet(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final feed = context.read<FeedProvider>();
  final token = auth.authToken;
  if (token == null || token.isEmpty) return;

  await feed.loadPendingModeration(token);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _FeedModerationSheetContent(
      onRefresh: () => feed.loadPendingModeration(token),
    ),
  );
}

class _FeedModerationSheetContent extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _FeedModerationSheetContent({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feed = context.watch<FeedProvider>();
    final auth = context.read<AuthProvider>();
    final token = auth.authToken!;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.45,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.feedModerationTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.feedModerationSubtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary.withValues(alpha: 0.95),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await onRefresh();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: l10n.retry,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (feed.loadingPendingModeration)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (feed.pendingModerationError != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        feed.pendingModerationError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ),
                )
              else if (feed.pendingModerationPosts.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.feedModerationEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    itemCount: feed.pendingModerationPosts.length,
                    itemBuilder: (context, index) {
                      final post = feed.pendingModerationPosts[index];
                      return _ModerationPostCard(
                        post: post,
                        onApprove: () async {
                          final ok = await feed.moderateFeedPost(
                            token,
                            post.id,
                            'approved',
                          );
                          if (!context.mounted) return;
                          if (ok) {
                            AppSnackBars.showSuccess(
                              context,
                              l10n.feedModerationApproved,
                            );
                          } else {
                            AppSnackBars.showError(
                              context,
                              l10n.feedModerationFailed,
                            );
                          }
                        },
                        onReject: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text(l10n.feedModerationRejectConfirmTitle),
                              content: Text(l10n.feedModerationRejectConfirmBody),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: Text(l10n.cancel),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: Text(l10n.feedModerationReject),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true || !context.mounted) return;
                          final ok = await feed.moderateFeedPost(
                            token,
                            post.id,
                            'rejected',
                          );
                          if (!context.mounted) return;
                          if (ok) {
                            AppSnackBars.showSuccess(
                              context,
                              l10n.feedModerationRejected,
                            );
                          } else {
                            AppSnackBars.showError(
                              context,
                              l10n.feedModerationFailed,
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ModerationPostCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ModerationPostCard({
    required this.post,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final thumbUrl = post.imageUrl;
    final hasImage = thumbUrl != null && thumbUrl.isNotEmpty;
    final isVideo = post.type == 'video';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.85)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: hasImage
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: thumbUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppTheme.surfaceVariant,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppTheme.surfaceVariant,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                              if (isVideo)
                                Container(
                                  color: Colors.black26,
                                  child: const Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                            ],
                          )
                        : Container(
                            color: AppTheme.surfaceVariant,
                            alignment: Alignment.center,
                            child: Icon(
                              isVideo
                                  ? Icons.videocam_outlined
                                  : Icons.article_outlined,
                              color: AppTheme.textTertiary.withValues(alpha: 0.7),
                              size: 32,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.feedModerationPlace}: ${post.authorPlaceName ?? '—'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.feedModerationType}: ${post.type} · ${post.createdAt}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textTertiary.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (post.caption != null && post.caption!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                post.caption!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(l10n.feedModerationReject),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(l10n.feedModerationApprove),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
