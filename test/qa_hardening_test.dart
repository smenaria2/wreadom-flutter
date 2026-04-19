import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/presentation/components/writer/writer_book_card.dart';
import 'package:librebook_flutter/src/presentation/providers/writer_providers.dart';
import 'package:librebook_flutter/src/presentation/routing/app_router.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';

void main() {
  Book book({
    required String id,
    required String title,
    String? status,
    int? updatedAt,
  }) {
    return Book(
      id: id,
      title: title,
      authors: const [Author(name: 'Test Author')],
      subjects: const [],
      languages: const [],
      formats: const {},
      downloadCount: 0,
      mediaType: 'text',
      bookshelves: const [],
      status: status,
      updatedAt: updatedAt,
    );
  }

  test('writer draft tab includes non-published active statuses only', () {
    expect(
      writerBookMatchesTab(
        book(id: '1', title: 'Draft', status: 'draft'),
        'draft',
      ),
      isTrue,
    );
    expect(
      writerBookMatchesTab(
        book(id: '2', title: 'Pending', status: 'pending'),
        'draft',
      ),
      isTrue,
    );
    expect(
      writerBookMatchesTab(book(id: '3', title: 'Missing'), 'draft'),
      isTrue,
    );
    expect(
      writerBookMatchesTab(
        book(id: '4', title: 'Published', status: 'published'),
        'draft',
      ),
      isFalse,
    );
    expect(
      writerBookMatchesTab(
        book(id: '5', title: 'Deleted', status: 'deleted'),
        'draft',
      ),
      isFalse,
    );
  });

  testWidgets('writer book row handles long Hindi titles without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: WriterBookCard(
                book: book(
                  id: 'long',
                  title:
                      'रस्ता बदल जाता है लेकिन यह बेहद लंबा शीर्षक नहीं टूटना चाहिए',
                  status: 'published',
                  updatedAt: DateTime(2026, 4, 7).millisecondsSinceEpoch,
                ),
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Last update:'), findsOneWidget);
  });

  testWidgets('writer card uses theme surface color in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WriterBookCard(
            book: book(id: 'dark', title: 'Dark Card', status: 'draft'),
            onTap: () {},
          ),
        ),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    expect(
      card.color,
      ThemeData.dark(useMaterial3: true).colorScheme.surfaceContainerLow,
    );
  });

  test('malformed reader route returns a safe page route', () {
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRoutes.reader),
    );

    expect(route, isA<MaterialPageRoute>());
  });

  test('feed comment error message typo stays fixed', () {
    final source = File(
      'lib/src/presentation/components/feed_post_card.dart',
    ).readAsStringSync();

    expect(source, contains('Error submitting comment'));
    expect(source, isNot(contains('Error subitting comment')));
  });

  test('feed post sharing uses Wreadom canonical query link', () {
    final source = File(
      'lib/src/presentation/components/feed_post_card.dart',
    ).readAsStringSync();

    expect(source, contains('Check out this post on Wreadom'));
    expect(source, contains('AppLinkHelper.post'));
    expect(source, isNot(contains('Check out this post on Librebook')));
  });

  test('profile side menu exposes requested navigation items only', () {
    final source = File(
      'lib/src/presentation/screens/profile_screen.dart',
    ).readAsStringSync();

    for (final label in [
      'Edit Profile',
      'Theme',
      'Help',
      'Privacy Policy',
      'Terms of Use',
      'Logout',
    ]) {
      expect(source, contains(label));
    }
    for (final label in ['Competition', 'Writer Dashboard', 'Publish Book']) {
      expect(source, isNot(contains(label)));
    }
    expect(source, isNot(contains("title: 'Settings'")));
    expect(source, contains('Icons.manage_accounts_outlined'));
    expect(source, contains('Icons.menu_rounded'));
    expect(source, isNot(contains('Icons.more_vert')));
  });

  test('Flutter legal pages include copied web policy content', () {
    final source = File(
      'lib/src/presentation/routing/app_router.dart',
    ).readAsStringSync();

    expect(source, contains('Last Updated: February 20, 2026'));
    expect(source, contains('Digital Personal Data Protection Act, 2023'));
    expect(source, contains('Indian Contract Act, 1872'));
    expect(source, contains('Terms of Use'));
    expect(source, contains('Grievance Officer'));
  });

  test('book detail exposes original author profile and follow actions', () {
    final source = File(
      'lib/src/presentation/screens/book_detail_screen.dart',
    ).readAsStringSync();

    expect(source, contains('book.isOriginal'));
    expect(source, contains('AppRoutes.publicProfile'));
    expect(source, contains('PublicProfileArguments'));
    expect(source, contains('FollowButton'));
  });

  testWidgets('published writer card exposes edit button only', (tester) async {
    var opened = 0;
    var edited = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WriterBookCard(
            book: book(
              id: 'published',
              title: 'Published',
              status: 'published',
            ),
            onTap: () => opened++,
            onEditStory: () => edited++,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));

    expect(opened, 0);
    expect(edited, 1);
  });

  testWidgets('draft writer card has no side action buttons', (tester) async {
    var edited = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WriterBookCard(
            book: book(id: 'draft', title: 'Draft', status: 'draft'),
            onTap: () => edited++,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);

    await tester.tap(find.byType(WriterBookCard));
    expect(edited, 1);
  });

  test(
    'writer dashboard uses published card tap for book page and edit button for editor',
    () {
      final source = File(
        'lib/src/presentation/screens/writer_dashboard_screen.dart',
      ).readAsStringSync();

      expect(
        source,
        contains('onTap: isPublished ? openStoryPage : openEditor'),
      );
      expect(source, contains('onEditStory: isPublished ? openEditor : null'));
    },
  );

  test(
    'reader uses automatic progress instead of manual chapter bookmarks',
    () {
      final readerSource = File(
        'lib/src/presentation/screens/reader_screen.dart',
      ).readAsStringSync();
      final providerSource = File(
        'lib/src/presentation/providers/book_providers.dart',
      ).readAsStringSync();
      final repositorySource = File(
        'lib/src/data/repositories/firebase_book_repository.dart',
      ).readAsStringSync();

      expect(readerSource, isNot(contains('FutureBuilder<List<Chapter>>')));
      expect(readerSource, contains('offlineChaptersProvider(widget.book.id)'));
      expect(providerSource, contains('offlineChaptersProvider'));
      expect(providerSource, contains('getDownloadedChapters(bookId)'));
      expect(readerSource, contains('WidgetsBindingObserver'));
      expect(readerSource, contains('didChangeAppLifecycleState'));
      expect(readerSource, contains('_saveProgressSilently'));
      expect(readerSource, contains('catchError'));
      expect(readerSource, contains('RestorableInt _restorableChapterIndex'));
      expect(
        readerSource,
        contains('RestorableDouble _restorableScrollProgress'),
      );
      expect(
        readerSource,
        contains(
          "registerForRestoration(_restorableChapterIndex, 'chapter_index')",
        ),
      );
      expect(
        readerSource,
        contains(
          "registerForRestoration(_restorableScrollProgress, 'scroll_progress')",
        ),
      );
      expect(readerSource, contains('_flushProgressSave'));
      expect(readerSource, contains('jumpTo'));
      expect(readerSource, isNot(contains('Icons.bookmark_add_outlined')));
      expect(readerSource, isNot(contains('Add Bookmark')));
      expect(readerSource, isNot(contains('bookmarkRepositoryProvider')));
      expect(readerSource, contains('Next Chapter'));
      expect(readerSource, contains('View Comments'));
      expect(readerSource, contains('ref.invalidate(currentUserProvider)'));
      expect(repositorySource, contains("'readingProgress': {"));
      expect(repositorySource, contains('SetOptions(merge: true)'));
      expect(repositorySource, isNot(contains("'readingProgress.\$bookId'")));
    },
  );

  test('reader drawer shows chapter completion and comment actions', () {
    final readerSource = File(
      'lib/src/presentation/screens/reader_screen.dart',
    ).readAsStringSync();
    final repositorySource = File(
      'lib/src/data/repositories/firebase_book_repository.dart',
    ).readAsStringSync();

    expect(readerSource, contains('completedChapterIndexes'));
    expect(readerSource, contains('_markChapterCompleteAndGoNext'));
    expect(
      readerSource,
      contains('completedChapterIndex: currentChapterIndex'),
    );
    expect(readerSource, contains('commentCounts'));
    expect(readerSource, contains('View chapter comments'));
    expect(readerSource, contains('Icons.chat_bubble_outline_rounded'));
    expect(readerSource, contains('Icons.check_rounded'));
    expect(readerSource, contains('onOpenComments'));
    expect(repositorySource, contains('completedChapterIndexes'));
  });

  test('book detail reads progress through shared progress helper', () {
    final source = File(
      'lib/src/presentation/screens/book_detail_screen.dart',
    ).readAsStringSync();

    expect(source, contains('_progressForBook'));
    expect(source, contains("'Continue Reading'"));
    expect(source, contains("'Start Reading'"));
  });

  test('optional polish stays in low-risk scope', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final writerPadSource = File(
      'lib/src/presentation/screens/writer_pad_screen.dart',
    ).readAsStringSync();
    final readerSource = File(
      'lib/src/presentation/screens/reader_screen.dart',
    ).readAsStringSync();
    final readerSettingsSource = File(
      'lib/src/presentation/providers/reader_settings_provider.dart',
    ).readAsStringSync();
    final writerTaxonomySource = File(
      'lib/src/presentation/providers/writer_taxonomy_provider.dart',
    ).readAsStringSync();
    final feedPostSource = File(
      'lib/src/presentation/components/feed_post_card.dart',
    ).readAsStringSync();
    final postDetailSource = File(
      'lib/src/presentation/screens/post_detail_screen.dart',
    ).readAsStringSync();
    final followSource = File(
      'lib/src/presentation/widgets/follow_button.dart',
    ).readAsStringSync();
    final replySheetSource = File(
      'lib/src/presentation/components/book/comment_reply_sheet.dart',
    ).readAsStringSync();
    final archiveSource = File(
      'lib/src/data/services/archive_book_service.dart',
    ).readAsStringSync();

    expect(mainSource, contains("restorationScopeId: 'wreadom_app'"));
    expect(writerPadSource, contains('RestorationMixin'));
    expect(writerPadSource, contains('RestorableTextEditingController'));
    expect(writerPadSource, contains('RestorableString _restorableContentType'));
    expect(writerPadSource, contains('writerTaxonomyProvider'));
    expect(writerPadSource, contains('wordCountFromHtml'));
    expect(writerPadSource, isNot(contains('_categoriesByType')));
    expect(
      writerPadSource,
      isNot(
        contains(
          'plainTextFromHtml(htmlFromDocument(_chapters[i].controller.document))',
        ),
      ),
    );
    expect(readerSource, contains('readerSettingsControllerProvider'));
    expect(readerSource, isNot(contains('SharedPreferences.getInstance')));
    expect(readerSettingsSource, contains('reader_font_size'));
    expect(readerSettingsSource, contains('reader_theme_index'));
    expect(readerSettingsSource, contains('reader_font_index'));
    expect(writerTaxonomySource, contains('WriterTaxonomy'));
    expect(writerTaxonomySource, contains('Arabic'));

    for (final source in [
      feedPostSource,
      postDetailSource,
      readerSource,
      replySheetSource,
    ]) {
      expect(source, contains('RestorationMixin'));
      expect(source, contains('RestorableTextEditingController'));
      expect(source, contains('HapticFeedback.lightImpact()'));
    }

    expect(feedPostSource, contains('HapticFeedback.lightImpact()'));
    expect(readerSource, contains('HapticFeedback.selectionClick()'));
    expect(followSource, contains('HapticFeedback.mediumImpact()'));
    expect(archiveSource, contains('compute('));
    expect(archiveSource, contains('_parseArchiveTextToChaptersOnIsolate'));
    expect(archiveSource, contains('ArchiveBookService()._parseTextToChapters'));
  });

  test('routing handles relative web links before showing not found', () {
    final routerSource = File(
      'lib/src/presentation/routing/app_router.dart',
    ).readAsStringSync();
    final manifestSource = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(routerSource, contains('_resolveIncomingName(name)'));
    expect(routerSource, contains('AppLinkHelper.resolve(name)'));
    expect(routerSource, contains("'\${uri.path}?\${uri.query}'"));
    expect(routerSource, contains('uri.hasFragment'));
    expect(routerSource, isNot(contains('_legacyOnGenerateRoute')));
    expect(
      manifestSource,
      contains('android:enableOnBackInvokedCallback="false"'),
    );
  });

  test('home books screen keeps priority two hardening in place', () {
    final source = File(
      'lib/src/presentation/screens/home_books_screen.dart',
    ).readAsStringSync();

    expect(source, contains('_HomeShelfDestination'));
    expect(source, contains('_openShelfDestination'));
    expect(source, contains('_SectionError'));
    expect(source, contains('onRetry'));
    expect(source, contains('_initialForName'));
    expect(source, isNot(contains('name.characters.first')));
    expect(source, isNot(contains('authorName.characters.first')));
    expect(source, contains("heroTag: 'book-cover-\$shelfId-\${book.id}'"));
    expect(
      source,
      isNot(contains("heroTag: 'book-cover-\$shelfId-\${book.id}-\$index'")),
    );
  });

  test('priority four responsive and theme polish stays in place', () {
    final homeSource = File(
      'lib/src/presentation/screens/home_books_screen.dart',
    ).readAsStringSync();
    final writerPadSource = File(
      'lib/src/presentation/screens/writer_pad_screen.dart',
    ).readAsStringSync();

    expect(homeSource, contains('AnimatedBuilder'));
    expect(homeSource, contains('_buildIndicator(index, page.toDouble())'));
    expect(homeSource, contains('constraints.maxWidth'));
    expect(homeSource, isNot(contains('height: 260')));
    expect(homeSource, isNot(contains('height: 210')));
    expect(homeSource, isNot(contains('setState(() {})')));
    expect(writerPadSource, contains('_writerChromeColor'));
    expect(writerPadSource, contains('_writerSurfaceColor'));
    expect(writerPadSource, contains('_writerPaperColor'));
    expect(writerPadSource, isNot(contains('Color(0xFF111018)')));
    expect(writerPadSource, isNot(contains('Color(0xFF191722)')));
    expect(writerPadSource, isNot(contains('Color(0xFF1D1A25)')));
    expect(writerPadSource, isNot(contains('Color(0xFF14121B)')));
  });
}
