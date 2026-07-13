import 'package:flutter/material.dart';
import '../../../domain/models/book_collection.dart';
import 'collection_widgets.dart';

class RoundedCollectionCard extends StatelessWidget {
  const RoundedCollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
    this.heroScope = 'default',
  });

  final BookCollection collection;
  final VoidCallback onTap;
  final String heroScope;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = SizedBox(
      width: 80,
      height: 80,
      child: ClipOval(
        child: CollectionCoverCollage(
          collection: collection,
          borderRadius: 0,
        ),
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: cover,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 84,
              child: Text(
                collection.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${collection.bookCount} ${collection.bookCount == 1 ? 'book' : 'books'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
