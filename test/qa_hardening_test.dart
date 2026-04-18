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
      final repositorySource = File(
        'lib/src/data/repositories/firebase_book_repository.dart',
      ).readAsStringSync();

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
}
