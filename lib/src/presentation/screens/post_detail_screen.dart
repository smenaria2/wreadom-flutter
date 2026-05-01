import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../domain/models/comment.dart';
import '../../domain/models/feed_post.dart';
import '../../utils/app_link_helper.dart';
import '../components/feed_post_card.dart';
import '../providers/auth_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/feed_providers.dart';
import '../routing/app_routes.dart';
import '../widgets/comment_widgets.dart';
import 'static_info_screen.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
    this.preloadedPost,
    this.targetCommentId,
    this.targetReplyId,
  });

  final String postId;
  final FeedPost? preloadedPost;
  final String? targetCommentId;
  final String? targetReplyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(singlePostProvider(postId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.post),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share(
              l10n.checkOutPostOnWreadom(AppLinkHelper.post(postId)),
              subject: l10n.wreadomPost,
            ),
          ),
        ],
      ),
      body: postAsync.when(
        data: (post) {
          final effectivePost = post ?? preloadedPost;
          if (effectivePost == null) {
            return StaticInfoScreen(
              title: 'Content Not Found',
              body: l10n.postNotFoundOrDeleted,
              actionLabel: l10n.searchBooks,
              onAction: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.discovery, arguments: {'query': postId}),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(singlePostProvider(postId));
              ref.invalidate(feedPostCommentsProvider(postId));
            },
            child: ListView(
              children: [
                FeedPostCard(post: effectivePost, openOnTap: false),
                _InlineComments(
                  post: effectivePost,
                  targetCommentId: targetCommentId,
                  targetReplyId: targetReplyId,
                ),
              ],
            ),
          );
        },
        loading: () => preloadedPost != null
            ? ListView(
                children: [
                  FeedPostCard(post: preloadedPost!, openOnTap: false),
                  _InlineComments(
                    post: preloadedPost!,
                    targetCommentId: targetCommentId,
                    targetReplyId: targetReplyId,
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text(l10n.failedToLoadPost(err.toString()))),
      ),
    );
  }
}

class _InlineComments extends ConsumerStatefulWidget {
  const _InlineComments({
    required this.post,
    this.targetCommentId,
    this.targetReplyId,
  });

  final FeedPost post;
  final String? targetCommentId;
  final String? targetReplyId;

  @override
  ConsumerState<_InlineComments> createState() => _InlineCommentsState();
}

class _InlineCommentsState extends ConsumerState<_InlineComments>
    with RestorationMixin {
  final _controller = RestorableTextEditingController();
  Comment? _replyingTo;
  bool _submitting = false;

  @override
  String? get restorationId =>
      'post_detail_comments_${widget.post.id ?? 'unknown'}';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_controller, 'comment_text');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final postId = widget.post.id;
    final text = _controller.value.text.trim();
    final user = ref.read(currentUserProvider).asData?.value;
    if (postId == null || text.isEmpty) return;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.signInToContinueAction)));
      return;
    }

    setState(() => _submitting = true);
    try {
      if (_replyingTo != null) {
        final reply = CommentReply(
          userId: user.id,
          username: user.username,
          displayName: user.displayName,
          userPhotoURL: user.photoURL,
          text: text,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        if (_replyingTo!.feedPostId != null && _replyingTo!.id != null) {
          await ref
              .read(feedRepositoryProvider)
              .addCommentReply(postId, _replyingTo!.id!, reply);
        } else {
          await ref
              .read(commentRepositoryProvider)
              .addReply(_replyingTo!.id!, reply);
        }
      } else {
        await ref.read(feedRepositoryProvider).addComment(postId, {
          'userId': user.id,
          'username': user.username,
          'displayName': user.displayName,
          'userPhotoURL': user.photoURL,
          'text': text,
        });
      }
      await HapticFeedback.lightImpact();
      _controller.value.clear();
      setState(() => _replyingTo = null);
      ref.invalidate(feedPostCommentsProvider(postId));
      ref.invalidate(singlePostProvider(postId));
      ref.invalidate(feedPostsProvider);
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.following));
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.public));
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.mine));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postId = widget.post.id;
    if (postId == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final commentsAsync = ref.watch(feedPostCommentsProvider(postId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            commentsAsync.maybeWhen(
              data: (comments) => l10n.commentsCount(comments.length),
              orElse: () => l10n.comments,
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(l10n.noCommentsYet),
                );
              }
              final targetComment = _targetComment(comments);
              final visibleComments = targetComment == null
                  ? comments
                  : comments
                        .where((comment) => comment.id != targetComment.id)
                        .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (targetComment != null) ...[
                    _TargetCommentHeader(label: l10n.targetComment),
                    CommentTile(
                      key: ValueKey(
                        'post-detail-target-comment-${targetComment.id ?? targetComment.timestamp}',
                      ),
                      comment: targetComment,
                      onReply: () =>
                          setState(() => _replyingTo = targetComment),
                      isTargetComment: true,
                      targetReplyId: widget.targetReplyId,
                    ),
                    const SizedBox(height: 8),
                  ],
                  for (final comment in visibleComments)
                    CommentTile(
                      key: ValueKey(
                        'post-detail-comment-${comment.id ?? comment.timestamp}',
                      ),
                      comment: comment,
                      onReply: () => setState(() => _replyingTo = comment),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) =>
                Text(l10n.failedToLoadComments(error.toString())),
          ),
          if (_replyingTo != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.replyingTo(
                        _replyingTo!.displayName ?? _replyingTo!.username,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller.value,
                  decoration: InputDecoration(
                    hintText: _replyingTo == null
                        ? l10n.addAComment
                        : l10n.addAReply,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Comment? _targetComment(List<Comment> comments) {
    final targetId = widget.targetCommentId?.trim();
    if (targetId == null || targetId.isEmpty) return null;
    for (final comment in comments) {
      if (comment.id == targetId) return comment;
    }
    return null;
  }
}

class _TargetCommentHeader extends StatelessWidget {
  const _TargetCommentHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.push_pin_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
