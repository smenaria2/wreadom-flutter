import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/feed_post.dart';
import '../providers/feed_providers.dart';
import '../providers/auth_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';

/// Relative timestamp helper
String _relativeTime(int timestampMs) {
  final now = DateTime.now();
  final then = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  final diff = now.difference(then);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}

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
  const FeedPostCard({super.key, required this.post});

  @override
  ConsumerState<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends ConsumerState<FeedPostCard> {
  bool _liking = false;

  Future<void> _toggleLike() async {
    if (_liking) return;
    final userAsync = ref.read(currentUserProvider).asData?.value;
    final user = userAsync;
    if (user == null || widget.post.id == null) return;

    setState(() => _liking = true);
    try {
      await ref
          .read(feedRepositoryProvider)
          .toggleLike(widget.post.id!, user.id);
      ref.invalidate(feedPostsProvider);
      ref.invalidate(userFeedPostsProvider(widget.post.userId));
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final accentColor = _typeColor(post.type);
    final typeLabel = post.type[0].toUpperCase() + post.type.substring(1);

    // Check if current user liked this post
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final liked = currentUser != null && post.likes.contains(currentUser.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // ─── Type accent bar ─────────────────────────────────────
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
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
                            arguments:
                                PublicProfileArguments(userId: post.userId),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: post.userPhotoURL != null
                                  ? NetworkImage(post.userPhotoURL!)
                                  : null,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primaryContainer,
                              child: post.userPhotoURL == null
                                  ? Text(
                                      post.username.isNotEmpty
                                          ? post.username[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
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
                                    _relativeTime(post.timestamp),
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
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_typeIcon(post.type),
                              size: 12, color: accentColor),
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        if (post.bookCover != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              post.bookCover!,
                              width: 36,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(),
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
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

                const SizedBox(height: 12),

                // ─── Actions ──────────────────────────────────────
                Row(
                  children: [
                    // Like
                    _ActionButton(
                      icon: liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: liked ? Colors.red : null,
                      label: post.likes.length.toString(),
                      loading: _liking,
                      onTap: _toggleLike,
                    ),
                    const SizedBox(width: 8),
                    // Comment
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label:
                          (post.comments?.length ?? 0).toString(),
                      onTap: () => _showComments(context),
                    ),
                    const Spacer(),
                    // Share
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 18),
                      color: Colors.grey[600],
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Native share integration is the next step.',
                            ),
                          ),
                        );
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.teal.withValues(alpha: 0.6),
            width: 3,
          ),
        ),
      ),
      child: Text(
        '"$text"',
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          fontStyle: FontStyle.italic,
          color: Colors.grey[800],
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

  const _ActionButton({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
              Icon(icon, size: 18, color: iconColor ?? Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
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
      await ref.read(feedRepositoryProvider).addComment(widget.post.id!, {
        'userId': user.id,
        'username': user.username,
        'displayName': user.displayName,
        'userPhotoURL': user.photoURL,
        'text': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'likes': [],
      });
      ref.invalidate(feedPostsProvider);
      _ctrl.clear();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.post.comments ?? [];
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Comments (${comments.length})',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          if (comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No comments yet. Be the first!',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: comments.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, i) {
                  final c = comments[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundImage: c.userPhotoURL != null
                          ? NetworkImage(c.userPhotoURL!)
                          : null,
                      child: c.userPhotoURL == null
                          ? Text(c.username[0].toUpperCase(),
                              style: const TextStyle(fontSize: 12))
                          : null,
                    ),
                    title: Text(c.displayName ?? c.username,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(c.text),
                    trailing: Text(
                      _relativeTime(c.timestamp),
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          const Divider(),
          // Comment input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Add a comment…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
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
