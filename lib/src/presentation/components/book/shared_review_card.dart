import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../domain/models/feed_post.dart';
import '../../../utils/image_proxy_utils.dart';
import '../generated_book_cover.dart';

/// A card displaying a shared book review with reviewer attribution,
/// rating, quoted review text, and embedded book info.
class SharedReviewCard extends StatelessWidget {
  final FeedPost post;
  final String bookTitle;
  final String bookAuthorName;
  final String? bookCover;
  final VoidCallback? onBookTap;
  final VoidCallback? onReviewerTap;

  const SharedReviewCard({
    super.key,
    required this.post,
    required this.bookTitle,
    required this.bookAuthorName,
    this.bookCover,
    this.onBookTap,
    this.onReviewerTap,
  });

  String _resolveReviewerName(FeedPost post, AppLocalizations l10n) {
    for (final value in [
      post.targetUserDisplayName,
      post.targetUserPenName,
      post.targetUsername,
    ]) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return l10n.unknownAuthor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final reviewerName = _resolveReviewerName(post, l10n);
    final reviewerPhoto = post.targetUserPhotoURL;
    final rating = post.rating ?? 0;
    final quoteText = (post.quote ?? post.text).trim();
    final chapterTitle = post.chapterTitle?.trim();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Header: Reviewer attribution & rating ───
          InkWell(
            onTap: onReviewerTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.07),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.amber.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.amber.withValues(alpha: 0.2),
                    backgroundImage: reviewerPhoto != null && reviewerPhoto.isNotEmpty
                        ? CachedNetworkImageProvider(
                            optimizedImageUrl(
                              reviewerPhoto,
                              width: 80,
                              height: 80,
                              fit: 'cover',
                            ),
                          )
                        : null,
                    child: reviewerPhoto == null || reviewerPhoto.isEmpty
                        ? Text(
                            reviewerName.isNotEmpty
                                ? reviewerName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900] ?? Colors.amber,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${l10n.reviewedBy} ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                reviewerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (rating > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            rating.toDouble().toStringAsFixed(1),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.amber[900] ?? Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Quoted Review Text ───
          if (quoteText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '“',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 32,
                      height: 0.8,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      quoteText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ─── Embedded Book Row ───
          InkWell(
            onTap: onBookTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 40,
                      height: 56,
                      child: bookCover != null && bookCover!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: optimizedImageUrl(
                                bookCover!,
                                width: 80,
                                height: 112,
                                fit: 'cover',
                              ),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: colorScheme.surfaceContainerHighest,
                              ),
                              errorWidget: (context, url, error) =>
                                  GeneratedBookCover(
                                title: bookTitle,
                                author: bookAuthorName,
                                seed: post.bookId?.toString() ?? bookTitle,
                                compact: true,
                              ),
                            )
                          : GeneratedBookCover(
                              title: bookTitle,
                              author: bookAuthorName,
                              seed: post.bookId?.toString() ?? bookTitle,
                              compact: true,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookTitle.isNotEmpty
                              ? bookTitle
                              : l10n.untitledStory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (bookAuthorName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'by $bookAuthorName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (chapterTitle != null && chapterTitle.isNotEmpty) ...[
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
                                  chapterTitle,
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
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
