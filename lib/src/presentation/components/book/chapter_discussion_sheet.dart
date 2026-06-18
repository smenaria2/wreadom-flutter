import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/comment.dart';
import '../../providers/comment_providers.dart';
import '../../widgets/comment_widgets.dart';
import '../../widgets/glass_surface.dart';
import '../../../utils/app_haptics.dart';
import 'comment_reply_sheet.dart';
import '../../routing/app_routes.dart';
import '../../routing/app_router.dart';
import '../../providers/book_providers.dart';

void showChapterDiscussionSheet({
  required BuildContext context,
  required String bookId,
  required String bookTitle,
  required String bookAuthorId,
  required String bookAuthorName,
  required String? bookCover,
  required String? chapterId,
  required int? chapterIndex,
  required String chapterTitle,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.98,
      expand: false,
      builder: (context, scrollController) {
        return ChapterDiscussionSheet(
          scrollController: scrollController,
          bookId: bookId,
          bookTitle: bookTitle,
          bookAuthorId: bookAuthorId,
          bookAuthorName: bookAuthorName,
          bookCover: bookCover,
          chapterId: chapterId,
          chapterIndex: chapterIndex,
          chapterTitle: chapterTitle,
        );
      },
    ),
  );
}

class ChapterDiscussionSheet extends ConsumerStatefulWidget {
  const ChapterDiscussionSheet({
    super.key,
    required this.scrollController,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthorId,
    required this.bookAuthorName,
    this.bookCover,
    this.chapterId,
    this.chapterIndex,
    required this.chapterTitle,
  });

  final ScrollController scrollController;
  final String bookId;
  final String bookTitle;
  final String bookAuthorId;
  final String bookAuthorName;
  final String? bookCover;
  final String? chapterId;
  final int? chapterIndex;
  final String chapterTitle;

  @override
  ConsumerState<ChapterDiscussionSheet> createState() => _ChapterDiscussionSheetState();
}

class _ChapterDiscussionSheetState extends ConsumerState<ChapterDiscussionSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final commentsAsync = ref.watch(liveBookCommentsProvider(widget.bookId));

    return GlassSurface(
      strong: true,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 36.0),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    unawaited(AppHaptics.selection());
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: GestureDetector(
              onTap: () async {
                try {
                  unawaited(AppHaptics.selection());
                  final book = await ref.read(bookRepositoryProvider).getBook(widget.bookId);
                  if (book == null || !context.mounted) return;
                  int chapterIndex = widget.chapterIndex ?? 0;
                  if (widget.chapterIndex == null && widget.chapterId != null && book.chapters != null) {
                    final foundIndex = book.chapters!.indexWhere((ch) => ch.id == widget.chapterId);
                    if (foundIndex != -1) {
                      chapterIndex = foundIndex;
                    }
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamed(
                    AppRoutes.reader,
                    arguments: ReaderArguments(
                      book: book,
                      initialChapterIndex: chapterIndex,
                    ),
                  );
                } catch (_) {}
              },
              child: Text(
                widget.chapterTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: commentsAsync.when(
              data: (items) {
                final chapterId = widget.chapterId?.toString();
                final chapterComments = items.where((comment) {
                  if (chapterId != null &&
                      chapterId.isNotEmpty &&
                      comment.chapterId == chapterId) {
                    return true;
                  }
                  if (widget.chapterIndex != null && comment.chapterIndex == widget.chapterIndex) {
                    return true;
                  }
                  return false;
                }).toList();

                if (chapterComments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No comments for this chapter yet.',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: chapterComments.length,
                  itemBuilder: (context, index) {
                    final comment = chapterComments[index];
                    return CommentTile(
                      key: ValueKey('chapter-discussion-comment-${comment.id ?? comment.timestamp}'),
                      comment: comment,
                      bookId: widget.bookId,
                      bookTitle: widget.bookTitle,
                      bookAuthorName: widget.bookAuthorName,
                      bookCover: widget.bookCover,
                      bookAuthorId: widget.bookAuthorId,
                      onReply: () => _showReplySheet(comment),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading comments: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReplySheet(Comment comment) async {
    if (comment.id == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentReplySheet(
        comment: comment,
        bookId: widget.bookId,
      ),
    );
  }
}
