import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/feed_post.dart';
import '../../domain/models/comment.dart';
import '../providers/feed_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/comment_providers.dart';
import '../widgets/comment_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../../utils/format_utils.dart';
import '../widgets/report_dialog.dart';

/// Maps post type → accent colour
Color _typeColor(String type) {
  switch (type.toLowerCase()) {
    case 'review':
      return Colors.amber;
    case 'quote':
      return Colors.teal;
    case 'testimony':
      return Colors.pink;
    default:
      return Colors.blue;
  }
}

/// Maps post type → icon
IconData _typeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'review':
      return Icons.star_rounded;
    case 'quote':
      return Icons.format_quote_rounded;
    case 'testimony':
      return Icons.favorite_rounded;
    default:
      return Icons.edit_note_rounded;
  }
}

class FeedPostCard extends ConsumerStatefulWidget {
  final FeedPost post;
  final bool openOnTap;
  const FeedPostCard({super.key, required this.post, this.openOnTap = true});

  @override
  ConsumerState<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends ConsumerState<FeedPostCard> {
  bool _liking = false;
  bool _deleting = false;
  bool? _optimisticLiked;
  int? _optimisticLikesCount;

  Future<void> _toggleLike() async {
    if (_liking) return;
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null || widget.post.id == null) return;

    final wasLiked = _optimisticLiked ?? widget.post.likes.contains(user.id);
    final prevCount = _optimisticLikesCount ?? widget.post.likes.length;

    setState(() {
      _optimisticLiked = !wasLiked;
      _optimisticLikesCount = wasLiked ? prevCount - 1 : prevCount + 1;
      _liking = true;
    });

    try {
      await ref
          .read(feedRepositoryProvider)
          .toggleLike(widget.post.id!, user.id);
      // No need to invalidate, optimistic state handles it
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _optimisticLiked = wasLiked;
          _optimisticLikesCount = prevCount;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _deletePost() async {
    if (_deleting || widget.post.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This will remove the post and its comments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(feedRepositoryProvider).deleteFeedPost(widget.post.id!);
      ref.invalidate(feedPostsProvider);
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.public));
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.following));
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.mine));
      ref.invalidate(userFeedPostsProvider(widget.post.userId));
      ref.invalidate(singlePostProvider(widget.post.id!));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post deleted')));
      if (!widget.openOnTap) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not delete post: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _typeColor(post.type);
    final typeLabel = post.type[0].toUpperCase() + post.type.substring(1);

    // Check if current user liked this post (with optimistic override)
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final isOwner = currentUser?.id == post.userId;
    final liked =
        _optimisticLiked ??
        (currentUser != null && post.likes.contains(currentUser.id));
    final likesCount = _optimisticLikesCount ?? post.likes.length;

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // ─── Type accent bar ─────────────────────────────────────
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Author row ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.publicProfile,
                            arguments: PublicProfileArguments(
                              userId: post.userId,
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: post.userPhotoURL != null
                                  ? CachedNetworkImageProvider(
                                      post.userPhotoURL!,
                                    )
                                  : null,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: post.userPhotoURL == null
                                  ? Text(
                                      post.username.isNotEmpty
                                          ? post.username[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.displayName ?? post.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    FormatUtils.relativeTime(post.timestamp),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Post type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _typeIcon(post.type),
                            size: 12,
                            color: accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            typeLabel,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (currentUser != null) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: _deleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.more_vert_rounded,
                                size: 18,
                                color: Colors.grey[400],
                              ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (val) {
                          if (val == 'report') {
                            showDialog(
                              context: context,
                              builder: (context) => ReportDialog(
                                targetId: post.id!,
                                targetType: 'post',
                              ),
                            );
                          } else if (val == 'delete') {
                            _deletePost();
                          }
                        },
                        itemBuilder: (context) => [
                          if (isOwner)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Delete Post'),
                                ],
                              ),
                            )
                          else
                            const PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  Icon(Icons.report_problem_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Report Post'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),

                // ─── Star rating (review) ─────────────────────────
                if (post.type.toLowerCase() == 'review' &&
                    post.rating != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < post.rating!
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: Colors.amber,
                      );
                    }),
                  ),
                ],

                // ─── Book reference ───────────────────────────────
                if (post.bookTitle != null) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      if (post.bookId != null) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.bookDetail,
                          arguments: BookDetailArguments(
                            bookId: post.bookId.toString(),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          if (post.bookCover != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: post.bookCover!,
                                width: 36,
                                height: 52,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 36,
                                  height: 52,
                                  color: colorScheme.surfaceContainerHighest,
                                ),
                                errorWidget: (_, _, _) => const SizedBox(),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Regarding',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  post.bookTitle!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // ─── Post text ────────────────────────────────────
                // Italicise quotes
                if (post.type.toLowerCase() == 'quote')
                  _QuoteBlock(text: post.text)
                else
                  Text(
                    post.text,
                    style: const TextStyle(fontSize: 14, height: 1.45),
                  ),

                const SizedBox(height: 10),

                // ─── Post image ───────────────────────────────────
                if (post.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl!,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => const SizedBox(),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ─── Actions ──────────────────────────────────────
                Row(
                  children: [
                    // Like
                    _ActionButton(
                      icon: liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: liked ? Colors.red : null,
                      label: likesCount.toString(),
                      semanticLabel: liked ? 'Unlike post' : 'Like post',
                      loading: _liking,
                      onTap: _toggleLike,
                    ),
                    const SizedBox(width: 8),
                    // Comment
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: (post.commentCount ?? 0).toString(),
                      semanticLabel: 'Show comments',
                      onTap: () => _showComments(context),
                    ),
                    const Spacer(),
                    // Share
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 18),
                      tooltip: 'Share post',
                      color: colorScheme.onSurfaceVariant,
                      onPressed: () {
                        if (post.id != null) {
                          Share.share(
                            'Check out this post on Librebook: https://wreadom.in/posts/${post.id}',
                            subject: 'Librebook Post',
                          );
                        }
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!widget.openOnTap || post.id == null) return card;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.postDetail,
        arguments: PostDetailArguments(postId: post.id!, post: post),
      ),
      child: card,
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CommentsSheet(post: widget.post),
    );
  }
}

