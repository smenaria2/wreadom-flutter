import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GradientBookCard extends StatelessWidget {
  final String bookTitle;
  final String? bookCover;
  final String? bookAuthorName;
  final VoidCallback? onBookTap;

  const GradientBookCard({
    super.key,
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
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                      Color(0xFF1E3A8A), // Deep Blue
                      Color(0xFF3B82F6), // Blue 500
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
                      // "Read Now" or Chevron
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Read Now',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colorScheme.primary,
                            size: 16,
                          ),
                        ],
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
