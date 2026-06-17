import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../../domain/models/book.dart';
import '../../../domain/models/feed_post.dart';
import '../../../utils/app_haptics.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feed_providers.dart';
import '../../utils/book_author_utils.dart';
import '../../utils/book_share_utils.dart';
import '../../utils/share_text_helper.dart';

class ChapterSharePreviewSheet extends ConsumerStatefulWidget {
  final Book book;
  final String chapterTitle;
  final String link;

  const ChapterSharePreviewSheet({
    super.key,
    required this.book,
    required this.chapterTitle,
    required this.link,
  });

  @override
  ConsumerState<ChapterSharePreviewSheet> createState() =>
      _ChapterSharePreviewSheetState();
}

class _ChapterSharePreviewSheetState extends ConsumerState<ChapterSharePreviewSheet> {
  late final TextEditingController _messageController;
  bool _isSharingToFeed = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messageController.text.isEmpty) {
      _messageController.text = generateChapterShareText(
        book: widget.book,
        chapterTitle: widget.chapterTitle,
        link: widget.link,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _shareExternally() async {
    try {
      await shareBookLinkWithCover(
        text: _messageController.text.trim(),
        subject: '${widget.book.title} - ${widget.chapterTitle}',
        coverUrl: widget.book.coverUrl,
        fileNameBase: widget.book.title,
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

    final shareText = _messageController.text.trim();
    if (shareText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a message to share')),
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
        penName: user.penName,
        userPhotoURL: user.photoURL,
        type: 'post',
        text: shareText,
        bookId: widget.book.id,
        bookTitle: widget.book.title,
        bookAuthorName: bookAuthorName(widget.book),
        bookCover: widget.book.coverUrl,
        chapterTitle: widget.chapterTitle,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        likes: const [],
        visibility: 'public',
        privacy: 'public',
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
          SnackBar(content: Text(l10n.sharedToFeed)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share to feed: $e')),
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
                    'Share Chapter',
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
              // Book details row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.book.coverUrl != null && widget.book.coverUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.book.coverUrl!,
                        width: 70,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.chapterTitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${bookAuthorName(widget.book)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Custom text input
              TextField(
                controller: _messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Custom Message',
                  hintText: 'Enter your message to share...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
                      label: const Text('Share Externally'),
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
                                  Color(0xFF3B82F6), // Blue 500
                                  Color(0xFF1D4ED8), // Blue 700
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
                        label: Text(_isSharingToFeed ? 'Sharing...' : l10n.shareToFeed),
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

void showChapterSharePreviewSheet({
  required BuildContext context,
  required Book book,
  required String chapterTitle,
  required String link,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ChapterSharePreviewSheet(
      book: book,
      chapterTitle: chapterTitle,
      link: link,
    ),
  );
}
