import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../utils/image_proxy_utils.dart';
import '../../widgets/glass_surface.dart';
import '../generated_book_cover.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return GlassSurface(
      onTap: onBookTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 42,
                height: 58,
                child: bookCover != null && bookCover!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: optimizedImageUrl(
                          bookCover!,
                          width: 84,
                          height: 116,
                          fit: 'cover',
                        ),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (context, url, error) =>
                            GeneratedBookCover(
                          title: bookTitle,
                          author: bookAuthorName ?? '',
                          seed: bookTitle,
                          compact: true,
                        ),
                      )
                    : GeneratedBookCover(
                        title: bookTitle,
                        author: bookAuthorName ?? '',
                        seed: bookTitle,
                        compact: true,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bookTitle.isNotEmpty ? bookTitle : l10n.untitledStory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (bookAuthorName != null && bookAuthorName!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'by $bookAuthorName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (rating > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.35),
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
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
