import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/domain/models/comment.dart';
import 'package:librebook_flutter/src/presentation/components/writer/writer_book_card.dart';
import 'package:librebook_flutter/src/presentation/providers/writer_providers.dart';
import 'package:librebook_flutter/src/presentation/routing/app_router.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';

void main() {
  Map<String, dynamic> englishL10n() =>
      jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;

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
    final l10n = englishL10n();

    expect(source, contains('l10n.errorSubmittingComment'));
    expect(
      l10n['errorSubmittingComment'],
      contains('Error submitting comment'),
    );
    expect(source, isNot(contains('Error subitting comment')));
    expect(
      l10n['errorSubmittingComment'],
      isNot(contains('Error subitting comment')),
    );
  });

  test('feed post sharing uses Wreadom canonical query link', () {
    final source = File(
      'lib/src/presentation/components/feed_post_card.dart',
    ).readAsStringSync();
    final l10n = englishL10n();

    expect(source, contains('l10n.checkOutPostOnWreadom'));
    expect(
      l10n['checkOutPostOnWreadom'],
      contains('Check out this post on Wreadom'),
    );
    expect(source, contains('AppLinkHelper.post'));
    expect(source, isNot(contains('Check out this post on Librebook')));
    expect(
      l10n['checkOutPostOnWreadom'],
      isNot(contains('Check out this post on Librebook')),
    );
  });

  test('profile side menu exposes requested navigation items only', () {
    final source = File(
      'lib/src/presentation/screens/profile_screen.dart',
    ).readAsStringSync();
    final l10n = englishL10n();

    for (final key in [
      'editProfile',
      'theme',
      'submitError',
      'help',
      'privacyPolicy',
      'termsOfUse',
      'logout',
    ]) {
      expect(source, contains('l10n.$key'));
      expect(l10n[key], isA<String>());
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

  test('reader uses automatic progress instead of manual chapter bookmarks', () {
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
    expect(readerSource, contains("AppLocalizations.of(context)!.nextChapter"));
    expect(
      readerSource,
      contains("AppLocalizations.of(context)!.viewComments"),
    );
    expect(readerSource, contains('ref.invalidate(currentUserProvider)'));
    expect(repositorySource, contains("'readingProgress': {"));
    expect(repositorySource, contains('SetOptions(merge: true)'));
    expect(repositorySource, isNot(contains("'readingProgress.\$bookId'")));
  });

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
    expect(
      readerSource,
      contains("AppLocalizations.of(context)!.viewChapterComments"),
    );
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
    expect(source, contains('continueReading'));
    expect(source, contains('startReading'));
    expect(source, isNot(contains('incrementViewCount')));
    expect(source, contains('initialReaderChapterIndex'));
    expect(source, contains('_ReaderDeepLinkLauncher'));
    expect(source, contains('_hasLaunchedReader'));
    expect(source, contains('_launchReaderOnce'));
    expect(source, contains('_preloadChapters'));
    expect(source, contains('bookChaptersProvider(bookId).future'));
    expect(source, contains('offlineChaptersProvider(bookId).future'));
  });

  test(
    'book detail shows direct report or edit actions and comment ratings',
    () {
      final source = File(
        'lib/src/presentation/screens/book_detail_screen.dart',
      ).readAsStringSync();

      expect(source, contains('reportBook'));
      expect(source, contains('if (!canEdit)'));
      expect(source, isNot(contains('PopupMenuButton<String>')));
      expect(source, contains('_RatingStat'));
      expect(source, contains('bookCommentsProvider(book.id)'));
      expect(source, contains('comment.rating'));
      expect(source, contains('l10n.noRatings'));
    },
  );

  test('story comments do not require unauthorized book counter writes', () {
    final source = File(
      'lib/src/data/repositories/firebase_comment_repository.dart',
    ).readAsStringSync();

    expect(source, contains('await docRef.set(data)'));
    expect(source, isNot(contains("'commentCount': FieldValue.increment(1)")));
    expect(source, isNot(contains("'commentCount': FieldValue.increment(-1)")));
  });

  test('follow repository uses idempotent relationship writes', () {
    final source = File(
      'lib/src/data/repositories/firebase_follow_repository.dart',
    ).readAsStringSync();

    expect(source, contains('_followDocId'));
    expect(source, contains('transaction.get(followRef)'));
    expect(source, contains('if (existing.exists) return;'));
    expect(source, contains('if (deletedCount == 0) return;'));
    expect(source, contains('FieldValue.increment(-deletedCount)'));
    expect(source, isNot(contains(".collection('follows').doc(), {")));
  });

  test(
    'message repository uses deterministic direct chats and atomic sends',
    () {
      final source = File(
        'lib/src/data/repositories/firebase_message_repository.dart',
      ).readAsStringSync();

      expect(source, contains('_directConversationId'));
      expect(source, contains("return 'direct_\${ids[0]}_\${ids[1]}'"));
      expect(source, contains('runTransaction((transaction) async'));
      expect(source, contains('firstMessageSenderId'));
      expect(source, contains('recipientHasReplied'));
      expect(source, contains('_sendMessageDocument'));
      expect(source, contains('transaction.set(messageRef'));
      expect(source, contains('transaction.update(conversationRef'));
      expect(source, isNot(contains(".collection('conversations').add")));
      expect(source, isNot(contains('await _assertCanSend(')));
    },
  );

  test('profile fan-out updates are chunked below Firestore batch limits', () {
    final source = File(
      'lib/src/data/repositories/firebase_auth_repository.dart',
    ).readAsStringSync();

    expect(source, contains('_maxFanOutWritesPerBatch = 450'));
    expect(source, contains('void queueUpdate('));
    expect(
      source,
      contains('if (currentWriteCount >= _maxFanOutWritesPerBatch)'),
    );
    expect(source, contains('for (final batch in batches)'));
    expect(source, isNot(contains('final batch = _firestore.batch();')));
  });

  test(
    'feed comments use top-level comment docs instead of embedded rewrites',
    () {
      final feedSource = File(
        'lib/src/data/repositories/firebase_feed_repository.dart',
      ).readAsStringSync();
      final commentSource = File(
        'lib/src/data/repositories/firebase_comment_repository.dart',
      ).readAsStringSync();

      expect(feedSource, contains("_firestore.collection('comments').doc()"));
      expect(feedSource, contains("'feedPostId': postId"));
      expect(feedSource, contains("'commentCount': FieldValue.increment(1)"));
      expect(feedSource, contains('_addTopLevelCommentReply'));
      expect(feedSource, contains('_updateTopLevelReplies'));
      expect(
        feedSource,
        isNot(contains("'comments': [...comments, embeddedComment]")),
      );
      expect(commentSource, contains('itemsById'));
      expect(commentSource, contains("collection('comments')"));
      expect(commentSource, contains("where('feedPostId', whereIn: ids)"));
    },
  );

  test('feed comment writes do not depend on count update permission', () {
    final feedSource = File(
      'lib/src/data/repositories/firebase_feed_repository.dart',
    ).readAsStringSync();

    final setIndex = feedSource.indexOf('await commentRef.set');
    final countIndex = feedSource.indexOf(
      "'commentCount': FieldValue.increment(1)",
    );
    expect(setIndex, greaterThan(-1));
    expect(countIndex, greaterThan(setIndex));
    expect(feedSource, contains('try {'));
    expect(feedSource, contains('Comment saved but count update failed'));
  });

  test('feed actions and follow writes require signed-in ownership shapes', () {
    final feedCardSource = File(
      'lib/src/presentation/components/feed_post_card.dart',
    ).readAsStringSync();
    final postDetailSource = File(
      'lib/src/presentation/screens/post_detail_screen.dart',
    ).readAsStringSync();
    final followSource = File(
      'lib/src/data/repositories/firebase_follow_repository.dart',
    ).readAsStringSync();
    final rulesSource = File('firestore.rules').readAsStringSync();
    final firebaseConfig = File('firebase.json').readAsStringSync();

    expect(feedCardSource, contains('l10n.signInToContinueAction'));
    expect(postDetailSource, contains('l10n.signInToContinueAction'));
    expect(followSource, contains('_followDocId'));
    expect(rulesSource, contains('followerId'));
    expect(rulesSource, contains("ownsIncoming('followerId')"));
    expect(rulesSource, contains("ownsIncoming('userId')"));
    expect(rulesSource, contains("onlyChanges(['commentCount'])"));
    expect(firebaseConfig, contains('"rules": "firestore.rules"'));
  });

  test('localized feed labels and Hindi app wording stay wired', () {
    final feedCardSource = File(
      'lib/src/presentation/components/feed_post_card.dart',
    ).readAsStringSync();
    final enArb = File('lib/l10n/app_en.arb').readAsStringSync();
    final hiArb = File('lib/l10n/app_hi.arb').readAsStringSync();

    expect(feedCardSource, contains('String _typeLabel'));
    expect(feedCardSource, contains('l10n.feedTypePost'));
    expect(feedCardSource, isNot(contains('post.type[0].toUpperCase()')));
    expect(enArb, contains('"history": "Read Content"'));
    expect(hiArb, contains('"appTitle": "रीडम्"'));
    expect(hiArb, contains('"history": "पढ़ी गई रचनाएँ"'));
    expect(hiArb, isNot(contains('किताब')));
  });

  test(
    'follow lists hide handles and home author metrics use ranked works',
    () {
      final followListSource = File(
        'lib/src/presentation/screens/follow_list_screen.dart',
      ).readAsStringSync();
      final homeProviderSource = File(
        'lib/src/presentation/providers/homepage_providers.dart',
      ).readAsStringSync();
      final homeScreenSource = File(
        'lib/src/presentation/screens/home_books_screen.dart',
      ).readAsStringSync();

      expect(followListSource, isNot(contains('@\${user.username}')));
      expect(homeProviderSource, contains('homepageAuthorWorksProvider'));
      expect(
        homeProviderSource,
        contains('ratingTotal += rating * ratingsCount'),
      );
      expect(homeProviderSource, contains('works += 1'));
      expect(homeScreenSource, contains('l10n.noRatingsYet'));
      expect(homeScreenSource, contains('l10n.ratingMetric'));
      expect(homeScreenSource, contains('l10n.readsMetric'));
      expect(homeScreenSource, contains('l10n.worksMetric'));
      expect(
        homeScreenSource,
        contains('homepageAuthorBooksProvider(author.id)'),
      );
      expect(
        homeScreenSource,
        contains('homepageRankedAuthorsProvider(HomeAuthorRanking.topRated)'),
      );
    },
  );

  test(
    'shared firestore rules preserve android and web compatibility paths',
    () {
      final rulesSource = File('firestore.rules').readAsStringSync();

      expect(
        rulesSource,
        contains("function ownsIncomingAny(primary, fallback)"),
      );
      expect(
        rulesSource,
        contains("function ownsExistingAny(primary, fallback)"),
      );
      expect(rulesSource, contains("function isBookAuthor(bookId)"));
      expect(
        rulesSource,
        contains("function allowsLegacyEmbeddedFeedCommentMutation()"),
      );

      expect(
        rulesSource,
        contains("allow create: if ownsIncoming('followerId')"),
      );
      expect(rulesSource, contains("onlyChanges(['commentCount'])"));
      expect(
        rulesSource,
        contains("allowsLegacyEmbeddedFeedCommentMutation()"),
      );
      expect(
        rulesSource,
        contains("request.resource.data.highlightedByUserId == uid()"),
      );
      expect(
        rulesSource,
        contains("allow create: if ownsIncomingAny('authorId', 'userId');"),
      );
      expect(rulesSource, contains("ownsExistingAny('authorId', 'userId')"));
      expect(
        rulesSource,
        contains("request.resource.data.reporterId == uid() ||"),
      );
      expect(rulesSource, contains("request.resource.data.userId == uid()"));
    },
  );

  test('reader sharing, chrome, tts, and unique views stay wired', () {
    final readerSource = File(
      'lib/src/presentation/screens/reader_screen.dart',
    ).readAsStringSync();
    final repositorySource = File(
      'lib/src/data/repositories/firebase_book_repository.dart',
    ).readAsStringSync();

    expect(readerSource, contains('recordBookView'));
    expect(readerSource, contains('_viewerKeyForViewCount'));
    expect(readerSource, contains("'user:\$userId'"));
    expect(readerSource, contains("'anon:\$anonymousId'"));
    expect(readerSource, contains('anonymous_reader_viewer_id'));
    expect(readerSource, isNot(contains('leading: _chapterIndex == 0')));
    expect(readerSource, contains('_getAppBarBackgroundColor'));
    expect(readerSource, contains('_getAppBarForegroundColor'));
    expect(readerSource, contains('_readerBlocksForChapter'));
    expect(readerSource, contains('_buildTtsListView'));
    expect(readerSource, contains('_startTtsFromBlock'));
    expect(readerSource, contains('_ReaderTtsBlockView'));
    expect(readerSource, contains('_activeTtsBlockIndex'));
    expect(readerSource, contains('SelectionArea'));
    expect(readerSource, contains('_isTtsPlaying || _isTtsPreparing'));
    expect(readerSource, contains('AppLinkHelper.chapter'));
    expect(repositorySource, contains(".collection('views')"));
    expect(repositorySource, contains('runTransaction'));
    expect(repositorySource, contains('FieldValue.increment(1)'));
    expect(repositorySource, contains('existingView.exists'));
  });

  test(
    'reader progress is chapter-only and selection tts avoids scroll jumps',
    () {
      final readerSource = File(
        'lib/src/presentation/screens/reader_screen.dart',
      ).readAsStringSync();

      expect(readerSource, contains('_chapterContentEndKey'));
      expect(readerSource, contains('_progressScrollExtent'));
      expect(readerSource, contains('RenderAbstractViewport.maybeOf'));
      final menuStart = readerSource.indexOf('final buttonItems');
      final menuSource = readerSource.substring(menuStart);
      final shareQuoteIndex = menuSource.indexOf('Share Quote');
      final quoteCommentIndex = menuSource.indexOf('Quote & Comment');
      final readAloudIndex = menuSource.indexOf('Read aloud');
      expect(shareQuoteIndex, greaterThan(-1));
      expect(quoteCommentIndex, greaterThan(shareQuoteIndex));
      expect(readAloudIndex, greaterThan(quoteCommentIndex));
      expect(readerSource, contains('_speakSelectedText'));
      expect(readerSource, contains('_isSelectionTtsPlaying'));
      expect(readerSource, contains('_restoreScrollOffsetAfterModeSwitch'));
      expect(readerSource, contains('scrollOffset'));
      expect(readerSource, contains('_appendPlainReaderBlocks'));
      expect(readerSource, contains('_splitLongPlainTextBlock'));
      expect(readerSource, contains('Back'));
      expect(readerSource, contains('Icons.arrow_back_rounded'));
      expect(readerSource, isNot(contains('Go to book')));
      expect(readerSource, isNot(contains('BookDetailArguments')));
    },
  );

  test(
    'reader review rules enforce one rated review and author highlighting',
    () {
      final readerSource = File(
        'lib/src/presentation/screens/reader_screen.dart',
      ).readAsStringSync();
      final commentSource = File(
        'lib/src/domain/models/comment.dart',
      ).readAsStringSync();
      final repositorySource = File(
        'lib/src/data/repositories/firebase_comment_repository.dart',
      ).readAsStringSync();
      final tileSource = File(
        'lib/src/presentation/widgets/comment_widgets.dart',
      ).readAsStringSync();

      expect(commentSource, contains('isHighlighted'));
      expect(commentSource, contains('highlightedAt'));
      expect(commentSource, contains('highlightedByUserId'));
      expect(repositorySource, contains('getUserBookReview'));
      expect(repositorySource, contains('upsertBookReview'));
      expect(repositorySource, contains('toggleReviewHighlight'));
      expect(repositorySource, contains('maxHighlighted = 3'));
      expect(readerSource, contains('int _chapterRating = 5'));
      expect(readerSource, contains('_isOwnOriginalBook'));
      expect(readerSource, contains('l10n.authorsCannotReviewOwnBook'));
      expect(readerSource, contains('upsertBookReview'));
      expect(readerSource, contains('_restoreLineBreaks'));
      expect(readerSource, contains('viewInsets.bottom'));
      expect(tileSource, contains('bookAuthorId'));
      expect(tileSource, contains('PopupMenuButton<String>'));
      expect(tileSource, contains('l10n.unpin'));
      expect(tileSource, contains('Icons.push_pin'));
    },
  );

  test(
    'profile sharing uses generated card and public header matches theme',
    () {
      final profileSource = File(
        'lib/src/presentation/screens/profile_screen.dart',
      ).readAsStringSync();
      final publicProfileSource = File(
        'lib/src/presentation/screens/public_profile_screen.dart',
      ).readAsStringSync();
      final cardSource = File(
        'lib/src/presentation/components/profile/profile_share_card.dart',
      ).readAsStringSync();

      expect(profileSource, contains('Icons.share_outlined'));
      expect(publicProfileSource, contains('Icons.share_outlined'));
      expect(profileSource, contains('shareUserProfileCard'));
      expect(publicProfileSource, contains('shareUserProfileCard'));
      expect(publicProfileSource, contains('theme.colorScheme.surface'));
      expect(publicProfileSource, contains('surfaceContainerHighest'));
      expect(cardSource, contains('RepaintBoundary'));
      expect(cardSource, contains('ProfileShareCard'));
      expect(cardSource, contains('Share.shareXFiles'));
    },
  );

  test('chat surfaces open public profiles', () {
    final conversationSource = File(
      'lib/src/presentation/screens/conversation_screen.dart',
    ).readAsStringSync();

    expect(conversationSource, contains('_ConversationTitle'));
    expect(conversationSource, contains('_MessageSender'));
    expect(conversationSource, contains('AppRoutes.publicProfile'));
    expect(conversationSource, contains('PublicProfileArguments'));
    expect(conversationSource, contains('message.senderId'));
  });

  test('daily topic matching allows spaces and normalized variants', () {
    final repositorySource = File(
      'lib/src/data/repositories/firebase_book_repository.dart',
    ).readAsStringSync();

    expect(repositorySource, contains('_topicSearchTerms'));
    expect(repositorySource, contains("replaceAll(RegExp(r'\\s+'), ' ')"));
    expect(repositorySource, contains("replaceAll(' ', '_')"));
    expect(repositorySource, contains('toLowerCase()'));
  });

  test('profile error reporting captures device info and logs', () {
    final profileSource = File(
      'lib/src/presentation/screens/profile_screen.dart',
    ).readAsStringSync();
    final reportRepositorySource = File(
      'lib/src/data/repositories/firebase_report_repository.dart',
    ).readAsStringSync();
    final logCollectorSource = File(
      'lib/src/utils/app_log_collector.dart',
    ).readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(profileSource, contains('l10n.submitError'));
    expect(
      profileSource.indexOf('l10n.submitError'),
      lessThan(profileSource.indexOf('l10n.help')),
    );
    expect(profileSource, contains('_SubmitErrorDialog'));
    expect(profileSource, contains('submitErrorReport'));
    expect(profileSource, contains('deviceInfo'));
    expect(profileSource, contains('AppLogCollector.formattedLogs()'));
    expect(profileSource, contains('PackageInfo.fromPlatform()'));
    expect(profileSource, contains('l10n.mustBeLoggedInToSubmitIssues'));
    expect(reportRepositorySource, contains('submitErrorReport'));
    expect(reportRepositorySource, contains('FieldValue.serverTimestamp()'));
    expect(logCollectorSource, contains('DebugPrintCallback'));
    expect(logCollectorSource, contains('_maxEntries = 100'));
    expect(mainSource, contains('runZonedGuarded'));
    expect(mainSource, contains('AppLogCollector.init()'));
    expect(mainSource, contains('PlatformDispatcher.instance.onError'));
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
    expect(
      writerPadSource,
      contains('RestorableString _restorableContentType'),
    );
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
    expect(writerTaxonomySource, isNot(contains('Arabic')));

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
    expect(
      archiveSource,
      contains('ArchiveBookService()._parseTextToChapters'),
    );
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
    expect(routerSource, contains('initialReaderChapterIndex'));
    expect(routerSource, contains('resolvedIncoming.chapterIndex'));
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
    expect(writerPadSource, contains('_syncBookTitleFromFirstChapter'));
    expect(writerPadSource, contains('_bookTitleEditedByUser'));
    expect(writerPadSource, isNot(contains('Color(0xFF111018)')));
    expect(writerPadSource, isNot(contains('Color(0xFF191722)')));
    expect(writerPadSource, isNot(contains('Color(0xFF1D1A25)')));
    expect(writerPadSource, isNot(contains('Color(0xFF14121B)')));
    expect(writerPadSource, isNot(contains('const dark = Colors.black')));
    expect(writerPadSource, isNot(contains('const onDark = Colors.white')));
  });

  test('writer navigation and language list use requested polish', () {
    final navSource = File(
      'lib/src/presentation/screens/main_navigation_shell.dart',
    ).readAsStringSync();
    final taxonomySource = File(
      'lib/src/presentation/providers/writer_taxonomy_provider.dart',
    ).readAsStringSync();
    final writerPadSource = File(
      'lib/src/presentation/screens/writer_pad_screen.dart',
    ).readAsStringSync();

    expect(navSource, contains('Icons.edit_note_outlined'));
    expect(navSource, contains('Icons.edit_note'));
    expect(navSource, isNot(contains('Icons.dashboard_outlined')));
    expect(navSource, isNot(contains('Icons.dashboard)')));
    for (final language in [
      'English',
      'Hindi',
      'Bengali',
      'Telugu',
      'Marathi',
      'Tamil',
      'Gujarati',
      'Urdu',
      'Kannada',
      'Malayalam',
    ]) {
      expect(taxonomySource, contains("'$language'"));
    }
    for (final language in ['Arabic', 'French', 'German', 'Spanish']) {
      expect(taxonomySource, isNot(contains("'$language'")));
      expect(writerPadSource, isNot(contains("'${language.toLowerCase()}'")));
    }
  });

  test('interaction writer feed and notification polish stays wired', () {
    final commentTileSource = File(
      'lib/src/presentation/widgets/comment_widgets.dart',
    ).readAsStringSync();
    final readerSource = File(
      'lib/src/presentation/screens/reader_screen.dart',
    ).readAsStringSync();
    final writerSource = File(
      'lib/src/presentation/screens/writer_pad_screen.dart',
    ).readAsStringSync();
    final bookDetailSource = File(
      'lib/src/presentation/screens/book_detail_screen.dart',
    ).readAsStringSync();
    final feedCardSource = File(
      'lib/src/presentation/components/feed_post_card.dart',
    ).readAsStringSync();
    final helpScreenSource = File(
      'lib/src/presentation/screens/help_screen.dart',
    ).readAsStringSync();
    final discoverySource = File(
      'lib/src/presentation/screens/discovery_screen.dart',
    ).readAsStringSync();
    final messagesSource = File(
      'lib/src/presentation/screens/messages_screen.dart',
    ).readAsStringSync();
    final notificationRepoSource = File(
      'lib/src/domain/repositories/notification_repository.dart',
    ).readAsStringSync();
    final messageRepoSource = File(
      'lib/src/data/repositories/firebase_message_repository.dart',
    ).readAsStringSync();

    expect(commentTileSource, contains('PopupMenuButton<String>'));
    expect(commentTileSource, contains('onDoubleTap'));
    expect(commentTileSource, contains('onHorizontalDragEnd'));
    expect(commentTileSource, contains('l10n.unpin'));
    expect(commentTileSource, contains('Icons.push_pin'));
    expect(readerSource, contains('_existingUserReview'));
    expect(readerSource, contains('_isReviewEditMode'));
    expect(readerSource, contains('readOnly:'));
    expect(readerSource, contains("label: const Text('Edit')"));
    expect(writerSource, contains('_populateSynopsisFromFirstLines'));
    expect(writerSource, contains("RestorableString('Hindi')"));
    expect(writerSource, contains('l10n.writerCoverOptional'));
    expect(writerSource, contains('l10n.topicsOptional'));
    expect(writerSource, contains('showLink: false'));
    expect(bookDetailSource, contains('l10n.shareToFeed'));
    expect(bookDetailSource, contains('l10n.defaultShareMessage'));
    expect(feedCardSource, contains('_showEditPostSheet'));
    expect(feedCardSource, contains('pickImage'));
    expect(feedCardSource, contains('updateFeedPost'));
    expect(feedCardSource, isNot(contains('height: 3')));
    expect(helpScreenSource, contains('SubmitErrorDialog'));
    expect(discoverySource, isNot(contains("@\${author.username}")));
    expect(messagesSource, contains('_ConversationSwipeShell'));
    expect(messagesSource, isNot(contains('Icons.delete_outline_rounded')));
    expect(notificationRepoSource, contains('createNotification'));
    expect(notificationRepoSource, contains('createNotifications'));
    expect(
      messageRepoSource,
      contains('Only one message allowed unless recipient replies.'),
    );
    expect(bookDetailSource, contains('l10n.sendToChat'));
    expect(commentTileSource, contains('_SwipeActionShell'));
    expect(commentTileSource, contains('_SlideActionChip'));
    expect(commentTileSource, contains('HapticFeedback.selectionClick'));
    expect(commentTileSource, contains('if (canHighlight)'));
    expect(commentTileSource, contains('color: Colors.black'));
    expect(readerSource, contains('_shareReviewToFeed'));
    expect(readerSource, contains('Share to feed'));
  });

  test('points are removed and home rankings replace leaderboard behavior', () {
    final authProviderSource = File(
      'lib/src/presentation/providers/auth_providers.dart',
    ).readAsStringSync();
    final authRepoSource = File(
      'lib/src/data/repositories/firebase_auth_repository.dart',
    ).readAsStringSync();
    final userModelSource = File(
      'lib/src/domain/models/user_model.dart',
    ).readAsStringSync();
    final writerHeaderSource = File(
      'lib/src/presentation/components/writer/writer_dashboard_header.dart',
    ).readAsStringSync();
    final profileSource = File(
      'lib/src/presentation/screens/profile_screen.dart',
    ).readAsStringSync();
    final publicProfileSource = File(
      'lib/src/presentation/screens/public_profile_screen.dart',
    ).readAsStringSync();
    final shareCardSource = File(
      'lib/src/presentation/components/profile/profile_share_card.dart',
    ).readAsStringSync();
    final homeProviderSource = File(
      'lib/src/presentation/providers/homepage_providers.dart',
    ).readAsStringSync();
    final homeScreenSource = File(
      'lib/src/presentation/screens/home_books_screen.dart',
    ).readAsStringSync();

    for (final source in [
      authProviderSource,
      authRepoSource,
      userModelSource,
      writerHeaderSource,
      profileSource,
      publicProfileSource,
      shareCardSource,
    ]) {
      expect(source, isNot(contains('totalPoints')));
      expect(source, isNot(contains('pointsLastUpdatedAt')));
      expect(source, isNot(contains('updateUserPoints')));
      expect(source, isNot(contains('Gamification')));
      expect(source, isNot(contains("label: 'Points'")));
      expect(source, isNot(contains("label: 'Tier'")));
    }

    expect(
      File('lib/src/domain/models/points_history.dart').existsSync(),
      isFalse,
    );
    expect(
      File(
        'lib/src/data/repositories/firebase_gamification_repository.dart',
      ).existsSync(),
      isFalse,
    );
    expect(homeProviderSource, contains('HomeAuthorRanking.topRated'));
    expect(homeProviderSource, contains('homepageRankedAuthorsProvider'));
    expect(homeProviderSource, contains('homepageTrendingWorksProvider'));
    expect(homeProviderSource, contains('viewCount'));
    expect(homeProviderSource, contains('ratingsCount'));
    expect(homeProviderSource, isNot(contains('FieldValue')));
    final l10n = englishL10n();
    expect(homeScreenSource, contains('l10n.topRatedAuthors'));
    expect(homeScreenSource, contains('l10n.mostReadAuthors'));
    expect(homeScreenSource, contains('l10n.mostPublishedAuthors'));
    expect(homeScreenSource, contains('l10n.shelfTrending'));
    expect(l10n['topRatedAuthors'], 'Top Rated Authors');
    expect(l10n['mostReadAuthors'], 'Most Read Authors');
    expect(l10n['mostPublishedAuthors'], 'Most Published Authors');
    expect(l10n['shelfTrending'], 'Trending Works');
  });
  test('comments serialize optional audio review metadata', () {
    final comment = Comment.fromJson({
      'id': 'c1',
      'bookId': 'book1',
      'userId': 'user1',
      'username': 'reader',
      'text': '',
      'timestamp': 123,
      'audioUrl': 'https://cdn.example.com/audio.m4a',
      'audioObjectKey': 'audio-reviews/user1/book1/chapter1/123.m4a',
      'audioDurationMs': 45000,
      'audioMimeType': 'audio/mp4',
      'audioSizeBytes': 123456,
    });

    expect(comment.text, isEmpty);
    expect(comment.audioUrl, 'https://cdn.example.com/audio.m4a');
    expect(comment.audioDurationMs, 45000);
    expect(comment.toJson(), containsPair('audioMimeType', 'audio/mp4'));
    expect(comment.toJson(), containsPair('audioSizeBytes', 123456));
  });

  test('onboarding is wired as a once-per-user signed-in gate', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final gateSource = File(
      'lib/src/presentation/screens/onboarding_gate.dart',
    ).readAsStringSync();
    final enArb = englishL10n();

    expect(mainSource, contains('OnboardingGate'));
    expect(mainSource, contains('userId: user.uid'));
    expect(gateSource, contains("onboarding_seen_\${widget.userId}_v1"));
    expect(gateSource, contains('setBool(_prefsKey, true)'));
    for (final key in [
      'onboardingDiscoverTitle',
      'onboardingOfflineTitle',
      'onboardingWriteTitle',
      'onboardingCommunityTitle',
      'onboardingProfileTitle',
    ]) {
      expect(enArb[key], isA<String>());
    }
  });

  test('profile separates saved and downloaded offline content', () {
    final profileSource = File(
      'lib/src/presentation/screens/profile_screen.dart',
    ).readAsStringSync();
    final savedSource = File(
      'lib/src/presentation/components/profile/user_saved_tab.dart',
    ).readAsStringSync();
    final downloadedSource = File(
      'lib/src/presentation/components/profile/user_downloaded_tab.dart',
    ).readAsStringSync();
    final providerSource = File(
      'lib/src/presentation/providers/book_providers.dart',
    ).readAsStringSync();
    final serviceSource = File(
      'lib/src/data/services/offline_service.dart',
    ).readAsStringSync();

    expect(profileSource, contains('DefaultTabController'));
    expect(profileSource, contains('length: 5'));
    expect(profileSource, contains('UserDownloadedTab'));
    expect(savedSource, contains('savedBooksProvider'));
    expect(downloadedSource, contains('downloadedBookEntriesProvider'));
    expect(downloadedSource, contains('deleteBook(entry.book.id)'));
    expect(downloadedSource, contains('homepageDownloadedBooksProvider'));
    expect(serviceSource, contains('class OfflineBookEntry'));
    expect(serviceSource, contains('downloadedAt'));
    expect(serviceSource, contains('sizeBytes'));
    expect(providerSource, contains('return [];'));
    expect(providerSource, isNot(contains('...offlineBooks.where')));
  });

  test('public profile hides author metrics but keeps three summary stats', () {
    final ownAboutSource = File(
      'lib/src/presentation/components/profile/user_about_tab.dart',
    ).readAsStringSync();
    final publicSource = File(
      'lib/src/presentation/screens/public_profile_screen.dart',
    ).readAsStringSync();

    expect(ownAboutSource, contains('AuthorStatsPanel(user: user)'));
    expect(publicSource, isNot(contains('AuthorStatsPanel')));
    expect(publicSource, contains('Row('));
    expect(publicSource, contains('label: l10n.followers'));
    expect(publicSource, contains('label: l10n.following'));
    expect(publicSource, contains('label: l10n.works'));
  });

  test('support contact email is updated across help and legal pages', () {
    final helpSource = File(
      'lib/src/presentation/screens/help_screen.dart',
    ).readAsStringSync();
    final routerSource = File(
      'lib/src/presentation/routing/app_router.dart',
    ).readAsStringSync();

    expect(helpSource, contains("path: 'contact@wreadom.in'"));
    expect(helpSource, contains('LaunchMode.externalApplication'));
    expect(helpSource, contains('SubmitErrorDialog'));
    expect(routerSource, contains('contact@wreadom.in'));
    expect(routerSource, isNot(contains('smenaria2@gmail.com')));
  });

  test('feed book cards show book title above writer name context', () {
    final modelSource = File(
      'lib/src/domain/models/feed_post.dart',
    ).readAsStringSync();
    final cardSource = File(
      'lib/src/presentation/components/feed_post_card.dart',
    ).readAsStringSync();
    final detailSource = File(
      'lib/src/presentation/screens/book_detail_screen.dart',
    ).readAsStringSync();
    final readerSource = File(
      'lib/src/presentation/screens/reader_screen.dart',
    ).readAsStringSync();

    expect(modelSource, contains('String? bookAuthorName'));
    expect(cardSource, contains('post.bookAuthorName'));
    expect(cardSource, contains('bookDetailProvider(bookIdText)'));
    expect(cardSource, contains('resolvedBookAuthorName'));
    expect(cardSource, contains('resolvedBookTitle'));
    expect(
      cardSource.indexOf('if (resolvedBookTitle.isNotEmpty)'),
      lessThan(cardSource.indexOf('if (resolvedBookAuthorName.isNotEmpty)')),
    );
    expect(cardSource, isNot(contains('l10n.regarding')));
    expect(detailSource, contains('bookAuthorName: bookAuthorName(book)'));
    expect(
      readerSource,
      contains("'bookAuthorName': bookAuthorName(widget.book)"),
    );
    expect(
      readerSource,
      contains('bookAuthorName: bookAuthorName(widget.book)'),
    );
  });

  test('profile saved and history tabs expose remove actions', () {
    final profileSource = File(
      'lib/src/presentation/screens/profile_screen.dart',
    ).readAsStringSync();
    final savedSource = File(
      'lib/src/presentation/components/profile/user_saved_tab.dart',
    ).readAsStringSync();
    final historySource = File(
      'lib/src/presentation/components/profile/user_history_tab.dart',
    ).readAsStringSync();

    expect(profileSource, contains('isScrollable: true'));
    expect(profileSource, contains('tabAlignment: TabAlignment.start'));
    expect(savedSource, contains('updateUserSavedBooks'));
    expect(savedSource, contains('_RemovableBookGridItem'));
    expect(historySource, contains('updateUserReadingHistory'));
    expect(historySource, contains('_RemovableHistoryGridItem'));
  });

  test('save flow asks before downloading and removing offline copy', () {
    final source = File(
      'lib/src/presentation/screens/book_detail_screen.dart',
    ).readAsStringSync();
    final l10n = englishL10n();

    expect(source, contains('l10n.downloadSavedBookTitle'));
    expect(source, contains('offlineServiceProvider'));
    expect(source, contains('removeDownload == true'));
    expect(source, contains('homepageDownloadedBooksProvider'));
    for (final key in [
      'bookSaved',
      'downloadSavedBookTitle',
      'downloadSavedBookBody',
      'notNow',
      'download',
      'keep',
    ]) {
      expect(l10n[key], isA<String>());
    }
  });

  test('notifications group message rows and carry comment targets', () {
    final notificationSource = File(
      'lib/src/presentation/screens/notifications_screen.dart',
    ).readAsStringSync();
    final resolverSource = File(
      'lib/src/utils/notification_target_resolver.dart',
    ).readAsStringSync();
    final routerSource = File(
      'lib/src/presentation/routing/app_router.dart',
    ).readAsStringSync();

    expect(notificationSource, contains('_groupNotificationItems'));
    expect(notificationSource, contains('displayItem.notifications'));
    expect(notificationSource, contains('PostDetailArguments'));
    expect(notificationSource, contains('BookDetailArguments'));
    expect(resolverSource, contains('commentId'));
    expect(resolverSource, contains('replyId'));
    expect(routerSource, contains('targetCommentId'));
    expect(routerSource, contains('targetReplyId'));
  });

  test('target comments and swipe hints are wired', () {
    final postSource = File(
      'lib/src/presentation/screens/post_detail_screen.dart',
    ).readAsStringSync();
    final bookSource = File(
      'lib/src/presentation/screens/book_detail_screen.dart',
    ).readAsStringSync();
    final commentSource = File(
      'lib/src/presentation/widgets/comment_widgets.dart',
    ).readAsStringSync();
    final messagesSource = File(
      'lib/src/presentation/screens/messages_screen.dart',
    ).readAsStringSync();
    final conversationSource = File(
      'lib/src/presentation/screens/conversation_screen.dart',
    ).readAsStringSync();
    final l10n = englishL10n();

    expect(postSource, contains('l10n.targetComment'));
    expect(bookSource, contains('targetCommentId'));
    expect(commentSource, contains('isTargetComment'));
    expect(commentSource, contains('isTargetReply'));
    expect(bookSource, contains('swipe_hint_seen_book_comments_v1'));
    expect(messagesSource, contains('swipe_hint_seen_messages_v1'));
    expect(conversationSource, contains('swipe_hint_seen_conversation_v1'));
    for (final key in [
      'targetComment',
      'removeReadingHistoryTitle',
      'removeReadingHistoryBody',
      'gotIt',
      'swipeHintBookComments',
      'swipeHintMessages',
    ]) {
      expect(l10n[key], isA<String>());
    }
  });
}