// ─── Quote block ─────────────────────────────────────────────────────────────
class _QuoteBlock extends StatelessWidget {
  final String text;
  const _QuoteBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.teal.withValues(alpha: 0.6), width: 3),
        ),
      ),
      child: Text(
        '"$text"',
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          fontStyle: FontStyle.italic,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;
  final bool loading;
  final String semanticLabel;

  const _ActionButton({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.onTap,
    required this.semanticLabel,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      value: label,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? colorScheme.onSurfaceVariant,
                ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Comments sheet ───────────────────────────────────────────────────────────
class _CommentsSheet extends ConsumerStatefulWidget {
  final FeedPost post;
  const _CommentsSheet({required this.post});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _ctrl = TextEditingController();
  bool _submitting = false;
  Comment? _replyingTo;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.post.id == null) return;
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      if (_replyingTo != null) {
        // Submit a reply
        await ref
            .read(commentRepositoryProvider)
            .addReply(
              _replyingTo!.id!,
              CommentReply(
                userId: user.id,
                username: user.username,
                displayName: user.displayName,
                userPhotoURL: user.photoURL,
                text: text,
                timestamp: DateTime.now().millisecondsSinceEpoch,
              ),
            );
      } else {
        // Submit a top-level comment
        await ref.read(feedRepositoryProvider).addComment(widget.post.id!, {
          'userId': user.id,
          'username': user.username,
          'displayName': user.displayName,
          'userPhotoURL': user.photoURL,
          'text': text,
        });
      }

      ref.invalidate(feedPostCommentsProvider(widget.post.id!));
      _ctrl.clear();
      setState(() => _replyingTo = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting comment: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(feedPostCommentsProvider(widget.post.id!));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 12, 0, bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              commentsAsync.when(
                data: (comments) => 'Comments (${comments.length})',
                loading: () => 'Comments…',
                error: (_, _) => 'Comments',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No comments yet. Be the first!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: comments.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, i) {
                    final c = comments[i];
                    return CommentTile(
                      comment: c,
                      onReply: () {
                        setState(() => _replyingTo = c);
                      },
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('Error loading comments: $e')),
              ),
            ),
          ),
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to ${_replyingTo!.displayName ?? _replyingTo!.username}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          // Comment input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: _replyingTo != null
                          ? 'Add a reply…'
                          : 'Add a comment…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  onPressed: _submitting ? null : _submitComment,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
