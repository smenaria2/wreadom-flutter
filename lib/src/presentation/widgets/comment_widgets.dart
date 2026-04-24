import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../domain/models/comment.dart';
import '../providers/auth_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/feed_providers.dart';
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
      if (widget.comment.feedPostId != null) {
        await ref
            .read(feedRepositoryProvider)
            .toggleCommentLike(
              widget.comment.feedPostId!,
              widget.comment.id!,
              user.id,
            );
        ref.invalidate(feedPostCommentsProvider(widget.comment.feedPostId!));
      } else {
        await ref
            .read(commentRepositoryProvider)
            .toggleCommentLike(widget.comment.id!, user.id);
      }
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

  Future<void> _editComment() async {
    final l10n = AppLocalizations.of(context)!;
    final comment = widget.comment;
    final commentId = comment.id;
    if (commentId == null) return;
    final text = await _showEditDialog(context, l10n.editComment, comment.text);
    if (text == null) return;
    try {
      if (comment.feedPostId != null) {
        await ref
            .read(feedRepositoryProvider)
            .updateCommentText(comment.feedPostId!, commentId, text);
        ref.invalidate(feedPostCommentsProvider(comment.feedPostId!));
      } else {
        await ref
            .read(commentRepositoryProvider)
            .updateCommentText(commentId, text);
      }
      if (comment.bookId != null) {
        ref.invalidate(bookCommentsProvider(comment.bookId!.toString()));
      }
      if (mounted) HapticFeedback.selectionClick();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.editFailed(e.toString()))));
      }
    }
  }

  void _leftSwipeAction() {
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;
    if (_canHighlight(user)) {
      _toggleHighlight();
    } else if (widget.comment.userId == user.id) {
      _editComment();
    } else if (widget.comment.id != null) {
      _reportComment(widget.comment);
    }
  }

  bool _canHighlight(dynamic user) {
    final comment = widget.comment;
    return (comment.rating ?? 0) > 0 &&
        widget.bookAuthorId != null &&
        widget.bookAuthorId == user.id &&
        comment.userId != user.id &&
        comment.id != null;
  }

  void _reportComment(Comment comment) {
    if (comment.id == null) return;
    showDialog(
      context: context,
      builder: (context) =>
          ReportDialog(targetId: comment.id!, targetType: 'comment'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final comment = widget.comment;
    final replies = comment.replies ?? [];
    final name = comment.displayName ?? comment.username;
    final user = ref.watch(currentUserProvider).asData?.value;
    final liked =
        _liked ??
        (user != null && (comment.likes ?? const <String>[]).contains(user.id));
    final likeCount = _likeCount ?? (comment.likes ?? const <String>[]).length;
    final isHighlighted = comment.isHighlighted == true;
    final canHighlight = user != null && _canHighlight(user);
    final isOwner = user != null && comment.userId == user.id;
    final leftLabel = canHighlight
        ? isHighlighted
              ? l10n.unpin
              : l10n.pin
        : isOwner
        ? l10n.edit
        : l10n.report;
    final leftIcon = canHighlight
        ? Icons.push_pin_outlined
        : isOwner
        ? Icons.edit_outlined
        : Icons.report_problem_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SwipeActionShell(
          leftLabel: leftLabel,
          leftIcon: leftIcon,
          rightLabel: l10n.reply,
          rightIcon: Icons.reply_rounded,
          onLeftAction: _leftSwipeAction,
          onRightAction: widget.onReply,
          onDoubleTap: _toggleLike,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _ProfileAvatar(
              userId: comment.userId,
              name: name,
              photoUrl: comment.userPhotoURL,
              radius: 20,
            ),
            trailing: user == null
                ? null
                : PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: widget.metadataColor,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'pin':
                          _toggleHighlight();
                          break;
                        case 'edit':
                          _editComment();
                          break;
                        case 'delete':
                          _confirmDeleteComment(context, ref, comment);
                          break;
                        case 'report':
                          _reportComment(comment);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (canHighlight)
                        PopupMenuItem(
                          value: 'pin',
                          child: _MenuRow(
                            icon: isHighlighted
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            label: isHighlighted ? l10n.unpin : l10n.pin,
                          ),
                        ),
                      if (comment.userId == user.id)
                        PopupMenuItem(
                          value: 'edit',
                          child: _MenuRow(
                            icon: Icons.edit_outlined,
                            label: l10n.edit,
                          ),
                        ),
                      if (comment.userId == user.id)
                        PopupMenuItem(
                          value: 'delete',
                          child: _MenuRow(
                            icon: Icons.delete_outline_rounded,
                            label: l10n.delete,
                          ),
                        )
                      else if (comment.id != null)
                        PopupMenuItem(
                          value: 'report',
                          child: _MenuRow(
                            icon: Icons.report_problem_outlined,
                            label: l10n.report,
                          ),
                        ),
                    ],
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
                    Icons.push_pin_rounded,
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
                      _formatTimestamp(context, comment.timestamp),
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
                        l10n.reply,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                      feedPostId: comment.feedPostId,
                      bookId: comment.bookId?.toString(),
                      onReply: widget.onReply,
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
    required this.onReply,
    this.feedPostId,
    this.bookId,
    this.textColor,
    this.metadataColor,
  });

  final String? commentId;
  final CommentReply reply;
  final VoidCallback onReply;
  final String? feedPostId;
  final String? bookId;
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
      if (widget.feedPostId != null) {
        await ref
            .read(feedRepositoryProvider)
            .toggleReplyLike(widget.feedPostId!, commentId, replyId, user.id);
        ref.invalidate(feedPostCommentsProvider(widget.feedPostId!));
      } else {
        await ref
            .read(commentRepositoryProvider)
            .toggleReplyLike(commentId, replyId, user.id);
      }
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

  Future<void> _editReply() async {
    final l10n = AppLocalizations.of(context)!;
    final commentId = widget.commentId;
    if (commentId == null) return;
    final replyId = widget.reply.id ?? widget.reply.timestamp.toString();
    final text = await _showEditDialog(
      context,
      l10n.editReply,
      widget.reply.text,
    );
    if (text == null) return;
    try {
      if (widget.feedPostId != null) {
        await ref
            .read(feedRepositoryProvider)
            .updateReplyText(widget.feedPostId!, commentId, replyId, text);
        ref.invalidate(feedPostCommentsProvider(widget.feedPostId!));
      } else {
        await ref
            .read(commentRepositoryProvider)
            .updateReplyText(commentId, replyId, text);
      }
      if (widget.bookId != null) {
        ref.invalidate(bookCommentsProvider(widget.bookId!));
      }
      if (mounted) HapticFeedback.selectionClick();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.editFailed(e.toString()))));
      }
    }
  }

  void _leftSwipeAction() {
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;
    if (widget.reply.userId == user.id) {
      _editReply();
    } else {
      _reportReply();
    }
  }

  void _reportReply() {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        targetId: widget.reply.id ?? widget.reply.timestamp.toString(),
        targetType: 'comment_reply',
      ),
    );
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

    final l10n = AppLocalizations.of(context)!;
    final isOwner = user != null && reply.userId == user.id;
    return _SwipeActionShell(
      leftLabel: isOwner ? l10n.edit : l10n.report,
      leftIcon: isOwner ? Icons.edit_outlined : Icons.report_problem_outlined,
      rightLabel: l10n.reply,
      rightIcon: Icons.reply_rounded,
      onLeftAction: _leftSwipeAction,
      onRightAction: widget.onReply,
      onDoubleTap: _toggleLike,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _ProfileAvatar(
          userId: reply.userId,
          name: name,
          photoUrl: reply.userPhotoURL,
          radius: 14,
        ),
        trailing: user == null
            ? null
            : PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: widget.metadataColor,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editReply();
                      break;
                    case 'delete':
                      _confirmDeleteReply(
                        context,
                        ref,
                        widget.commentId,
                        reply,
                        feedPostId: widget.feedPostId,
                        bookId: widget.bookId,
                      );
                      break;
                    case 'report':
                      _reportReply();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (reply.userId == user.id)
                    PopupMenuItem(
                      value: 'edit',
                      child: _MenuRow(icon: Icons.edit_outlined, label: l10n.edit),
                    ),
                  if (reply.userId == user.id)
                    PopupMenuItem(
                      value: 'delete',
                      child: _MenuRow(
                        icon: Icons.delete_outline_rounded,
                        label: l10n.delete,
                      ),
                    )
                  else
                    PopupMenuItem(
                      value: 'report',
                      child: _MenuRow(
                        icon: Icons.report_problem_outlined,
                        label: l10n.report,
                      ),
                    ),
                ],
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
                  _formatTimestamp(context, reply.timestamp),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeActionShell extends StatefulWidget {
  const _SwipeActionShell({
    required this.child,
    required this.leftLabel,
    required this.leftIcon,
    required this.rightLabel,
    required this.rightIcon,
    required this.onLeftAction,
    required this.onRightAction,
    this.onDoubleTap,
  });

  final Widget child;
  final String leftLabel;
  final IconData leftIcon;
  final String rightLabel;
  final IconData rightIcon;
  final VoidCallback onLeftAction;
  final VoidCallback onRightAction;
  final VoidCallback? onDoubleTap;

  @override
  State<_SwipeActionShell> createState() => _SwipeActionShellState();
}

