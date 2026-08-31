import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../domain/models/comment.dart';
import '../../../utils/image_proxy_utils.dart';

/// Finds the top or latest review/comment for a specific chapter.
Comment? findTopChapterReview(
  List<Comment>? allComments, {
  required String? chapterId,
  required int chapterIndex,
  List<dynamic>? chapters,
}) {
  if (allComments == null || allComments.isEmpty) return null;

  final chapterComments = allComments.where((c) {
    if (c.text.trim().isEmpty) return false;

    // Check by chapterId
    if (chapterId != null &&
        chapterId.isNotEmpty &&
        c.chapterId != null &&
        c.chapterId!.isNotEmpty) {
      if (c.chapterId == chapterId) return true;
    }

    // Check by chapterIndex
    if (c.chapterIndex != null && c.chapterIndex == chapterIndex) {
      return true;
    }

    // Match chapterId to index in chapters list
    if (chapters != null &&
        c.chapterId != null &&
        c.chapterId!.isNotEmpty) {
      final foundIdx = chapters.indexWhere(
        (ch) => ch != null && ch.id == c.chapterId,
      );
      if (foundIdx == chapterIndex) return true;
    }

    return false;
  }).toList();

  if (chapterComments.isEmpty) return null;

  // Sorting hierarchy:
  // 1. Highlighted by author/admin
  // 2. Reviews with rating
  // 3. Highest likes
  // 4. Most recent
  chapterComments.sort((a, b) {
    final aHigh = a.isHighlighted == true ? 1 : 0;
    final bHigh = b.isHighlighted == true ? 1 : 0;
    if (aHigh != bHigh) return bHigh.compareTo(aHigh);

    final aHasRating = (a.rating != null && a.rating! > 0) ? 1 : 0;
    final bHasRating = (b.rating != null && b.rating! > 0) ? 1 : 0;
    if (aHasRating != bHasRating) return bHasRating.compareTo(aHasRating);

    final aLikes = a.likesCount ?? a.likes?.length ?? 0;
    final bLikes = b.likesCount ?? b.likes?.length ?? 0;
    if (aLikes != bLikes) return bLikes.compareTo(aLikes);

    return b.timestamp.compareTo(a.timestamp);
  });

  return chapterComments.first;
}

/// A compact 2-line YouTube-style teaser card showing the top/latest
/// review at the end of a chapter. Tapping opens the review/discussion sheet.
class ChapterReviewTeaserCard extends StatelessWidget {
  final Comment? review;
  final VoidCallback onTap;
  final Color? actionColor;

  const ChapterReviewTeaserCard({
    super.key,
    required this.review,
    required this.onTap,
    this.actionColor,
  });

  String _reviewerName(Comment comment, AppLocalizations l10n) {
    for (final value in [
      comment.displayName,
      comment.penName,
      comment.username,
    ]) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return l10n.unknownAuthor;
  }

  @override
  Widget build(BuildContext context) {
    final comment = review;
    if (comment == null || comment.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final reviewer = _reviewerName(comment, l10n);
    final photoUrl = comment.userPhotoURL;
    final rating = comment.rating;
    final effectiveActionColor = actionColor ?? colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Reviewer Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: effectiveActionColor.withValues(alpha: 0.15),
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(
                          optimizedImageUrl(
                            photoUrl,
                            width: 64,
                            height: 64,
                            fit: 'cover',
                          ),
                        )
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Text(
                          reviewer.isNotEmpty ? reviewer.characters.first.toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: effectiveActionColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                // Reviewer Name & 2-line Review Snippet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              reviewer,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (rating != null && rating > 0) ...[
                            const SizedBox(width: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 13,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toDouble().toStringAsFixed(1),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Colors.amber[800] ?? Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        comment.text.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          height: 1.35,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
