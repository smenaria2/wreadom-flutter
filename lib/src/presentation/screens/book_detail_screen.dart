import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/book.dart';
import '../components/book/review_sheet.dart';
import '../components/book/quote_sheet.dart';
import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';

class BookDetailScreen extends ConsumerWidget {
  final String bookId;
  final Book? preloadedBook; // passed from list for instant hero display

  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.preloadedBook,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = preloadedBook != null
        ? AsyncValue.data(preloadedBook)
        : ref.watch(bookDetailProvider(bookId));

    return Scaffold(
      body: bookAsync.when(
        data: (book) {
          if (book == null) {
            return const Center(child: Text('Book not found'));
          }
          return _BookDetailBody(book: book);
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _BookDetailBody extends ConsumerWidget {
  final Book book;
  const _BookDetailBody({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authors = book.authors.map((a) => a.name).join(', ');
    final userAsync = ref.watch(currentUserProvider);
    final bookIdStr = book.id.toString();
    final isSaved = userAsync.maybeWhen(
      data: (u) =>
          u != null &&
          u.savedBooks.any((e) => e?.toString() == bookIdStr),
      orElse: () => false,
    );

    return CustomScrollView(
      slivers: [
        // ─── Hero AppBar ───────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // blurred background colour
                Container(
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
                // Cover art centred
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Hero(
                      tag: 'book-cover-${book.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: book.coverUrl != null
                            ? Image.network(
                                book.coverUrl!,
                                height: 220,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
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

        // ─── Content ────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Title & Author
              Text(
                book.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                authors.isNotEmpty ? 'by $authors' : 'Unknown Author',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  if (book.averageRating != null) ...[
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      book.averageRating!.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (book.viewCount != null) ...[
                    Icon(Icons.visibility_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${_formatCount(book.viewCount!)} views',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(width: 16),
                  ],
                  if (book.chapterCount != null || (book.chapters?.isNotEmpty ?? false)) ...[
                    Icon(Icons.menu_book_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${book.chapterCount ?? book.chapters!.length} chapters',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Subjects / tags
              if (book.subjects.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: book.subjects.take(5).map((s) {
                    return Chip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor:
                          theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // CTA Buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(
                        userAsync.maybeWhen(
                                  data: (u) => u?.readingProgress?[book.id.toString()] != null,
                                  orElse: () => false,
                                )
                            ? 'Continue Reading'
                            : 'Start Reading',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final bookIdStr = book.id.toString();
                        final progress = userAsync.maybeWhen(
                          data: (u) => u?.readingProgress?[bookIdStr],
                          orElse: () => null,
                        );

                        int startChapter = 0;
                        if (progress != null && progress is Map) {
                          startChapter = progress['chapterIndex'] ?? 0;
                        }

                        Navigator.of(context).pushNamed(
                          AppRoutes.reader,
                          arguments: ReaderArguments(
                            book: book,
                            initialChapterIndex: startChapter,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final user = await ref.read(currentUserProvider.future);
                      if (user == null) return;
                      final savedBooks = List<dynamic>.from(user.savedBooks);
                      final idStr = book.id.toString();
                      if (savedBooks.any((e) => e?.toString() == idStr)) {
                        savedBooks.removeWhere((e) => e?.toString() == idStr);
                      } else {
                        savedBooks.add(book.id);
                      }
                      await ref
                          .read(authRepositoryProvider)
                          .updateUserSavedBooks(user.id, savedBooks);
                      ref.invalidate(currentUserProvider);
                    },
                    child: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Community Actions
              Row(
                children: [
                   _ActionButton(
                    icon: Icons.star_outline_rounded,
                    label: 'Review',
                    onTap: () => showReviewSheet(context, book),
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.format_quote_rounded,
                    label: 'Quote',
                    onTap: () => showQuoteSheet(context, book),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Description
              if (book.description != null && book.description!.isNotEmpty) ...[
                Text(
                  'About this Book',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _ExpandableText(text: book.description!),
                const SizedBox(height: 24),
              ],

              // Chapters list
              if (book.chapters != null && book.chapters!.isNotEmpty) ...[
                Text(
                  'Chapters',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...book.chapters!.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ch = entry.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primaryContainer,
                      radius: 16,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(
                      ch.title,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.reader,
                        arguments: ReaderArguments(
                          book: book,
                          initialChapterIndex: i,
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 32),
              ],
            ]),
          ),
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

// ─── Placeholder cover ───────────────────────────────────────────────────────
class _PlaceholderCover extends StatelessWidget {
  final String title;
  const _PlaceholderCover({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
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

// ─── Expandable text ─────────────────────────────────────────────────────────
class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