class _SwipeActionShellState extends State<_SwipeActionShell> {
  static const double _threshold = 72;
  static const double _maxSlide = 96;

  double _dragOffset = 0;
  bool _hapticArmed = false;

  bool get _showRightAction => _dragOffset > 0;

  void _handleDragUpdate(DragUpdateDetails details) {
    final next = (_dragOffset + (details.primaryDelta ?? 0)).clamp(
      -_maxSlide,
      _maxSlide,
    );
    final crossed = next.abs() >= _threshold;
    if (crossed && !_hapticArmed) {
      HapticFeedback.selectionClick();
      _hapticArmed = true;
    } else if (!crossed) {
      _hapticArmed = false;
    }
    setState(() => _dragOffset = next.toDouble());
  }

  void _handleDragEnd(DragEndDetails details) {
    final offset = _dragOffset;
    setState(() {
      _dragOffset = 0;
      _hapticArmed = false;
    });
    if (offset >= _threshold) {
      HapticFeedback.lightImpact();
      widget.onRightAction();
    } else if (offset <= -_threshold) {
      HapticFeedback.lightImpact();
      widget.onLeftAction();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _dragOffset.abs() > 8 ? 1 : 0,
              duration: const Duration(milliseconds: 90),
              child: Align(
                alignment: _showRightAction
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _SlideActionChip(
                    label: _showRightAction
                        ? widget.rightLabel
                        : widget.leftLabel,
                    icon: _showRightAction ? widget.rightIcon : widget.leftIcon,
                    color: Colors.black,
                    foreground: Colors.white,
                    armed: _dragOffset.abs() >= _threshold,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: widget.onDoubleTap,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onHorizontalDragCancel: () => setState(() {
              _dragOffset = 0;
              _hapticArmed = false;
            }),
            child: AnimatedContainer(
              duration: _dragOffset == 0
                  ? const Duration(milliseconds: 180)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_dragOffset, 0, 0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideActionChip extends StatelessWidget {
  const _SlideActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.foreground,
    required this.armed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color foreground;
  final bool armed;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: armed ? 1.04 : 1,
      duration: const Duration(milliseconds: 120),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
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

String _formatTimestamp(BuildContext context, int timestamp) {
  final l10n = AppLocalizations.of(context)!;
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
  if (diff.inDays > 0) return l10n.daysAgo(diff.inDays);
  if (diff.inHours > 0) return l10n.hoursAgo(diff.inHours);
  if (diff.inMinutes > 0) return l10n.minutesAgo(diff.inMinutes);
  return l10n.justNow;
}

Future<void> _confirmDeleteComment(
  BuildContext context,
  WidgetRef ref,
  Comment comment,
) async {
  final l10n = AppLocalizations.of(context)!;
  if (comment.id == null) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.deleteCommentTitle),
      content: Text(l10n.deleteActionUndone),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      if (comment.feedPostId != null) {
        await ref
            .read(feedRepositoryProvider)
            .deleteComment(comment.feedPostId!, comment.id!);
      } else {
        await ref.read(commentRepositoryProvider).deleteComment(comment.id!);
      }
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
        ).showSnackBar(
          SnackBar(content: Text(l10n.deleteFailed(e.toString()))),
        );
      }
    }
  }
}

Future<void> _confirmDeleteReply(
  BuildContext context,
  WidgetRef ref,
  String? commentId,
  CommentReply reply, {
  String? feedPostId,
  String? bookId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  if (commentId == null) return;
  final replyId = reply.id ?? reply.timestamp.toString();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.deleteReplyTitle),
      content: Text(l10n.deleteActionUndone),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      if (feedPostId != null) {
        await ref
            .read(feedRepositoryProvider)
            .deleteReply(feedPostId, commentId, replyId);
      } else {
        await ref
            .read(commentRepositoryProvider)
            .deleteReply(commentId, replyId);
      }
      if (feedPostId != null) {
        ref.invalidate(feedPostCommentsProvider(feedPostId));
      }
      if (bookId != null) ref.invalidate(bookCommentsProvider(bookId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(l10n.deleteFailed(e.toString()))),
        );
      }
    }
  }
}

Future<String?> _showEditDialog(
  BuildContext context,
  String title,
  String initialText,
) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initialText);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 3,
        maxLines: 8,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: l10n.writeYourUpdate,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            Navigator.of(ctx).pop(text);
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  controller.dispose();
  return result == initialText.trim() ? null : result;
}
