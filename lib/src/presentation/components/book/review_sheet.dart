import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../../domain/models/book.dart';
import '../../../domain/models/feed_post.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feed_providers.dart';
import '../../utils/book_author_utils.dart';

/// Shows a sheet for writing a book review.
void showReviewSheet(BuildContext context, Book book) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ReviewSheet(book: book),
  );
}

class _ReviewSheet extends ConsumerStatefulWidget {
  final Book book;
  const _ReviewSheet({required this.book});

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  final _textController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectRating)));
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseWriteShortReview)));
      return;
    }

    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseLoginToReview)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final post = FeedPost(
        userId: user.id,
        username: user.username,
        displayName: user.displayName,
        penName: user.penName,
        userPhotoURL: user.photoURL,
        type: 'review',
        text: text,
        rating: _rating,
        bookId: widget.book.id.toString(),
        bookTitle: widget.book.title,
        bookAuthorName: bookAuthorName(widget.book),
        bookCover: widget.book.coverUrl,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        likes: const [],
        visibility: 'public',
        privacy: 'public',
      );

      await ref.read(feedRepositoryProvider).createFeedPost(post);
      ref.invalidate(feedPostsProvider);
      ref.invalidate(pagedFeedPostsProvider(FeedFilter.public));
      ref.invalidate(pagedFeedPostsProvider(FeedFilter.mine));
      ref.invalidate(pagedUserFeedPostsProvider(user.id));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reviewShared),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.reviewTitle(widget.book.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_isSubmitting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(onPressed: _submit, child: Text(l10n.post)),
            ],
          ),
          const SizedBox(height: 16),

          // Rating Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final active = index < _rating;
              return IconButton(
                iconSize: 32,
                icon: Icon(
                  active ? Icons.star_rounded : Icons.star_border_rounded,
                  color: active ? Colors.amber : Colors.grey[400],
                ),
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 5,
            minLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.reviewHint,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
