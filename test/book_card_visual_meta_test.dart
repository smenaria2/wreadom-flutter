import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/components/book/book_card_meta_tags.dart';
import 'package:librebook_flutter/src/presentation/components/book/book_card_metrics_row.dart';

Book _book({
  String? contentType = 'poem',
  List<String> subjects = const ['Free Verse'],
  int? viewCount = 1200,
  int? chapterCount,
  int? readingTimeMinutes = 2,
}) {
  return Book(
    id: 'b1',
    title: 'Title',
    authors: const [Author(name: 'Author')],
    subjects: subjects,
    languages: const ['en'],
    formats: const {},
    downloadCount: 0,
    mediaType: 'text',
    bookshelves: const [],
    viewCount: viewCount,
    contentType: contentType,
    chapterCount: chapterCount,
    readingTimeMinutes: readingTimeMinutes,
    status: 'published',
  );
}

Widget _app(Widget child, {String locale = 'en'}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(locale),
      home: Scaffold(
        body: Center(child: SizedBox(width: 120, height: 180, child: child)),
      ),
    ),
  );
}

void main() {
  group('bookContentTypeAccent', () {
    test('maps poem, story and article to distinct colors', () {
      final poem = bookContentTypeAccent('poem');
      final story = bookContentTypeAccent('story');
      final article = bookContentTypeAccent('article');

      expect(poem, isNotNull);
      expect(story, isNotNull);
      expect(article, isNotNull);
      expect({poem, story, article}.length, 3);
    });

    test('is case/whitespace insensitive and null for unknown types', () {
      expect(bookContentTypeAccent(' Poem '), bookContentTypeAccent('poem'));
      expect(bookContentTypeAccent('novel'), isNull);
      expect(bookContentTypeAccent(''), isNull);
      expect(bookContentTypeAccent(null), isNull);
    });
  });

  group('BookCoverBadgesOverlay', () {
    testWidgets('shows views badge and accent bar for a poem', (tester) async {
      await tester.pumpWidget(
        _app(
          BookCoverBadgesOverlay(
            book: _book(viewCount: 1200),
            child: const ColoredBox(color: Colors.grey),
          ),
        ),
      );

      expect(find.byType(BookViewsBadge), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.text('1.2K'), findsOneWidget);

      final accent = bookContentTypeAccent('poem')!;
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == accent,
        ),
        findsOneWidget,
      );
    });

    testWidgets('hides views badge when there are no views', (tester) async {
      await tester.pumpWidget(
        _app(
          BookCoverBadgesOverlay(
            book: _book(viewCount: 0),
            child: const ColoredBox(color: Colors.grey),
          ),
        ),
      );

      expect(find.byType(BookViewsBadge), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('keeps series chapter badge and no accent for unknown type', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          BookCoverBadgesOverlay(
            book: _book(contentType: null, chapterCount: 5, viewCount: 0),
            child: const ColoredBox(color: Colors.grey),
          ),
        ),
      );

      expect(find.byType(BookChapterBadge), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      for (final type in ['poem', 'story', 'article']) {
        final accent = bookContentTypeAccent(type)!;
        expect(
          find.byWidgetPredicate((w) => w is ColoredBox && w.color == accent),
          findsNothing,
        );
      }
    });
  });

  group('BookCardMetaLine', () {
    testWidgets('shows sub-type and read time with clock icon', (tester) async {
      await tester.pumpWidget(
        _app(BookCardMetaLine(book: _book(readingTimeMinutes: 2))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Free Verse'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.text('2 min'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('falls back to the content type when no sub-type', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          BookCardMetaLine(
            book: _book(subjects: const [], readingTimeMinutes: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Poem'), findsOneWidget);
      expect(find.text('3 min'), findsOneWidget);
    });

    testWidgets('localizes genre and read time in Hindi', (tester) async {
      await tester.pumpWidget(
        _app(
          BookCardMetaLine(book: _book(readingTimeMinutes: 3)),
          locale: 'hi',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('मुक्त छंद'), findsOneWidget);
      expect(find.text('3 मिनट'), findsOneWidget);
    });
  });

  group('resolveBookContentTypeParts', () {
    testWidgets('drops generic sub-types and keeps the wrapper format', (
      tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final withSub = resolveBookContentTypeParts(_book(), l10n);
      expect(withSub.type, 'Poem');
      expect(withSub.subType, 'Free Verse');
      expect(getBookContentTypeAndCategory(_book(), l10n), 'Poem • Free Verse');

      final generic = _book(subjects: const ['Other']);
      expect(resolveBookContentTypeParts(generic, l10n).subType, isNull);
      expect(getBookContentTypeAndCategory(generic, l10n), 'Poem');
    });
  });
}
