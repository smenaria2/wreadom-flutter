import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../../domain/models/book.dart';

/// Localizes category/subject terms dynamically based on current AppLocalizations locale.
String localizeCategory(String category, AppLocalizations l10n) {
  final isHindi = l10n.localeName.startsWith('hi');
  final lower = category.trim().toLowerCase();

  switch (lower) {
    case 'fantasy':
      return l10n.genreFantasy;
    case 'romance':
      return l10n.genreRomance;
    case 'science fiction':
    case 'sci-fi':
    case 'scifi':
      return l10n.genreSciFi;
    case 'mystery':
      return l10n.genreMystery;
    case 'horror':
      return l10n.genreHorror;
    case 'historical':
      return l10n.genreHistorical;
    case 'historical fiction':
      return isHindi ? 'ऐतिहासिक' : 'Historical Fiction';
    case 'history':
      return l10n.genreHistory;
    case 'adventure':
      return l10n.genreAdventure;
    case 'poetry':
    case 'poem':
      return l10n.genrePoetry;
    case 'classic':
    case 'classics':
      return l10n.genreClassic;
    case 'social':
      return l10n.genreSocial;
    case 'stories':
    case 'short story':
    case 'short stories':
      return l10n.genreStories;
    case 'biography':
    case 'autobiography':
      return l10n.genreBiography;
    case 'philosophy':
      return l10n.genrePhilosophy;
    case 'other':
      return l10n.genreOther;
  }

  if (isHindi) {
    const hindiMap = {
      'thriller': 'थ्रिलर',
      'young adult': 'युवा साहित्य',
      'literary fiction': 'साहित्यिक रचना',
      'literary': 'साहित्यिक',
      'comedy': 'हास्य',
      'humor': 'हास्य',
      'drama': 'नाटक',
      'crime': 'अपराध',
      'fan fiction': 'फैन फिक्शन',
      'lyrical': 'गीत',
      'narrative': 'आख्यान',
      'haiku': 'हाइकु',
      'free verse': 'मुक्त छंद',
      'sonnet': 'सोनेट',
      'ghazal': 'गज़ल',
      'blank verse': 'अतुकान्त कविता',
      'ode': 'प्रगीत',
      'elegy': 'शोकगीत',
      'ballad': 'गाथागीत',
      'prose poetry': 'गद्य काव्य',
      'spoken word': 'स्पोकन वर्ड',
      'visual poetry': 'दृश्य काव्य',
      'acrostic': 'एक्रोस्टिक',
      'experimental': 'प्रयोगात्मक',
      'technology': 'तकनीक',
      'tech': 'तकनीक',
      'science': 'विज्ञान',
      'health': 'स्वास्थ्य',
      'education': 'शिक्षा',
      'business': 'व्यापार',
      'politics': 'राजनीति',
      'travel': 'यात्रा',
      'lifestyle': 'जीवनशैली',
      'personal development': 'व्यक्तिगत विकास',
      'finance': 'वित्त',
      'environment': 'पर्यावरण',
      'arts & culture': 'कला और संस्कृति',
      'arts': 'कला',
      'culture': 'संस्कृति',
      'food & cooking': 'खान-पान',
      'food': 'खान-पान',
      'sports': 'खेल',
      'spiritual': 'आध्यात्मिक',
      'spirituality': 'आध्यात्म',
      'religion': 'धर्म',
      'mythology': 'पौराणिक',
    };
    if (hindiMap.containsKey(lower)) {
      return hindiMap[lower]!;
    }
  }

  return category;
}

