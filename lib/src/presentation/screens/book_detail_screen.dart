import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/book.dart';
import '../../domain/models/comment.dart';
import '../../utils/app_link_helper.dart';
import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/profile_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../widgets/comment_widgets.dart';
import '../widgets/report_dialog.dart';
import '../components/book/comment_reply_sheet.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.preloadedBook,
    this.heroTag,
  });

  final String bookId;
  final Book? preloadedBook;
  final String? heroTag;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookRepositoryProvider).incrementViewCount(widget.bookId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = widget.preloadedBook != null
        ? AsyncValue.data(widget.preloadedBook)
        : ref.watch(bookDetailProvider(widget.bookId));

    return Scaffold(
      body: bookAsync.when(
        data: (book) {
          if (book == null) return const Center(child: Text('Book not found'));
          return _BookDetailBody(book: book, heroTag: widget.heroTag);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _BookDetailBody extends ConsumerWidget {
  const _BookDetailBody({required this.book, this.heroTag});

  final Book book;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authors = book.authors
        .map((a) => a.name)
        .where((n) => n.isNotEmpty)
        .join(', ');
    final userAsync = ref.watch(currentUserProvider);
    final authorAsync = book.authorId == null
        ? null
        : ref.watch(publicProfileProvider(book.authorId!));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 330,
          pinned: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => Share.share(
                'Read "${book.title}" on Wreadom: ${AppLinkHelper.book(book.id)}',
                subject: book.title,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'report') {
                  showDialog(
                    context: context,
                    builder: (context) => ReportDialog(
                      targetId: book.id,
                      targetType: 'book',
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report_problem_outlined),
                      SizedBox(width: 8),
                      Text('Report Book'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                        theme.colorScheme.surface,
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Hero(
                      tag: heroTag ?? 'book-cover-${book.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: book.coverUrl != null
                            ? CachedNetworkImage(
                                imageUrl: book.coverUrl!,
                                height: 220,
                                width: 150,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(
                                  height: 220,
                                  width: 150,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (_, _, _) =>
                                    _PlaceholderCover(title: book.title),
                              )
                            : _PlaceholderCover(title: book.title),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                book.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _AuthorLine(
                authors: authors.isNotEmpty ? authors : 'Unknown Author',
                authorAsync: authorAsync,
              ),
              const SizedBox(height: 16),
              _StatsRow(book: book),
              if (book.subjects.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: book.subjects.take(5).map((subject) {
                    return Chip(
                      label: Text(
                        subject,
                        style: const TextStyle(fontSize: 12),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.5),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(
                        _hasProgress(userAsync, book.id)
                            ? 'Continue Reading'
                            : 'Start Reading',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _openReader(context, userAsync),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SaveDownloadButton(book: book),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Share.share(
                      'Read "${book.title}" on Wreadom: ${AppLinkHelper.book(book.id)}',
                      subject: book.title,
                    ),
                    child: const Icon(Icons.share_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if ((book.description ?? '').isNotEmpty) ...[
                Text(
                  'About this Book',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _ExpandableText(text: book.description!),
              ],
              const SizedBox(height: 28),
              _LatestDiscussionSection(bookId: book.id),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  static bool _hasProgress(AsyncValue<dynamic> userAsync, String bookId) {
    return userAsync.maybeWhen(
      data: (u) => u?.readingProgress?[bookId] != null,
      orElse: () => false,
    );
  }

  void _openReader(BuildContext context, AsyncValue<dynamic> userAsync) {
    final progress = userAsync.maybeWhen(
      data: (u) => u?.readingProgress?[book.id],
      orElse: () => null,
    );
    var startChapter = 0;
    if (progress is Map) {
      startChapter = (progress['chapterIndex'] as int?) ?? 0;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.reader,
      arguments: ReaderArguments(book: book, initialChapterIndex: startChapter),
    );
  }
}

class _AuthorLine extends StatelessWidget {
  const _AuthorLine({required this.authors, required this.authorAsync});

  final String authors;
  final AsyncValue<dynamic>? authorAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = authorAsync?.asData?.value;
    return Row(
      children: [
        if (user?.photoURL != null) ...[
          CircleAvatar(
            radius: 12,
            backgroundImage: CachedNetworkImageProvider(user!.photoURL!),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            authors,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _LatestDiscussionSection extends ConsumerStatefulWidget {
  const _LatestDiscussionSection({required this.bookId});

  final String bookId;

  @override
  ConsumerState<_LatestDiscussionSection> createState() =>
      _LatestDiscussionSectionState();
}

class _LatestDiscussionSectionState
    extends ConsumerState<_LatestDiscussionSection> {
  int _visibleCount = 5;

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(bookCommentsProvider(widget.bookId));
    final theme = Theme.of(context);

    return commentsAsync.when(
      data: (comments) {
        if (comments.isEmpty) return const SizedBox.shrink();
        final visible = comments.take(_visibleCount).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest discussion',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final comment in visible)
              CommentTile(
                comment: comment,
                onReply: () => _showReplySheet(comment),
              ),
            if (_visibleCount < comments.length)
              TextButton.icon(
                onPressed: () => setState(() => _visibleCount += 5),
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Show more'),
              ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Future<void> _showReplySheet(Comment comment) async {
    if (comment.id == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentReplySheet(
        comment: comment,
        bookId: widget.bookId,
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.grey[600];
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (book.averageRating != null)
          _Stat(
            icon: Icons.star_rounded,
            label: book.averageRating!.toStringAsFixed(1),
            color: Colors.amber,
          ),
        _Stat(
          icon: Icons.visibility_outlined,
          label: '${_formatCount(book.viewCount ?? 0)} reads',
          color: textColor,
        ),
        if (book.chapterCount != null || (book.chapters?.isNotEmpty ?? false))
          _Stat(
            icon: Icons.menu_book_outlined,
            label: '${book.chapterCount ?? book.chapters!.length} chapters',
            color: textColor,
          ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            title,
            maxLines: 4,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Show less' : 'Read more'),
        ),
      ],
    );
  }
}

class _SaveDownloadButton extends ConsumerStatefulWidget {
  const _SaveDownloadButton({required this.book});

  final Book book;

  @override
  ConsumerState<_SaveDownloadButton> createState() =>
      _SaveDownloadButtonState();
}

class _SaveDownloadButtonState extends ConsumerState<_SaveDownloadButton> {
  bool _isDownloading = false;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final downloaded = await ref
        .read(offlineServiceProvider)
        .isBookDownloaded(widget.book.id);
    if (mounted) setState(() => _isDownloaded = downloaded);
  }

  Future<void> _handleSaveDownload() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    if (!mounted) return;

    final idStr = widget.book.id.toString();
    final savedBooks = List<dynamic>.from(user.savedBooks);
    final isSaved = savedBooks.any((id) => id?.toString() == idStr);

    if (isSaved && _isDownloaded) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove saved book?'),
          content: const Text(
            'The offline download will stay available unless you remove it separately.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Unsave', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        savedBooks.removeWhere((id) => id?.toString() == idStr);
        await ref
            .read(authRepositoryProvider)
            .updateUserSavedBooks(user.id, savedBooks);
        ref.invalidate(currentUserProvider);
        ref.invalidate(savedBooksProvider);
      }
      return;
    }

    setState(() => _isDownloading = true);
    try {
      if (!isSaved) {
        savedBooks.add(widget.book.id);
        await ref
            .read(authRepositoryProvider)
            .updateUserSavedBooks(user.id, savedBooks);
      }
      final chapters = await ref.read(
        bookChaptersProvider(widget.book.id).future,
      );
      await ref
          .read(offlineServiceProvider)
          .downloadBook(widget.book, chapters);

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });
        ref.invalidate(currentUserProvider);
        ref.invalidate(savedBooksProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book saved and downloaded for offline reading.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: _isDownloaded
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      onPressed: _isDownloading ? null : _handleSaveDownload,
      child: _isDownloading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isDownloaded
                  ? Icons.bookmark_added_rounded
                  : Icons.bookmark_add_outlined,
              color: _isDownloaded
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
    );
  }
}
