import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../utils/image_proxy_utils.dart';
import '../../widgets/glass_surface.dart';
import '../generated_book_cover.dart';

class GradientBookCard extends StatelessWidget {
  final String bookTitle;
  final String? bookCover;
  final String? bookAuthorName;
  final String? chapterTitle;
  final VoidCallback? onBookTap;

  const GradientBookCard({
    super.key,
    required this.bookTitle,
    this.bookCover,
    this.bookAuthorName,
    this.chapterTitle,
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
                  if (chapterTitle != null && chapterTitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 11,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            chapterTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
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
