import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/comment.dart';
import '../providers/auth_providers.dart';
import '../providers/comment_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../widgets/report_dialog.dart';

class CommentTile extends ConsumerStatefulWidget {
  const CommentTile({
    super.key,
    required this.comment,
    required this.onReply,
    this.textColor,
    this.metadataColor,
    this.bookId,
    this.bookAuthorId,
  });

  final Comment comment;
  final VoidCallback onReply;
  final Color? textColor;
  final Color? metadataColor;
  final String? bookId;
  final String? bookAuthorId;

  @override
  ConsumerState<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<CommentTile> {
  bool _liking = false;
  bool _highlighting = false;
  bool? _liked;
  int? _likeCount;

  Future<void> _toggleLike() async {
    if (_liking || widget.comment.id == null) return;
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    final likes = widget.comment.likes ?? const <String>[];
    final wasLiked = _liked ?? likes.contains(user.id);
    final previousCount = _likeCount ?? likes.length;

    setState(() {
      _liking = true;
      _liked = !wasLiked;
      _likeCount = wasLiked ? previousCount - 1 : previousCount + 1;
    });

    try {
      await ref
          .read(commentRepositoryProvider)
          .toggleCommentLike(widget.comment.id!, user.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _liked = wasLiked;
          _likeCount = previousCount;
        });
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _toggleHighlight() async {
    final commentId = widget.comment.id;
    final bookId = widget.bookId ?? widget.comment.bookId?.toString();
    final user = ref.read(currentUserProvider).asData?.value;
    if (_highlighting ||
        commentId == null ||
        bookId == null ||
        user == null ||
        widget.bookAuthorId != user.id) {
      return;
    }

    setState(() => _highlighting = true);
    try {
      await ref
          .read(commentRepositoryProvider)
          .toggleReviewHighlight(
            commentId: commentId,
            bookId: bookId,
            authorId: user.id,
          );
      ref.invalidate(bookCommentsProvider(bookId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _highlighting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comment = widget.comment;
    final replies = comment.replies ?? [];
    final name = comment.displayName ?? comment.username;
    final user = ref.watch(currentUserProvider).asData?.value;
    final liked =
        _liked ??
        (user != null && (comment.likes ?? const <String>[]).contains(user.id));
    final likeCount = _likeCount ?? (comment.likes ?? const <String>[]).length;
    final isReview = (comment.rating ?? 0) > 0;
    final isHighlighted = comment.isHighlighted == true;
    final canHighlight =
        isReview &&
        widget.bookAuthorId != null &&
        user != null &&
        widget.bookAuthorId == user.id &&
        comment.userId != user.id &&
        comment.id != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _ProfileAvatar(
            userId: comment.userId,
            name: name,
            photoUrl: comment.userPhotoURL,
            radius: 20,
          ),
          title: Row(
            children: [
              _ProfileName(
                userId: comment.userId,
                name: name,
                color: widget.textColor,
              ),
              if (comment.rating != null && comment.rating! > 0) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < comment.rating!
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 14,
                      color: index < comment.rating!
                          ? Colors.amber
                          : Colors.grey[400],
                    ),
                  ),
                ),
              ],
              if (isHighlighted) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: Colors.amber[700],
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(comment.text, style: TextStyle(color: widget.textColor)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _formatTimestamp(comment.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.metadataColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 14,
                          color: liked ? Colors.red : widget.metadataColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$likeCount',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: widget.metadataColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: widget.onReply,
                    child: Text(
                      'Reply',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (user != null && comment.userId == user.id) ...[
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _confirmDeleteComment(context, ref, comment),
                      child: Text(
                        'Delete',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else if (user != null && comment.id != null) ...[
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) => ReportDialog(
                          targetId: comment.id!,
                          targetType: 'comment',
                        ),
                      ),
                      child: Text(
                        'Report',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (canHighlight) ...[
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _toggleHighlight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHighlighted
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 14,
                            color: isHighlighted
                                ? Colors.amber
                                : widget.metadataColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isHighlighted ? 'Unstar' : 'Star',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              children: replies
                  .map(
                    (reply) => ReplyTile(
                      commentId: comment.id,
                      reply: reply,
                      textColor: widget.textColor,
                      metadataColor: widget.metadataColor,
                    ),
                  )
                  .toList(),
            ),
          ),
        Divider(color: widget.metadataColor?.withValues(alpha: 0.25)),
      ],
    );
  }
}

class ReplyTile extends ConsumerStatefulWidget {
  const ReplyTile({
    super.key,
    required this.commentId,
    required this.reply,
    this.textColor,
    this.metadataColor,
  });

  final String? commentId;
  final CommentReply reply;
  final Color? textColor;
  final Color? metadataColor;

  @override
  ConsumerState<ReplyTile> createState() => _ReplyTileState();
}

class _ReplyTileState extends ConsumerState<ReplyTile> {
  bool _liking = false;
  bool? _liked;
  int? _likeCount;

  Future<void> _toggleLike() async {
    final replyId = widget.reply.id ?? widget.reply.timestamp.toString();
    final commentId = widget.commentId;
    if (_liking || commentId == null) return;
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    final likes = widget.reply.likes ?? const <String>[];
    final wasLiked = _liked ?? likes.contains(user.id);
    final previousCount = _likeCount ?? likes.length;

    setState(() {
      _liking = true;
      _liked = !wasLiked;
      _likeCount = wasLiked ? previousCount - 1 : previousCount + 1;
    });

    try {
      await ref
          .read(commentRepositoryProvider)
          .toggleReplyLike(commentId, replyId, user.id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = wasLiked;
          _likeCount = previousCount;
        });
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reply = widget.reply;
    final name = reply.displayName ?? reply.username;
    final user = ref.watch(currentUserProvider).asData?.value;
    final liked =
        _liked ??
        (user != null && (reply.likes ?? const <String>[]).contains(user.id));
    final likeCount = _likeCount ?? (reply.likes ?? const <String>[]).length;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _ProfileAvatar(
        userId: reply.userId,
        name: name,
        photoUrl: reply.userPhotoURL,
        radius: 14,
      ),
      title: _ProfileName(
        userId: reply.userId,
        name: name,
        color: widget.textColor,
        fontSize: 13,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.text,
            style: TextStyle(fontSize: 13, color: widget.textColor),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                _formatTimestamp(reply.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: widget.metadataColor,
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: _toggleLike,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 13,
                      color: liked ? Colors.red : widget.metadataColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$likeCount',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: widget.metadataColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (user != null && reply.userId == user.id) ...[
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () => _confirmDeleteReply(
                    context,
                    ref,
                    widget.commentId,
                    reply,
                  ),
                  child: Text(
                    'Delete',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else if (user != null) ...[
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => ReportDialog(
                      targetId: reply.id ?? reply.timestamp.toString(),
                      targetType: 'comment_reply',
                    ),
                  ),
                  child: Text(
                    'Report',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.radius,
  });

  final String userId;
  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openProfile(context, userId),
      child: CircleAvatar(
        radius: radius,
        backgroundImage: photoUrl != null
            ? CachedNetworkImageProvider(photoUrl!)
            : null,
        child: photoUrl == null && name.isNotEmpty
            ? Text(
                name.characters.first.toUpperCase(),
                style: TextStyle(fontSize: radius * 0.75),
              )
            : null,
      ),
    );
  }
}

class _ProfileName extends StatelessWidget {
  const _ProfileName({
    required this.userId,
    required this.name,
    this.color,
    this.fontSize = 14,
  });

  final String userId;
  final String name;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openProfile(context, userId),
      child: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          color: color,
        ),
      ),
    );
  }
}

void _openProfile(BuildContext context, String userId) {
  Navigator.of(context).pushNamed(
    AppRoutes.publicProfile,
    arguments: PublicProfileArguments(userId: userId),
  );
}

String _formatTimestamp(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

Future<void> _confirmDeleteComment(
  BuildContext context,
  WidgetRef ref,
  Comment comment,
) async {
  if (comment.id == null) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Comment?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await ref.read(commentRepositoryProvider).deleteComment(comment.id!);
      // Invaliding providers to refresh UI
      if (comment.bookId != null) {
        ref.invalidate(bookCommentsProvider(comment.bookId!));
      }
      if (comment.feedPostId != null) {
        ref.invalidate(feedPostCommentsProvider(comment.feedPostId!));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}

Future<void> _confirmDeleteReply(
  BuildContext context,
  WidgetRef ref,
  String? commentId,
  CommentReply reply,
) async {
  if (commentId == null) return;
  final replyId = reply.id ?? reply.timestamp.toString();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Reply?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await ref.read(commentRepositoryProvider).deleteReply(commentId, replyId);
      // Re-fetching comments to show update
      // We don't have the bookId/postId here easily without passing it,
      // but usually the parents will refresh if we invalidate the repo's related providers.
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}
