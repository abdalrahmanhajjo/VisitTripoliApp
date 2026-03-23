import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/feed_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/feedback_utils.dart';
import '../../providers/feed_provider.dart';

class CommentsSheet extends StatefulWidget {
  final FeedPost post;
  final String authToken;
  /// Optional; use when the parent needs a side effect. Count updates are applied in [FeedProvider] automatically.
  final VoidCallback? onCommentAdded;

  const CommentsSheet({super.key, 
    required this.post,
    required this.authToken,
    this.onCommentAdded,
  });

  @override
  State<CommentsSheet> createState() => CommentsSheetState();
}

class CommentsSheetState extends State<CommentsSheet> {
  static const int _pageSize = 40;

  List<FeedComment> _comments = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMoreOlder = true;
  int _apiOffset = 0;

  final _controller = TextEditingController();
  FeedComment? _replyTo;
  bool _submitting = false;
  String? _likingCommentId;

  Future<bool> _handleMaybeUnauthorized(dynamic e) async {
    if (e is! FeedException) return false;
    if (e.statusCode != 401) return false;

    final auth = context.read<AuthProvider>();
    await auth.logout();

    if (!mounted) return true;
    context.go('/login?redirect=${Uri.encodeComponent('/community')}');
    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadComments(reset: true);
  }

