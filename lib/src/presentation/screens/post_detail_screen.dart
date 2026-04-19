import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/comment.dart';
import '../../domain/models/feed_post.dart';
import '../../utils/app_link_helper.dart';
import '../components/feed_post_card.dart';
import '../providers/auth_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/feed_providers.dart';
import '../widgets/comment_widgets.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId, this.preloadedPost});

  final String postId;
  final FeedPost? preloadedPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(singlePostProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share(
              'Check out this post on Wreadom: ${AppLinkHelper.post(postId)}',
              subject: 'Wreadom Post',
            ),
          ),
        ],
      ),
      body: postAsync.when(
        data: (post) {
          final effectivePost = post ?? preloadedPost;
          if (effectivePost == null) {
            return const Center(child: Text('Post not found or deleted'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(singlePostProvider(postId));
              ref.invalidate(feedPostCommentsProvider(postId));
            },
            child: ListView(
              children: [
                FeedPostCard(post: effectivePost, openOnTap: false),
                _InlineComments(post: effectivePost),
              ],
            ),
          );
        },
        loading: () => preloadedPost != null
            ? ListView(
                children: [
                  FeedPostCard(post: preloadedPost!, openOnTap: false),
                  _InlineComments(post: preloadedPost!),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load post: $err')),
      ),
    );
  }
}

class _InlineComments extends ConsumerStatefulWidget {
  const _InlineComments({required this.post});

  final FeedPost post;

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
    final postId = widget.post.id;
    final text = _controller.value.text.trim();
    final user = ref.read(currentUserProvider).asData?.value;
    if (postId == null || text.isEmpty || user == null) return;

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

    final commentsAsync = ref.watch(feedPostCommentsProvider(postId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            commentsAsync.maybeWhen(
              data: (comments) => 'Comments (${comments.length})',
              orElse: () => 'Comments',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No comments yet. Be the first!'),
                );
              }
              return Column(
                children: [
                  for (final comment in comments)
                    CommentTile(
                      comment: comment,
                      onReply: () => setState(() => _replyingTo = comment),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Failed to load comments: $error'),
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
                      'Replying to ${_replyingTo!.displayName ?? _replyingTo!.username}',
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
                        ? 'Add a comment...'
                        : 'Add a reply...',
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
}
