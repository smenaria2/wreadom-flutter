import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/domain/models/chapter.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';
import 'package:librebook_flutter/src/presentation/providers/auth_providers.dart';
import 'package:librebook_flutter/src/presentation/routing/writer_pad_mode.dart';
import 'package:librebook_flutter/src/presentation/screens/writer_pad_screen.dart';

void main() {
  const testUser = UserModel(
    id: 'user-1',
    username: 'writer',
    email: 'writer@example.com',
    displayName: 'Writer',
    readingHistory: [],
    savedBooks: [],
    bookmarks: [],
  );

  Widget writerPadTestApp(Book book) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(testUser)),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: WriterPadScreen(
          book: book,
          restoreLocalDrafts: false,
          showToolbar: false,
        ),
      ),
    );
  }

  testWidgets('WriterPad renders rich html content without literal tags', (
    tester,
  ) async {
    final book = Book(
      id: 'book-1',
      title: 'Rich Draft',
      description: 'A test draft',
      authors: const [Author(name: 'Author')],
      subjects: const ['Fantasy'],
      languages: const ['en'],
      formats: const {},
      downloadCount: 0,
      mediaType: 'text',
      bookshelves: const [],
      source: 'firestore',
      isOriginal: true,
      contentType: 'story',
      authorId: 'user-1',
      chapters: const [
        Chapter(
          id: 'chapter-1',
          title: 'Opening',
          content: '<p><strong>Hello</strong> from the story</p>',
          index: 0,
        ),
      ],
      status: 'draft',
      createdAt: 1,
      updatedAt: 1,
      topics: const ['magic'],
      chapterCount: 1,
    );

    await tester.pumpWidget(writerPadTestApp(book));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Writing Editor'), findsOneWidget);
    expect(find.text('Opening'), findsOneWidget);
    expect(find.textContaining('Hello', findRichText: true), findsWidgets);
    expect(find.textContaining('<strong>'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('chapter draft mode shows simple draft actions only', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(testUser)),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WriterPadScreen(
            mode: WriterPadMode.chapterDraft,
            restoreLocalDrafts: false,
            showToolbar: false,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Save Draft'), findsOneWidget);
    expect(find.text('Add to book'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Publish'), findsNothing);
    expect(find.byTooltip('Chapters'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'WriterPad shows version history and restores a rich chapter version',
    (tester) async {
      const image =
          'https://res.cloudinary.com/demo/image/upload/f_auto/sample.jpg';
      const media = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      final book = Book(
        id: 'book-1',
        title: 'Versioned Draft',
        description: 'A test draft',
        authors: const [Author(name: 'Author')],
        subjects: const ['Fantasy'],
        languages: const ['en'],
        formats: const {},
        downloadCount: 0,
        mediaType: 'text',
        bookshelves: const [],
        source: 'firestore',
        isOriginal: true,
        contentType: 'story',
        authorId: 'user-1',
        chapters: const [
          Chapter(
            id: 'chapter-1',
            title: 'Opening',
            content: '<p>Current text in the editor</p>',
            index: 0,
            versions: [
              ChapterVersion(
                content:
                    '<h2>Older rich text from history</h2>'
                    '<p><strong>Bold restored text</strong></p>'
                    '<p><img src="$image"></p>'
                    '<p><a href="$media">YouTube</a></p>',
                timestamp: 1234,
                wordCount: 8,
              ),
            ],
          ),
        ],
        status: 'draft',
        createdAt: 1,
        updatedAt: 1,
        topics: const ['magic'],
        chapterCount: 1,
      );

      await tester.pumpWidget(writerPadTestApp(book));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byTooltip('Chapters'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Version history'));
      await tester.pumpAndSettle();

      expect(find.text('Version history'), findsOneWidget);
      expect(
        find.textContaining('Older rich text from history'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Restore').last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Older rich text from history', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('Bold restored text', findRichText: true),
        findsWidgets,
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
