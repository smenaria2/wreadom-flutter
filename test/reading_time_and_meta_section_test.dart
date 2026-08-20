import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/domain/models/chapter.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/components/book/book_card_metrics_row.dart';
import 'package:librebook_flutter/src/presentation/components/book/book_detail_meta_section.dart';
import 'package:librebook_flutter/src/utils/reading_time_utils.dart';

Book _testBook({
  String id = 'test-book-1',
  String title = 'Test Book Title',
  int? viewCount = 159,
  double? averageRating = 4.8,
  int? ratingsCount = 29,
  String? contentType = 'story',
  int? chapterCount = 7,
  int? publishedAt = 1787040000000,
  List<Chapter>? chapters,
}) {
  return Book(
    id: id,
    title: title,
    authors: const [Author(name: 'Test Author')],
    subjects: const ['Fiction'],
    languages: const ['en'],
    formats: const {},
    downloadCount: 50,
    mediaType: 'text',
    bookshelves: const [],
    viewCount: viewCount,
    averageRating: averageRating,
    ratingsCount: ratingsCount,
    contentType: contentType,
    chapterCount: chapterCount,
    publishedAt: publishedAt,
    status: 'published',
    chapters: chapters,
  );
}

void main() {
  group('Reading time utility tests', () {
    test('Calculates reading time accurately from chapter words', () {
      final book = _testBook(
        chapters: [
          const Chapter(
            id: 'c1',
            title: 'Chapter 1',
            content: '<p>This is a test chapter with ten simple sample words here.</p>',
            index: 0,
          ),
          Chapter(
            id: 'c2',
            title: 'Chapter 2',
            content: List.generate(400, (i) => 'word$i').join(' '),
            index: 1,
          ),
        ],
      );

      final mins = estimateBookReadingTimeMinutes(book);
      // 10 words + 400 words = 410 words -> 410 / 200 = 2.05 -> ceil = 3 mins
      expect(mins, 3);
    });

    test('Formats compact reading time correctly in English and Hindi', () async {
      expect(formatCompactReadingTime(1), '1 min');
      expect(formatCompactReadingTime(5), '5 min');
      expect(formatCompactReadingTime(60), '1h');
      expect(formatCompactReadingTime(75), '1h 15m');
      expect(formatCompactReadingTime(130), '2h 10m');

      final l10nHi = await AppLocalizations.delegate.load(const Locale('hi'));
      expect(formatCompactReadingTime(1, l10n: l10nHi), '1 मिनट');
      expect(formatCompactReadingTime(5, l10n: l10nHi), '5 मिनट');
      expect(formatCompactReadingTime(60, l10n: l10nHi), '1 घंटे');
      expect(formatCompactReadingTime(75, l10n: l10nHi), '1 घंटे 15 मिनट');
    });

    test('Formats detail reading time in English', () async {
      final l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
      expect(formatDetailReadingTime(5, l10n: l10nEn), '5 min read');
      expect(formatDetailReadingTime(60, l10n: l10nEn), '1 hr read');
      expect(formatDetailReadingTime(75, l10n: l10nEn), '1 hr 15 min read');
    });

    test('Formats detail reading time in Hindi without का पाठ', () async {
      final l10nHi = await AppLocalizations.delegate.load(const Locale('hi'));
      expect(formatDetailReadingTime(5, l10n: l10nHi), '5 मिनट');
      expect(formatDetailReadingTime(60, l10n: l10nHi), '1 घंटे');
      expect(formatDetailReadingTime(75, l10n: l10nHi), '1 घंटे 15 मिनट');
    });
  });

  group('BookCardMetricsRow Widget Tests', () {
    testWidgets('Renders eye icon, reads count, clock icon, and compact read time in one line (English)', (tester) async {
      final book = _testBook(
        viewCount: 159,
        chapterCount: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: BookCardMetricsRow(book: book),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.text('159'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.text('9 min'), findsOneWidget);
    });

    testWidgets('Renders compact read time in Hindi when locale is Hindi', (tester) async {
      final book = _testBook(
        viewCount: 19,
        chapterCount: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('hi'),
          home: Scaffold(
            body: BookCardMetricsRow(book: book),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.text('19'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.text('3 मिनट'), findsOneWidget);
    });
  });

  group('BookDetailMetaSection Widget Tests', () {
    testWidgets('Renders all 6 metadata elements cleanly', (tester) async {
      final book = _testBook(
        viewCount: 159,
        averageRating: 5.0,
        ratingsCount: 29,
        contentType: 'story',
        chapterCount: 7,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: BookDetailMetaSection(book: book),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Rating
      expect(find.text('5.0 (29)'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);

      // Reads
      expect(find.text('159 reads'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Reading time
      expect(find.text('21 min read'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);

      // Content type
      expect(find.text('Story'), findsOneWidget);
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);

      // Chapters
      expect(find.text('7 chapters'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);

      // Published date
      expect(find.textContaining('Published:'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });
  });
}
