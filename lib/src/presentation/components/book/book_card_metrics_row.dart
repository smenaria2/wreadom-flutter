import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../../domain/models/book.dart';
import '../../../utils/format_utils.dart';
import '../../../utils/reading_time_utils.dart';
import '../../providers/book_providers.dart';
import 'book_card_meta_tags.dart';

/// Compact reading-time label (e.g. "5 min") for a book. Uses the stored
/// `readingTimeMinutes` when present, otherwise estimates from live chapters.
String bookReadingTimeLabel(WidgetRef ref, Book book, AppLocalizations? l10n) {
  final int readingTimeMins;
  if (book.readingTimeMinutes != null && book.readingTimeMinutes! > 0) {
    readingTimeMins = book.readingTimeMinutes!;
  } else {
    final chaptersAsync = ref.watch(liveBookChaptersProvider(book.id));
    final chapters = chaptersAsync.asData?.value ?? book.chapters;
    readingTimeMins = estimateBookReadingTimeMinutes(book, chapters: chapters);
  }
  return formatCompactReadingTime(readingTimeMins, l10n: l10n);
}

/// Single-line "genre · ⏱ read time" meta row for book cards. Falls back to
/// the content type label when the book has no usable sub-type.
class BookCardMetaLine extends ConsumerWidget {
  final Book book;
  final TextStyle? textStyle;
  final double iconSize;

  const BookCardMetaLine({
    super.key,
    required this.book,
    this.textStyle,
    this.iconSize = 11,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.onSurfaceVariant.withValues(alpha: 0.75);
    final style =
        textStyle ??
        TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w500,
          height: 1.15,
        );
    final iconColor = style.color ?? color;
    final l10n = AppLocalizations.of(context);

    final parts = l10n == null ? null : resolveBookContentTypeParts(book, l10n);
    final genre = parts?.subType ?? parts?.type;
    final readingTime = bookReadingTimeLabel(ref, book, l10n);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (genre != null && genre.isNotEmpty) ...[
          Flexible(
            child: Text(
              genre,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(' · ', style: style),
        ],
        Icon(Icons.schedule_rounded, size: iconSize, color: iconColor),
        const SizedBox(width: 3),
        Text(readingTime, style: style, maxLines: 1),
      ],
    );
  }
}

/// Compact single-line row displaying reads (eye icon) and estimated time to read (clock icon)
/// designed for book cards on the homepage and list views.
class BookCardMetricsRow extends ConsumerWidget {
  final Book book;
  final TextStyle? textStyle;
  final double iconSize;

  const BookCardMetricsRow({
    super.key,
    required this.book,
    this.textStyle,
    this.iconSize = 12,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final l10n = AppLocalizations.of(context);
    final style =
        textStyle ??
        TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w500,
          height: 1.15,
        );

    final viewCount = book.viewCount ?? 0;
    final readsFormatted = FormatUtils.formatNumber(viewCount);
    final readingTimeFormatted = bookReadingTimeLabel(ref, book, l10n);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Reads item
        Icon(Icons.visibility_outlined, size: iconSize, color: color),
        const SizedBox(width: 3),
        Text(
          readsFormatted,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 8),
        // Reading time item
        Icon(Icons.schedule_rounded, size: iconSize, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            readingTimeFormatted,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