  Future<void> _loadComments({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _apiOffset = 0;
        _hasMoreOlder = true;
      });
    }
    try {
      final page = await FeedService.instance.getComments(
        postId: widget.post.id,
        authToken: widget.authToken,
        limit: _pageSize,
        offset: 0,
        order: 'desc',
      );
      final batchAsc = page.comments.reversed.toList();
      if (!mounted) return;
      setState(() {
        _comments = batchAsc;
        _apiOffset = page.comments.length;
        _hasMoreOlder = page.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingMore || !_hasMoreOlder || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final page = await FeedService.instance.getComments(
        postId: widget.post.id,
        authToken: widget.authToken,
        limit: _pageSize,
        offset: _apiOffset,
        order: 'desc',
      );
      final batchAsc = page.comments.reversed.toList();
      if (!mounted) return;
      setState(() {
        _comments = [...batchAsc, ..._comments];
        _apiOffset += page.comments.length;
        _hasMoreOlder = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _submitComment() async {
    if (_submitting) return;
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    setState(() => _submitting = true);
    AppFeedback.tap();
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
      widget.onCommentAdded?.call();
      await _loadComments();
    } catch (e) {
      final unauthorized = await _handleMaybeUnauthorized(e);
      if (!unauthorized && mounted) {
        AppSnackBars.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(FeedComment c) async {
    if (_loading) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    AppFeedback.tap();

    try {
      await FeedService.instance.deleteComment(
        authToken: widget.authToken,
        commentId: c.id,
      );
      if (!mounted) return;
      AppSnackBars.showSuccess(context, 'Comment deleted');
      if (context.mounted) {
        context.read<FeedProvider>().decrementCommentCount(widget.post.id);
      }
      widget.onCommentAdded?.call();
      await _loadComments();
    } catch (e) {
      final unauthorized = await _handleMaybeUnauthorized(e);
      if (!unauthorized && mounted) {
        AppSnackBars.showError(context, e.toString());
      }
    }
  }

  Future<void> _editComment(FeedComment c) async {
    final editController = TextEditingController(text: c.body);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit comment'),
        content: TextField(
          controller: editController,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != true) return;
    AppFeedback.tap();
    if (!mounted) return;

    final newBody = editController.text.trim();
    if (newBody.isEmpty) {
      AppSnackBars.showError(context, 'Comment cannot be empty');
      return;
    }

    try {
      await FeedService.instance.editComment(
        authToken: widget.authToken,
        commentId: c.id,
        body: newBody,
      );
      if (!mounted) return;
      AppSnackBars.showSuccess(context, 'Comment updated');
      widget.onCommentAdded?.call();
      await _loadComments();
    } catch (e) {
      final unauthorized = await _handleMaybeUnauthorized(e);
      if (!unauthorized && mounted) {
        AppSnackBars.showError(context, e.toString());
      }
    }
  }

  void _startReply(FeedComment c) {
    setState(() {
      _replyTo = c;
      final mention = '@${c.authorName} ';
      _controller.text = mention;
      AppFeedback.tap();
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final feed = context.watch<FeedProvider>();
    final post = feed.postById(widget.post.id) ?? widget.post;
    final isPostOwner = post.authorId != null && auth.userId != null && post.authorId == auth.userId;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Text(
                      l10n.comment,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${post.commentCount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? _CommentsLoadingSkeleton()
                    : _comments.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 48,
                                    color: AppTheme.textTertiary.withValues(alpha: 0.85),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No comments yet',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Be the first to comment.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.textSecondary,
                                          height: 1.45,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n.metrics.pixels < 72 &&
                              n is ScrollUpdateNotification &&
                              _hasMoreOlder &&
                              !_loadingMore &&
                              !_loading) {
                            _loadOlder();
                          }
                          return false;
                        },
                        child: ListView.builder(
                        controller: scrollController,
                        cacheExtent: 150,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _comments.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (_loadingMore && i == 0) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          final ci = _loadingMore ? i - 1 : i;
                          final c = _comments[ci];
                          final canManage = isPostOwner || (c.userId != null && auth.userId != null && c.userId == auth.userId);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: EdgeInsets.only(left: c.parentCommentId != null && c.parentCommentId!.isNotEmpty ? 16 : 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.authorName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (c.parentCommentId != null && c.parentCommentId!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(999),
                                                      border: Border.all(
                                                        color: AppTheme.primaryColor.withValues(alpha: 0.35),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Reply',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 12,
                                                        color: AppTheme.primaryColor,
                                                        height: 1.0,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Replying to ${c.parentAuthorName ?? "comment"}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: AppTheme.textSecondary,
                                                            fontWeight: FontWeight.w800,
                                                            fontSize: 12,
                                                          ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            c.body,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              height: 1.4,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        AppFeedback.selection();
                                        _startReply(c);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                        child: Text(
                                          'Reply',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    InkWell(
                                      onTap: _likingCommentId == c.id
                                          ? null
                                          : () async {
                                              AppFeedback.selection();
                                              setState(() => _likingCommentId = c.id);
                                              try {
                                                await FeedService.instance.toggleCommentLike(
                                                  authToken: widget.authToken,
                                                  commentId: c.id,
                                                );
                                                await _loadComments();
                                              } catch (e) {
                                                final unauthorized = await _handleMaybeUnauthorized(e);
                                                if (!unauthorized && context.mounted) {
                                                  AppSnackBars.showError(context, e.toString());
                                                }
                                              } finally {
                                                if (mounted) setState(() => _likingCommentId = null);
                                              }
                                            },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _likingCommentId == c.id
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : Icon(
                                                    c.likedByMe
                                                        ? Icons.favorite_rounded
                                                        : Icons.favorite_border_rounded,
                                                    size: 18,
                                                    color: c.likedByMe
                                                        ? const Color(0xFFE11D48)
                                                        : AppTheme.textSecondary,
                                                  ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${c.likeCount}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (canManage) ...[
                                      const SizedBox(width: 12),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        icon: const Icon(Icons.edit_outlined),
                                        color: AppTheme.textSecondary,
                                        onPressed: () {
                                          AppFeedback.tap();
                                          _editComment(c);
                                        },
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        icon: const Icon(Icons.delete_outline_rounded),
                                        color: AppTheme.errorColor,
                                        onPressed: () {
                                          AppFeedback.tap();
                                          _deleteComment(c);
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ));
                        },
                      ),
                    ),
              ),
              if (post.commentsDisabled)
                Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppTheme.borderColor)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppTheme.textTertiary),
                      SizedBox(width: 10),
                      Text(
                        'Comments are turned off for this post',
                        style: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppTheme.borderColor)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_replyTo != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Replying to ${_replyTo!.authorName}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                AppFeedback.tap();
                                setState(() => _replyTo = null);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: _replyTo != null ? 'Write a reply...' : l10n.whatsOnYourMind,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.85)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.85)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              maxLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _submitComment(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _submitting ? null : _submitComment,
                            icon: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded),
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

class _CommentsLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE8ECF0),
        highlightColor: const Color(0xFFF8FAFC),
        period: const Duration(milliseconds: 1000),
        child: Column(
          children: List.generate(
            4,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i == 3 ? 0 : 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 13,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 11,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 11,
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

