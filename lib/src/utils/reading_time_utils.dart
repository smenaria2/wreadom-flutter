import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../domain/models/book.dart';
import '../domain/models/chapter.dart';

/// Average reading speed in words per minute.
const int _wordsPerMinute = 200;

/// Estimates reading time in minutes for a book from chapter contents,
/// description, or chapter count.
int estimateBookReadingTimeMinutes(Book book, {List<Chapter>? chapters}) {
  final candidateChapters = (chapters != null && chapters.isNotEmpty)
      ? chapters
      : book.chapters;

  if (candidateChapters != null && candidateChapters.isNotEmpty) {
    int totalWords = 0;
    for (final chapter in candidateChapters) {
      if (chapter.content.trim().isNotEmpty) {
        totalWords += countWords(chapter.content);
      }
    }
    if (totalWords > 0) {
      final calculated = (totalWords / _wordsPerMinute).ceil();
      return calculated < 1 ? 1 : calculated;
    }
  }

  // Fallback 1: Calculate from book description if present
  if (book.description != null && book.description!.trim().isNotEmpty) {
    final descWords = countWords(book.description!);
    if (descWords > 0) {
      final calculated = (descWords / _wordsPerMinute).ceil();
      if (calculated > 0) return calculated;
    }
  }

  // Fallback 2: Estimate based on chapter count (~3 minutes per chapter average)
  final chapterCount = book.chapterCount ?? book.chapters?.length ?? 1;
  if (chapterCount > 0) {
    return (chapterCount * 3).clamp(1, 99999);
  }

  return 1;
}

/// Counts words in a string by removing HTML markup and splitting on whitespace.
int countWords(String text) {
  if (text.trim().isEmpty) return 0;
  final plain = text.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').trim();
  if (plain.isEmpty) return 0;
  return RegExp(r'\S+').allMatches(plain).length;
}

/// Formats reading time concisely for cards (e.g. "5 min", "1h", "1h 15m" / "5 मिनट").
String formatCompactReadingTime(int minutes, {AppLocalizations? l10n}) {
  final safeMinutes = minutes < 1 ? 1 : minutes;

  if (l10n != null) {
    if (safeMinutes < 60) {
      return l10n.compactReadingTimeMinutes(safeMinutes);
    }
    final hours = safeMinutes ~/ 60;
    final remainingMinutes = safeMinutes % 60;
    if (remainingMinutes == 0) {
      return l10n.compactReadingTimeHoursOnly(hours);
    }
    return l10n.compactReadingTimeHours(hours, remainingMinutes);
  }

  if (safeMinutes <= 1) return '1 min';
  if (safeMinutes < 60) return '$safeMinutes min';

  final hours = safeMinutes ~/ 60;
  final remainingMinutes = safeMinutes % 60;
  if (remainingMinutes == 0) {
    return '${hours}h';
  }
  return '${hours}h ${remainingMinutes}m';
}

/// Formats reading time for book detail screen with localization support.
String formatDetailReadingTime(int minutes, {AppLocalizations? l10n}) {
  final safeMinutes = minutes < 1 ? 1 : minutes;

  if (l10n != null) {
    if (safeMinutes < 60) {
      return l10n.readingTimeMinutes(safeMinutes);
    }
    final hours = safeMinutes ~/ 60;
    final remainingMinutes = safeMinutes % 60;
    if (remainingMinutes == 0) {
      return l10n.readingTimeHoursOnly(hours);
    }
    return l10n.readingTimeHours(hours, remainingMinutes);
  }

  if (safeMinutes == 1) return '1 min read';
  if (safeMinutes < 60) return '$safeMinutes min read';

  final hours = safeMinutes ~/ 60;
  final remainingMinutes = safeMinutes % 60;
  if (remainingMinutes == 0) {
    return '$hours ${hours == 1 ? 'hr' : 'hrs'} read';
  }
  return '$hours hr $remainingMinutes min read';
}
