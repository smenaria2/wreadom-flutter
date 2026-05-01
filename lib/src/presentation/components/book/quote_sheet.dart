import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../../domain/models/book.dart';
import '../../../domain/models/feed_post.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feed_providers.dart';
import '../../utils/book_author_utils.dart';

class QuoteSheet extends ConsumerStatefulWidget {
  final Book book;

  const QuoteSheet({super.key, required this.book});

  @override
  ConsumerState<QuoteSheet> createState() => _QuoteSheetState();
}

class _QuoteSheetState extends ConsumerState<QuoteSheet> {
  final _quoteController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quoteController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quoteText = _quoteController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (quoteText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterQuote)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('User not logged in');

      final post = FeedPost(
        userId: user.id,
        username: user.username,
        displayName: user.displayName,
        userPhotoURL: user.photoURL,
        type: 'quote',
        bookId: widget.book.id,
        bookTitle: widget.book.title,
        bookAuthorName: bookAuthorName(widget.book),
        bookCover: widget.book.coverUrl,
        text: _commentController.text.trim(),
        quote: quoteText,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        likes: [],
        visibility: 'public',
      );

      await ref.read(feedRepositoryProvider).createFeedPost(post);
      ref.invalidate(feedPostsProvider);
      ref.invalidate(pagedFeedPostsProvider(FeedFilter.public));
      ref.invalidate(pagedFeedPostsProvider(FeedFilter.mine));
      ref.invalidate(pagedUserFeedPostsProvider(user.id));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.quoteShared)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToShareQuote(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.shareAQuote,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quote input
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Icon(
                      Icons.format_quote_rounded,
                      color: Colors.grey,
                      size: 32,
                    ),
                    TextField(
                      controller: _quoteController,
                      maxLines: 4,
                      minLines: 2,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: l10n.enterQuoteHint,
                        border: InputBorder.none,
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Personal comment input
              TextField(
                controller: _commentController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: l10n.addThoughtsOptional,
                  prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.postQuote,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showQuoteSheet(BuildContext context, Book book) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => QuoteSheet(book: book),
  );
}
