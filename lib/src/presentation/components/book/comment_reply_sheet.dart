import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
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
      await ref
          .read(commentRepositoryProvider)
          .addReply(
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToPostReply(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.replyingTo(
              widget.comment.displayName ?? widget.comment.username,
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller.value,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.addAReply,
              border: const OutlineInputBorder(),
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
                  : Text(l10n.reply),
            ),
          ),
        ],
      ),
    );
  }
}
