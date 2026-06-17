import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../../domain/models/book.dart';
import '../../../domain/models/feed_post.dart';
import '../../../utils/app_haptics.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feed_providers.dart';
import '../../utils/book_author_utils.dart';

class QuoteSharePreviewSheet extends ConsumerStatefulWidget {
  final Book book;
  final String? chapterTitle;
  final String quoteText;
  final Uint8List imageBytes;
  final String shareText;
  final String chapterLink;

  const QuoteSharePreviewSheet({
    super.key,
    required this.book,
    required this.chapterTitle,
    required this.quoteText,
    required this.imageBytes,
    required this.shareText,
    required this.chapterLink,
  });

  @override
  ConsumerState<QuoteSharePreviewSheet> createState() =>
      _QuoteSharePreviewSheetState();
}

class _QuoteSharePreviewSheetState extends ConsumerState<QuoteSharePreviewSheet> {
  bool _isSharingToFeed = false;

  Future<void> _shareExternally() async {
    try {
      final authors = bookAuthorName(widget.book);
      final caption = 'Read :: "${widget.book.title}" and "$authors" on Wreadom. Read hundreds of Stories on Wreadom. ${widget.chapterLink} ::';
      await Share.shareXFiles(
        [
          XFile.fromData(
            widget.imageBytes,
            name: '${widget.book.title.replaceAll(RegExp(r'[^\w\s\-]'), '')}-quote.png',
            mimeType: 'image/png',
          ),
        ],
        text: caption,
        subject: 'Quote from ${widget.book.title}',
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _shareInFeed() async {
    final l10n = AppLocalizations.of(context)!;
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signInToShare)),
        );
      }
      return;
    }

    setState(() => _isSharingToFeed = true);

    try {
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
        text: widget.quoteText,
        quote: widget.quoteText,
        chapterTitle: widget.chapterTitle,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        likes: const [],
        visibility: 'public',
      );

      await ref.read(feedRepositoryProvider).createFeedPost(post);
      await AppHaptics.light();
      ref.invalidate(feedPostsProvider);
      ref.invalidate(pagedFeedPostsProvider(FeedFilter.public));
      ref.invalidate(pagedFeedPostsProvider(FeedFilter.mine));
      ref.invalidate(pagedUserFeedPostsProvider(user.id));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.quoteShared)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToShareQuote(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharingToFeed = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
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
                    l10n.shareQuote,
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
              // Quote image preview
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // Share Externally
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSharingToFeed ? null : _shareExternally,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Share to Feed
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _isSharingToFeed
                            ? null
                            : const LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6), // Purple 500
                                  Color(0xFF6366F1), // Indigo 500
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isSharingToFeed ? null : _shareInFeed,
                        icon: _isSharingToFeed
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.forum_rounded),
                        label: Text(_isSharingToFeed ? 'Sharing...' : 'Post to Feed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showQuoteSharePreviewSheet({
  required BuildContext context,
  required Book book,
  required String? chapterTitle,
  required String quoteText,
  required Uint8List imageBytes,
  required String shareText,
  required String chapterLink,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => QuoteSharePreviewSheet(
      book: book,
      chapterTitle: chapterTitle,
      quoteText: quoteText,
      imageBytes: imageBytes,
      shareText: shareText,
      chapterLink: chapterLink,
    ),
  );
}
