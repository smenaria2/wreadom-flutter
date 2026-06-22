import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../../domain/models/comment.dart';
import '../../../domain/models/feed_post.dart';
import '../../../utils/app_haptics.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feed_providers.dart';
import '../../widgets/modal_feedback_scope.dart';

class CommentSharePreviewSheet extends ConsumerStatefulWidget {
  final Comment comment;
  final String bookId;
  final String bookTitle;
  final String bookAuthorName;
  final String? bookCover;
  final Uint8List imageBytes;
  final String fallbackText;
  final String link;

  const CommentSharePreviewSheet({
    super.key,
    required this.comment,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthorName,
    required this.bookCover,
    required this.imageBytes,
    required this.fallbackText,
    required this.link,
  });

  @override
  ConsumerState<CommentSharePreviewSheet> createState() =>
      _CommentSharePreviewSheetState();
}

class _CommentSharePreviewSheetState
    extends ConsumerState<CommentSharePreviewSheet> {
  bool _isSharingToFeed = false;

  Future<void> _shareExternally() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            widget.imageBytes,
            name:
                '${widget.bookTitle.replaceAll(RegExp(r'[^\w\s\-]'), '')}-review.png',
            mimeType: 'image/png',
          ),
        ],
        text: widget.link,
        subject: l10n.reviewTitle(widget.bookTitle),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ModalFeedbackScope.show(
          context,
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
        ModalFeedbackScope.show(
          context,
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
        type: widget.comment.rating != null ? 'review' : 'comment',
        bookId: widget.bookId,
        bookTitle: widget.bookTitle,
        bookAuthorName: widget.bookAuthorName,
        bookCover: widget.bookCover,
        text: widget.comment.text,
        rating: widget.comment.rating,
        chapterTitle: widget.comment.chapterTitle,
        chapterId: widget.comment.chapterId,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.sharedToFeed)));
      }
    } catch (e) {
      if (mounted) {
        ModalFeedbackScope.show(
          context,
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
                    widget.comment.rating != null
                        ? 'Share Review'
                        : 'Share Comment',
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
              // Comment image card preview
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
                    child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
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
                                  Color(0xFFF59E0B), // Amber 500
                                  Color(0xFFEA580C), // Orange 600
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
                        label: Text(
                          _isSharingToFeed ? 'Sharing...' : l10n.shareToFeed,
                        ),
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

void showCommentSharePreviewSheet({
  required BuildContext context,
  required Comment comment,
  required String bookId,
  required String bookTitle,
  required String bookAuthorName,
  required String? bookCover,
  required Uint8List imageBytes,
  required String fallbackText,
  required String link,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ModalFeedbackScope(
      child: CommentSharePreviewSheet(
        comment: comment,
        bookId: bookId,
        bookTitle: bookTitle,
        bookAuthorName: bookAuthorName,
        bookCover: bookCover,
        imageBytes: imageBytes,
        fallbackText: fallbackText,
        link: link,
      ),
    ),
  );
}
