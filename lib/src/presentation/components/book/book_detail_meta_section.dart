import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../../domain/models/book.dart';
import '../../../domain/models/comment.dart';
import '../../../utils/book_publication_date.dart';
import '../../../utils/format_utils.dart';
import '../../../utils/reading_time_utils.dart';
import '../../providers/book_providers.dart';
import '../../providers/comment_providers.dart';

class BookDetailMetaSection extends ConsumerWidget {
  final Book book;

  const BookDetailMetaSection({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurfaceVariant;
    final l10n = AppLocalizations.of(context)!;

    // 1. Rating calculation
    final commentsAsync = ref.watch(liveBookCommentsProvider(book.id));
    final rating = commentsAsync.maybeWhen(
      data: (comments) => _resolveRatingSummary(book, comments),
      orElse: () => _resolveRatingSummary(book, const <Comment>[]),
    );

    // 2. Reading time calculation (watching chapters stream for latest content)
    final chaptersAsync = ref.watch(liveBookChaptersProvider(book.id));
    final chapters = chaptersAsync.asData?.value ?? book.chapters;
    final readingTimeMins = estimateBookReadingTimeMinutes(book, chapters: chapters);
    final readingTimeText = formatDetailReadingTime(readingTimeMins, l10n: l10n);

    // 3. Reads count
    final viewCount = book.viewCount ?? 0;
    final readsText = l10n.readsStat(_formatCount(viewCount));

    // 4. Content Type
    final contentType = _localizedContentType(context, book);

    // 5. Chapters count
    final chapterCount = book.chapterCount ?? book.chapters?.length ?? (chapters?.isNotEmpty == true ? chapters!.length : null);
    final chaptersText = chapterCount != null && chapterCount > 0
        ? (chapterCount == 1 ? l10n.singleChapterStat : l10n.chaptersStat(chapterCount.toString()))
        : null;

    // 6. Publication date
    final pubTimestamp = publicationTimestamp(book) ?? (book.status == 'published' ? (book.publishedAt ?? book.createdAt) : null);
    final pubDateText = pubTimestamp != null
        ? l10n.publishedDateLabel(FormatUtils.formatTimestamp(pubTimestamp))
        : null;

    final isArchive = book.source == 'archive' ||
        (book.source == null &&
            !(book.id.length == 20 && RegExp(r'^[a-zA-Z0-9]{20}$').hasMatch(book.id)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Metrics Row (Rating, Reading Time, Reads)
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _RatingMetric(summary: rating),
            if (isArchive) _ArchiveVotesInline(book: book),
            _MetaItem(
              icon: Icons.schedule_rounded,
              label: readingTimeText,
              color: textColor,
            ),
            _MetaItem(
              icon: Icons.visibility_outlined,
              label: readsText,
              color: textColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Content Attributes Row (Type, Chapters, Published Date)
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (contentType != null)
              _MetaItem(
                icon: Icons.category_outlined,
                label: contentType,
                color: textColor,
              ),
            if (chaptersText != null)
              _MetaItem(
                icon: Icons.menu_book_outlined,
                label: chaptersText,
                color: textColor,
              ),
            if (pubDateText != null)
              _MetaItem(
                icon: Icons.calendar_today_outlined,
                label: pubDateText,
                color: textColor,
              ),
          ],
        ),
      ],
    );
  }

  static String? _localizedContentType(BuildContext context, Book book) {
    final l10n = AppLocalizations.of(context)!;
    return switch (book.contentType?.trim().toLowerCase()) {
      'story' => l10n.contentTypeStory,
      'poem' => l10n.contentTypePoem,
      'article' => l10n.contentTypeArticle,
      _ => null,
    };
  }

  static _RatingSummary _resolveRatingSummary(Book book, List<Comment> comments) {
    if (book.averageRating != null && book.averageRating! > 0) {
      return _RatingSummary(
        average: book.averageRating!,
        count: book.ratingsCount ?? 0,
      );
    }
    final ratings = comments
        .where((comment) => comment.rating != null && comment.rating! > 0)
        .map((comment) => comment.rating!.toDouble())
        .toList();
    if (ratings.isEmpty) return const _RatingSummary.none();
    final average =
        ratings.reduce((sum, rating) => sum + rating) / ratings.length;
    return _RatingSummary(average: average, count: ratings.length);
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _RatingSummary {
  const _RatingSummary({this.average, this.count = 0});
  const _RatingSummary.none() : average = null, count = 0;

  final double? average;
  final int count;
}

class _RatingMetric extends StatelessWidget {
  const _RatingMetric({required this.summary});

  final _RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final average = summary.average;
    final theme = Theme.of(context);
    final starColor = theme.brightness == Brightness.dark
        ? const Color(0xFFFFD36A)
        : const Color(0xFFC47A00);

    if (average == null || average <= 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            l10n.noRatings,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    final countLabel = summary.count > 0 ? ' (${summary.count})' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 16, color: starColor),
        const SizedBox(width: 4),
        Text(
          '${average.toStringAsFixed(1)}$countLabel',
          style: TextStyle(
            color: starColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaItem({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ArchiveVotesInline extends ConsumerWidget {
  const _ArchiveVotesInline({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(bookVoteStatsProvider(book.id));
    final userVoteAsync = ref.watch(userBookVoteProvider(book.id));
    final currentVote = userVoteAsync.value;

    return statsAsync.maybeWhen(
      data: (stats) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ArchiveVoteButton(
            icon: Icons.thumb_up_alt_outlined,
            selectedIcon: Icons.thumb_up_alt,
            count: stats.upvotes,
            selected: currentVote == 'up',
            onPressed: () => ref
                .read(bookVoteControllerProvider)
                .vote(book.id, currentVote == 'up' ? null : 'up'),
          ),
          const SizedBox(width: 6),
          _ArchiveVoteButton(
            icon: Icons.thumb_down_alt_outlined,
            selectedIcon: Icons.thumb_down_alt,
            count: stats.downvotes,
            selected: currentVote == 'down',
            onPressed: () => ref
                .read(bookVoteControllerProvider)
                .vote(book.id, currentVote == 'down' ? null : 'down'),
          ),
        ],
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ArchiveVoteButton extends StatelessWidget {
  const _ArchiveVoteButton({
    required this.icon,
    required this.selectedIcon,
    required this.count,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final IconData selectedIcon;
  final int count;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, size: 14, color: color),
            if (count > 0) ...[
              const SizedBox(width: 3),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