/// Formats and resolves the content type and subtype/category string for a book.
/// e.g. "Poem • Free Verse", "Story • Thriller", "Article • Technology"
String? getBookContentTypeAndCategory(Book book, AppLocalizations l10n) {
  // 1. Resolve Content Type
  String? mainType;
  final rawContentType = book.contentType?.trim().toLowerCase();
  if (rawContentType != null && rawContentType.isNotEmpty) {
    mainType = switch (rawContentType) {
      'story' => l10n.contentTypeStory,
      'poem' => l10n.contentTypePoem,
      'article' => l10n.contentTypeArticle,
      _ => rawContentType[0].toUpperCase() + rawContentType.substring(1),
    };
  }

  bool isValidCandidate(String? candidate) {
    if (candidate == null) return false;
    final trimmed = candidate.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    if (lower == rawContentType) return false;
    if (mainType != null && lower == mainType.toLowerCase()) return false;
    if (lower == 'other' ||
        lower == 'none' ||
        lower == 'uncategorized' ||
        lower == 'general') {
      return false;
    }
    return true;
  }

  // 2. Resolve Sub-type / Category / Topic by searching subjects and topics
  String? subType;
  for (final subject in book.subjects) {
    final candidate = subject.trim();
    if (isValidCandidate(candidate)) {
      subType = localizeCategory(candidate, l10n);
      break;
    }
  }

  if (subType == null && book.topics != null) {
    for (final topic in book.topics!) {
      final candidate = topic.trim();
      if (isValidCandidate(candidate)) {
        subType = localizeCategory(candidate, l10n);
        break;
      }
    }
  }

  // 3. Combine into final display string
  if (mainType != null && subType != null) {
    if (mainType.toLowerCase() == subType.toLowerCase()) {
      return mainType;
    }
    return '$mainType • $subType';
  } else if (mainType != null) {
    return mainType;
  } else if (subType != null) {
    return subType;
  }
  return null;
}

/// Widget displaying the content type and sub-type label above author name.
class BookContentTypeLabel extends StatelessWidget {
  final Book book;
  final TextStyle? style;

  const BookContentTypeLabel({
    super.key,
    required this.book,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    final label = getBookContentTypeAndCategory(book, l10n);
    if (label == null || label.isEmpty) {
      return const SizedBox.shrink();
    }

    final defaultStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.76),
      height: 1.15,
    );

    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style ?? defaultStyle,
    );
  }
}

/// Badge widget displayed on top-right of cover when a book is a series (> 1 chapter).
class BookChapterBadge extends StatelessWidget {
  final int chapterCount;

  const BookChapterBadge({super.key, required this.chapterCount});

  @override
  Widget build(BuildContext context) {
    if (chapterCount <= 1) return const SizedBox.shrink();

    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.collections_bookmark_rounded,
                size: 10,
                color: Colors.white,
              ),
              const SizedBox(width: 3),
              Text(
                '$chapterCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge widget displayed on top-left of cover when average rating is present.
class BookRatingBadge extends StatelessWidget {
  final double rating;

  const BookRatingBadge({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();

    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 11,
                color: Colors.amber,
              ),
              const SizedBox(width: 2),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay stack container for cover badges:
/// - Top-Left: Rating Badge & Leaf Badge
/// - Top-Right: Chapter Count Badge (Series)
class BookCoverBadgesOverlay extends StatelessWidget {
  final Book book;
  final Widget child;

  const BookCoverBadgesOverlay({
    super.key,
    required this.book,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final chapterCount = book.chapterCount ?? book.chapters?.length ?? 0;
    final isSeries = chapterCount > 1;
    final rating = book.averageRating ?? 0.0;
    final hasRating = rating > 0;
    final hasLeaves = book.hasLeaves == true || (book.leafCount ?? 0) > 0;

    if (!isSeries && !hasRating && !hasLeaves) {
      return child;
    }

    final scheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        // Top-Right: Series Chapter Count Badge
        if (isSeries)
          Positioned(
            right: 6,
            top: 6,
            child: BookChapterBadge(chapterCount: chapterCount),
          ),
        // Top-Left: Rating Badge and/or Leaf Badge
        if (hasRating || hasLeaves)
          Positioned(
            left: 6,
            top: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasRating) BookRatingBadge(rating: rating),
                if (hasRating && hasLeaves) const SizedBox(width: 4),
                if (hasLeaves)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.94),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.surface.withValues(alpha: 0.86),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.eco_rounded,
                        size: 11,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
