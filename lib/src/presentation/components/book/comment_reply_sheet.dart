import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/comment.dart';
import '../../providers/auth_providers.dart';
import '../../providers/comment_providers.dart';

class CommentReplySheet extends ConsumerStatefulWidget {
  const CommentReplySheet({
    super.key,
    required this.comment,
    required this.bookId,
  });

  final Comment comment;
  final String bookId;

  @override
  ConsumerState<CommentReplySheet> createState() => _CommentReplySheetState();
}

class _CommentReplySheetState extends ConsumerState<CommentReplySheet>
    with RestorationMixin {
  final _controller = RestorableTextEditingController();
  bool _submitting = false;

  @override
  String? get restorationId =>
      'book_comment_reply_${widget.bookId}_${widget.comment.id ?? 'unknown'}';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_controller, 'reply_text');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.value.text.trim();
    if (text.isEmpty) return;

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(commentRepositoryProvider).addReply(
            widget.comment.id!,
            CommentReply(
              userId: user.id,
              username: user.username,
              displayName: user.displayName,
              penName: user.penName,
              text: text,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              userPhotoURL: user.photoURL,
            ),
          );

      await HapticFeedback.lightImpact();
      _controller.value.clear();
      ref.invalidate(bookCommentsProvider(widget.bookId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post reply: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reply to ${widget.comment.displayName ?? widget.comment.username}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller.value,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Add a reply...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Reply'),
            ),
          ),
        ],
      ),
    );
  }
}
