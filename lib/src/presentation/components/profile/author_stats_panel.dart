import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../domain/models/book.dart';
import '../../../domain/models/user_model.dart';
import '../../../utils/format_utils.dart';
import '../../providers/book_providers.dart';

class AuthorStatsPanel extends ConsumerWidget {
  const AuthorStatsPanel({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final booksAsync = ref.watch(userBooksProvider(user.id));
    final joinedDate = _formatJoinedDate(user.createdAt);

    return booksAsync.when(
      data: (books) {
        final stats = _AuthorStats.fromBooks(books);
        return _StatsGrid(
          items: [
            _StatsItem(
              label: l10n.averageRating,
              value: stats.averageRating == null
                  ? l10n.noRatings
                  : stats.averageRating!.toStringAsFixed(1),
              icon: Icons.star_rounded,
            ),
            _StatsItem(
              label: l10n.totalReads,
              value: FormatUtils.formatNumber(stats.totalReads),
              icon: Icons.visibility_outlined,
            ),
            _StatsItem(
              label: l10n.booksPublished,
              value: FormatUtils.formatNumber(stats.booksPublished),
              icon: Icons.library_books_outlined,
            ),
            _StatsItem(
              label: l10n.dateJoined,
              value: joinedDate.isEmpty ? '-' : joinedDate,
              icon: Icons.calendar_today_outlined,
            ),
          ],
        );
      },
      loading: () => _StatsGrid(
        items: [
          _StatsItem(
            label: l10n.averageRating,
            value: '...',
            icon: Icons.star_rounded,
          ),
          _StatsItem(
            label: l10n.totalReads,
            value: '...',
            icon: Icons.visibility_outlined,
          ),
          _StatsItem(
            label: l10n.booksPublished,
            value: '...',
            icon: Icons.library_books_outlined,
          ),
          _StatsItem(
            label: l10n.dateJoined,
            value: joinedDate.isEmpty ? '-' : joinedDate,
            icon: Icons.calendar_today_outlined,
          ),
        ],
      ),
      error: (_, _) => _StatsGrid(
        items: [
          _StatsItem(
            label: l10n.averageRating,
            value: '-',
            icon: Icons.star_rounded,
          ),
          _StatsItem(
            label: l10n.totalReads,
            value: '-',
            icon: Icons.visibility_outlined,
          ),
          _StatsItem(
            label: l10n.booksPublished,
            value: '-',
            icon: Icons.library_books_outlined,
          ),
          _StatsItem(
            label: l10n.dateJoined,
            value: joinedDate.isEmpty ? '-' : joinedDate,
            icon: Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  static String _formatJoinedDate(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return '';
    return FormatUtils.formatTimestamp(timestamp);
  }
}

class _AuthorStats {
  const _AuthorStats({
    required this.booksPublished,
    required this.totalReads,
    required this.averageRating,
  });

  final int booksPublished;
  final int totalReads;
  final double? averageRating;

  factory _AuthorStats.fromBooks(List<Book> books) {
    var totalReads = 0;
    var ratingTotal = 0.0;
    var ratingWeight = 0;
    var unratedWeight = 0;

    for (final book in books) {
      totalReads += book.viewCount ?? 0;
      final rating = book.averageRating ?? 0;
      final count = book.ratingsCount ?? 0;
      if (rating > 0 && count > 0) {
        ratingTotal += rating * count;
        ratingWeight += count;
      } else if (rating > 0) {
        ratingTotal += rating;
        unratedWeight += 1;
      }
    }

    final totalWeight = ratingWeight + unratedWeight;
    return _AuthorStats(
      booksPublished: books.length,
      totalReads: totalReads,
      averageRating: totalWeight == 0 ? null : ratingTotal / totalWeight,
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});

  final List<_StatsItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items
                .map((item) => SizedBox(width: itemWidth, child: item))
                .toList(),
          );
        },
      ),
    );
  }
}

class _StatsItem extends StatelessWidget {
  const _StatsItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
