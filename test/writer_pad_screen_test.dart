import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/domain/models/chapter.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';
import 'package:librebook_flutter/src/domain/repositories/writer_repository.dart';
import 'package:librebook_flutter/src/data/services/writer_draft_service.dart';
import 'package:librebook_flutter/src/presentation/providers/auth_providers.dart';
import 'package:librebook_flutter/src/presentation/providers/writer_providers.dart';
import 'package:librebook_flutter/src/presentation/screens/writer_pad_screen.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('writer-pad-test-');
    Hive.init(hiveDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  const testUser = UserModel(
    id: 'user-1',
    username: 'writer',
    email: 'writer@example.com',
    displayName: 'Writer',
    readingHistory: [],
    savedBooks: [],
    bookmarks: [],
  );

  Book testBook({
    required String status,
    int chapterCount = 1,
    String id = 'book-1',
  }) {
    return Book(
      id: id,
      title: 'Test Book',
      description: 'A test book',
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
      chapters: List.generate(
        chapterCount,
        (index) => Chapter(
          id: 'chapter-${index + 1}',
          title: 'Chapter ${index + 1}',
          content: '<p>Chapter ${index + 1} content</p>',
          index: index,
        ),
      ),
      status: status,
      createdAt: 1,
      updatedAt: 1,
      topics: const ['magic'],
      chapterCount: chapterCount,
    );
  }

  Widget writerPadTestApp(
    Book book, {
    Future<bool> Function(Uri uri)? openPrintPage,
    WriterRepository? writerRepository,
    WriterDraftStore? writerDraftStore,
    bool restoreLocalDrafts = false,
  }) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(testUser)),
        if (writerRepository != null)
          writerRepositoryProvider.overrideWithValue(writerRepository),
        if (writerDraftStore != null)
          writerDraftServiceProvider.overrideWithValue(writerDraftStore),
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
          restoreLocalDrafts: restoreLocalDrafts,
          showToolbar: false,
          openPrintPage: openPrintPage,
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

  testWidgets('single chapter draft shows save, next, and draft menu', (
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
            restoreLocalDrafts: false,
            showToolbar: false,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byTooltip('Save Draft'), findsOneWidget);
    expect(find.byIcon(Icons.save_rounded), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byIcon(Icons.save_rounded),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Next'),
        matching: find.byType(OutlinedButton),
      ),
      findsOneWidget,
    );
    expect(find.text('Publish'), findsNothing);
    expect(find.byTooltip('Chapters'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Add to book'), findsOneWidget);
    expect(find.text('Delete Book'), findsOneWidget);

    await tester.tap(find.text('Delete Book'));
    await tester.pumpAndSettle();
    expect(find.text('This draft will be deleted.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('single published chapter shows published edit actions', (
    tester,
  ) async {
    await tester.pumpWidget(writerPadTestApp(testBook(status: 'published')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byTooltip('Save'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Publish'), findsNothing);
    expect(
      find.ancestor(
        of: find.byIcon(Icons.save_rounded),
        matching: find.byType(OutlinedButton),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.text('Next'), matching: find.byType(FilledButton)),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Convert to Draft'), findsOneWidget);
    expect(find.text('Add to book'), findsOneWidget);
    expect(find.text('Delete Book'), findsNothing);
    expect(find.text('Print'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('chapter visibility keeps at least one chapter visible', (
    tester,
  ) async {
    final repository = _FakeWriterRepository();
    await tester.pumpWidget(
      writerPadTestApp(
        testBook(status: 'published', chapterCount: 2),
        writerRepository: repository,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Chapters'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hide chapter').first);
    await tester.pumpAndSettle();

    expect(find.text('Hidden'), findsOneWidget);
    expect(find.byTooltip('Show chapter'), findsOneWidget);
    expect(find.byTooltip('Hide chapter'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide chapter'));
    await tester.pumpAndSettle();

    expect(
      find.text('A published book must keep at least one chapter visible.'),
      findsOneWidget,
    );
  });

  testWidgets('single hydrated chapter is visible and cannot be hidden', (
    tester,
  ) async {
    final repository = _FakeWriterRepository(
      authoringChapters: const [
        Chapter(
          id: 'chapter-1',
          title: 'Only chapter',
          content: '<p>Visible content</p>',
          index: 0,
          status: 'draft',
          isHidden: true,
        ),
      ],
    );
    await tester.pumpWidget(
      writerPadTestApp(
        testBook(status: 'published'),
        writerRepository: repository,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Chapters'));
    await tester.pumpAndSettle();

    expect(find.text('Hidden'), findsNothing);
    expect(find.byTooltip('Hide chapter'), findsNothing);
    expect(find.byTooltip('Show chapter'), findsNothing);
  });

  testWidgets('newer local draft restores automatically without dialog', (
    tester,
  ) async {
    final serverBook = testBook(status: 'draft', id: 'auto-restore-book');
    final localBook = serverBook.copyWith(
      title: 'Automatically restored',
      updatedAt: 100,
      chapters: const [
        Chapter(
          id: 'chapter-1',
          title: 'Restored chapter',
          content: '<p>Latest local text</p>',
          index: 0,
          isHidden: true,
        ),
      ],
    );
    final draftStore = _FakeWriterDraftStore({
      'user-1:auto-restore-book': localBook,
    });

    await tester.pumpWidget(
      writerPadTestApp(
        serverBook,
        restoreLocalDrafts: true,
        writerDraftStore: draftStore,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Restore unsaved draft?'), findsNothing);
    expect(find.text('Restored chapter'), findsOneWidget);
    await tester.tap(find.byTooltip('Chapters'));
    await tester.pumpAndSettle();
    expect(find.text('Hidden'), findsNothing);
  });

  testWidgets('stale local draft is deleted and ignored', (tester) async {
    final serverBook = testBook(
      status: 'draft',
      id: 'stale-draft-book',
    ).copyWith(updatedAt: 100);
    final staleBook = serverBook.copyWith(
      title: 'Stale local title',
      updatedAt: 50,
    );
    const draftKey = 'user-1:stale-draft-book';
    final draftStore = _FakeWriterDraftStore({draftKey: staleBook});

    await tester.pumpWidget(
      writerPadTestApp(
        serverBook,
        restoreLocalDrafts: true,
        writerDraftStore: draftStore,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Stale local title'), findsNothing);
    expect(await draftStore.getDraft(draftKey), isNull);
  });

  testWidgets('content details shows one themed action set', (tester) async {
    await tester.pumpWidget(
      writerPadTestApp(testBook(status: 'draft', chapterCount: 2)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Publish Content'),
      500,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('Content Details'), findsOneWidget);
    expect(find.text('Publish Content'), findsOneWidget);
    expect(find.text('Save Draft'), findsOneWidget);
    expect(find.byType(PopupMenuButton), findsNothing);
  });

  testWidgets('saving published content preserves status and confirms save', (
    tester,
  ) async {
    final repository = _FakeWriterRepository();
    await tester.pumpWidget(
      writerPadTestApp(
        testBook(status: 'published'),
        writerRepository: repository,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.save_rounded));
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.updatedBook?.status, 'published');
    expect(find.text('Content saved.'), findsWidgets);
    expect(find.text('Story published.'), findsNothing);
  });

  testWidgets('draft save confirms draft saved', (tester) async {
    final repository = _FakeWriterRepository();
    await tester.pumpWidget(
      writerPadTestApp(testBook(status: 'draft'), writerRepository: repository),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.save_rounded));
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.updatedBook?.status, 'draft');
    expect(find.text('Draft saved'), findsWidgets);
  });

  testWidgets('first publication confirms story published', (tester) async {
    final repository = _FakeWriterRepository();
    final draft = testBook(status: 'draft');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(testUser)),
          writerRepositoryProvider.overrideWithValue(repository),
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
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WriterPadScreen(
                      book: draft,
                      restoreLocalDrafts: false,
                      showToolbar: false,
                    ),
                  ),
                ),
                child: const Text('Open writer'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open writer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Publish Content'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Publish Content'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.updatedBook?.status, 'published');
    expect(find.text('Story published.'), findsWidgets);
    expect(find.text('Content saved.'), findsNothing);
  });

  testWidgets('multi chapter draft requires two confirmations to delete', (
    tester,
  ) async {
    await tester.pumpWidget(
      writerPadTestApp(testBook(status: 'draft', chapterCount: 2)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byTooltip('Save Draft'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Delete Book'), findsOneWidget);
    expect(find.text('Add to book'), findsNothing);

    await tester.tap(find.text('Delete Book'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this book?'), findsOneWidget);
    expect(
      find.text('This will delete the entire book and all of its chapters.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this book permanently?'), findsOneWidget);
    expect(
      find.text(
        'This action cannot be undone. You will lose all chapters of this '
        'book and their comments. You can keep this book as a draft and '
        'publish it whenever you want.',
      ),
      findsOneWidget,
    );
    expect(find.text('Keep Draft'), findsOneWidget);

    await tester.tap(find.text('Keep Draft'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('multi chapter published book opens print page', (tester) async {
    Uri? openedUri;
    await tester.pumpWidget(
      writerPadTestApp(
        testBook(status: 'published', chapterCount: 2),
        openPrintPage: (uri) async {
          openedUri = uri;
          return true;
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byTooltip('Save'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Convert to Draft'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);
    expect(find.text('Delete Book'), findsNothing);

    await tester.tap(find.text('Print'));
    await tester.pumpAndSettle();
    expect(openedUri, Uri.parse('https://publish.wreadom.in'));

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

class _FakeWriterDraftStore implements WriterDraftStore {
  _FakeWriterDraftStore([Map<String, Book>? drafts])
    : _drafts = Map<String, Book>.from(drafts ?? const {});

  final Map<String, Book> _drafts;

  @override
  Future<void> deleteDraft(String draftKey) async {
    _drafts.remove(draftKey);
  }

  @override
  Future<Book?> getDraft(String draftKey) async => _drafts[draftKey];

  @override
  Future<void> saveDraft({required String draftKey, required Book book}) async {
    _drafts[draftKey] = book;
  }
}

class _FakeWriterRepository implements WriterRepository {
  _FakeWriterRepository({this.authoringChapters = const <Chapter>[]});

  final List<Chapter> authoringChapters;
  Book? updatedBook;

  @override
  Future<String> createBook(Book book) async {
    updatedBook = book;
    return 'created-book';
  }

  @override
  Future<void> updateBook(String bookId, Book book) async {
    updatedBook = book;
  }

  @override
  Future<List<Chapter>> getAuthoringChapters(String bookId) async {
    return authoringChapters;
  }

  @override
  Future<void> deleteBook(String bookId) async {}

  @override
  Future<List<Book>> getUserBooks(
    String userId, {
    String status = 'all',
  }) async {
    return const [];
  }

  @override
  Future<List<Book>> getImportableSingleChapterDrafts(
    String userId, {
    String? excludeBookId,
  }) async {
    return const [];
  }

  @override
  Future<List<Chapter>> importSingleDraftsToBook({
    required Book targetBook,
    required List<Book> sourceDrafts,
  }) async {
    return const [];
  }

  @override
  Future<String> moveChapterToStandaloneDraft({
    required Book sourceBook,
    required Chapter chapter,
    required List<Chapter> remainingChapters,
    required String ownerUserId,
  }) async {
    return 'draft-book';
  }

  @override
  Future<void> respondToCollaborationRequest({
    required String bookId,
    required String userId,
    required bool accept,
  }) async {}
}
