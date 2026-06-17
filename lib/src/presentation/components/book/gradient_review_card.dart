import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GradientReviewCard extends StatelessWidget {
  final int rating;
  final String bookTitle;
  final String? bookCover;
  final String? bookAuthorName;
  final VoidCallback? onBookTap;

  const GradientReviewCard({
    super.key,
    required this.rating,
    required this.bookTitle,
    this.bookCover,
    this.bookAuthorName,
    this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onBookTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerLow,
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.25),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Gradient Bar
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFF59E0B), // Amber 500
                      Color(0xFFEA580C), // Orange 600
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content Row
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      if (bookCover != null && bookCover!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: bookCover!,
                            width: 44,
                            height: 64,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 44,
                              height: 64,
                              color: colorScheme.onSurface.withValues(alpha: 0.05),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 44,
                              height: 64,
                              color: colorScheme.onSurface.withValues(alpha: 0.05),
                              child: const Icon(Icons.book_rounded, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              bookTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (bookAuthorName != null && bookAuthorName!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'by $bookAuthorName',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Rating Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toDouble().toStringAsFixed(1),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.amber[800] ?? Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
