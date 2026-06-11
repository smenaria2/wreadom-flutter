import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../../domain/models/book.dart';
import '../../../utils/book_collaboration_utils.dart';
import '../../../utils/book_publication_date.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/glass_surface.dart';

class WriterBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onEditStory;
  final VoidCallback? onDeleteDraft;
  final VoidCallback? onDeleteBlocked;

  const WriterBookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onEditStory,
    this.onDeleteDraft,
    this.onDeleteBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final isPublished = book.status == 'published';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final publishedLabel = l10n?.published ?? 'Published';
    final draftLabel = l10n?.draft ?? 'Draft';
    final lastUpdateLabel = l10n?.lastUpdate ?? 'Last update';
    final publishedOnLabel = l10n?.publishedOn ?? 'Published';
    final editStoryLabel = l10n?.editStory ?? 'Edit story';
    final deleteDraftLabel = l10n?.deleteDraftTitle ?? 'Delete draft';
    final dateLabel = isPublished ? publishedOnLabel : lastUpdateLabel;
    final dateValue = isPublished
        ? formatTimestamp(publicationTimestamp(book))
        : formatTimestamp(book.updatedAt);

    return Semantics(
      button: true,
      label: '${book.title}, ${isPublished ? publishedLabel : draftLabel}',
      child: GlassSurface(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                    image: book.coverUrl != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(book.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: book.coverUrl == null
                      ? Icon(Icons.book, color: colorScheme.primary)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        book.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatusBadge(isPublished: isPublished),
                          if (isAcceptedCollaboration(book)) ...[
                            const SizedBox(width: 6),
                            const _CollabBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _StatItem(
                                icon: Icons.remove_red_eye_outlined,
                                value: '${book.viewCount ?? 0}',
                              ),
                              _StatItem(
                                icon: Icons.star_outline_rounded,
                                value:
                                    book.averageRating?.toStringAsFixed(1) ??
                                    '0.0',
                              ),
                              _StatItem(
                                icon: Icons.calendar_today_outlined,
                                value: '$dateLabel: $dateValue',
                                maxWidth: constraints.maxWidth,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (onEditStory != null) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: editStoryLabel,
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: colorScheme.onSurfaceVariant,
                      onPressed: onEditStory,
                    ),
                  ),
                ],
                if (onDeleteDraft != null || onDeleteBlocked != null) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: deleteDraftLabel,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: onDeleteDraft == null
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.error,
                      onPressed: onDeleteDraft ?? onDeleteBlocked,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollabBadge extends StatelessWidget {
  const _CollabBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        AppLocalizations.of(context)?.collab ?? 'Collab',
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isPublished;

  const _StatusBadge({required this.isPublished});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = isPublished
        ? AppLocalizations.of(context)?.published ?? 'Published'
        : AppLocalizations.of(context)?.draft ?? 'Draft';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPublished
            ? Colors.green.withValues(alpha: 0.14)
            : colorScheme.tertiaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPublished ? Colors.green : colorScheme.onTertiaryContainer,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final double? maxWidth;

  const _StatItem({required this.icon, required this.value, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final text = Text(
      value,
      style: TextStyle(fontSize: 12, color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        if (maxWidth == null) text else Flexible(child: text),
      ],
    );
    if (maxWidth == null) return row;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: row,
    );
  }
}
