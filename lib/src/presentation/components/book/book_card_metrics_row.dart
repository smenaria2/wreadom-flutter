import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../../domain/models/book.dart';
import '../../../utils/format_utils.dart';
import '../../../utils/reading_time_utils.dart';

/// Compact single-line row displaying reads (eye icon) and estimated time to read (clock icon)
/// designed for book cards on the homepage and list views.
class BookCardMetricsRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final l10n = AppLocalizations.of(context);
    final style = textStyle ??
        TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w500,
          height: 1.15,
        );

    final viewCount = book.viewCount ?? 0;
    final readsFormatted = FormatUtils.formatNumber(viewCount);
    final readingTimeMins = estimateBookReadingTimeMinutes(book);
    final readingTimeFormatted =
        formatCompactReadingTime(readingTimeMins, l10n: l10n);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Reads item
        Icon(
          Icons.visibility_outlined,
          size: iconSize,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          readsFormatted,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 8),
        // Reading time item
        Icon(
          Icons.schedule_rounded,
          size: iconSize,
          color: color,
        ),
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
