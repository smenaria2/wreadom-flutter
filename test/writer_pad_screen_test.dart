import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/domain/models/chapter.dart';
import 'package:librebook_flutter/src/presentation/screens/writer_pad_screen.dart';

void main() {
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

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          home: WriterPadScreen(book: book),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Writing Editor'), findsOneWidget);
    expect(find.text('Opening'), findsOneWidget);
    expect(find.textContaining('Hello', findRichText: true), findsWidgets);
    expect(find.textContaining('<strong>'), findsNothing);
  });
}
