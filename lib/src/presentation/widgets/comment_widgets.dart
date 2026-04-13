import 'package:flutter/material.dart';
import '../../domain/models/comment.dart';
import 'follow_button.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback onReply;

  const CommentTile({
    super.key,
    required this.comment,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final replies = comment.replies ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: comment.userPhotoURL != null
                ? NetworkImage(comment.userPhotoURL!)
                : null,
            child: comment.userPhotoURL == null
                ? Text(comment.username[0].toUpperCase())
                : null,
          ),
          title: Row(
            children: [
              Text(
                comment.displayName ?? comment.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              FollowButton(targetUserId: comment.userId, compact: true),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(comment.text),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _formatTimestamp(comment.timestamp),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onReply,
                    child: Text(
                      'Reply',
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
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              children: replies.map((reply) => ReplyTile(reply: reply)).toList(),
            ),
          ),
        const Divider(),
      ],
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
}

class ReplyTile extends StatelessWidget {
  final CommentReply reply;

  const ReplyTile({super.key, required this.reply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 14,
        backgroundImage: reply.userPhotoURL != null
            ? NetworkImage(reply.userPhotoURL!)
            : null,
        child: reply.userPhotoURL == null
            ? Text(reply.username[0].toUpperCase(), style: const TextStyle(fontSize: 10))
            : null,
      ),
      title: Row(
        children: [
          Text(
            reply.displayName ?? reply.username,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          FollowButton(targetUserId: reply.userId, compact: true),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reply.text, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            _formatTimestamp(reply.timestamp),
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
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
}
