import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/models/book.dart';
import '../../../utils/book_collaboration_utils.dart';
import '../../utils/date_formatter.dart';

class WriterBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onEditStory;
  final VoidCallback? onDeleteDraft;

  const WriterBookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onEditStory,
    this.onDeleteDraft,
  });

  @override
  Widget build(BuildContext context) {
    final isPublished = book.status == 'published';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: '${book.title}, ${isPublished ? 'published' : 'draft'} story',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Last update: ${formatTimestamp(book.updatedAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatItem(
                            icon: Icons.remove_red_eye_outlined,
                            value: '${book.viewCount ?? 0}',
                          ),
                          const SizedBox(width: 12),
                          _StatItem(
                            icon: Icons.star_outline_rounded,
                            value:
                                book.averageRating?.toStringAsFixed(1) ?? '0.0',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onEditStory != null) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Edit story',
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: colorScheme.onSurfaceVariant,
                      onPressed: onEditStory,
                    ),
                  ),
                ],
                if (onDeleteDraft != null) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Delete draft',
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: colorScheme.error,
                      onPressed: onDeleteDraft,
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
        'Collab',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPublished
            ? Colors.green.withValues(alpha: 0.14)
            : colorScheme.tertiaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
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

  const _StatItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
