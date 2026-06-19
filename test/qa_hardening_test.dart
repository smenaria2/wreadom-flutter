import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/utils/firestore_utils.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/domain/models/chapter.dart';
import 'package:librebook_flutter/src/domain/models/comment.dart';
import 'package:librebook_flutter/src/presentation/components/writer/writer_book_card.dart';
import 'package:librebook_flutter/src/presentation/providers/writer_providers.dart';
import 'package:librebook_flutter/src/presentation/routing/app_router.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';
import 'package:librebook_flutter/src/presentation/screens/reader_screen.dart';
import 'package:librebook_flutter/src/presentation/widgets/glass_surface.dart';

void main() {
  String readFirestoreRules() {
    final local = File('firestore.rules');
    if (local.existsSync()) return local.readAsStringSync();
    return File('../librebook/firestore.rules').readAsStringSync();
  }

  String readFirestoreIndexes() {
    final local = File('firestore.indexes.json');
    if (local.existsSync()) return local.readAsStringSync();
    return File('../librebook/firestore.indexes.json').readAsStringSync();
  }

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

  test(
    'single-chapter moved drafts remain visible and imported drafts hide',
    () {
      final movedChapterDraft =
          book(
            id: 'single-draft',
            title: 'Moved Chapter',
            status: 'draft',
          ).copyWith(
            chapters: const [
              Chapter(
                id: 'chapter-1',
                title: 'Moved Chapter',
                content: 'Text',
                index: 0,
              ),
            ],
            chapterCount: 1,
          );
      final importedSourceDraft = movedChapterDraft.copyWith(status: 'deleted');

      expect(writerBookMatchesTab(movedChapterDraft, 'draft'), isTrue);
      expect(writerBookMatchesTab(importedSourceDraft, 'draft'), isFalse);
    },
  );

  test('writer chapter draft moves migrate comments and feed metadata', () {
    final source = File(
      'lib/src/data/repositories/firebase_writer_repository.dart',
    ).readAsStringSync();

    expect(source, contains('_restoreEngagementDataToStandalone'));
    expect(source, contains('_migrateEngagementDataToChapter'));
    expect(source, contains(".collection('comments')"));
    expect(source, contains(".collection('feed')"));
    expect(source, contains("'chapterIndex': 0"));
    expect(source, contains("'chapterId': null"));
    expect(source, contains("'chapterId': newChapterId"));
    expect(source, contains("'chapterIndex': newChapterIndex"));
    expect(source, contains('static const int _batchChunkSize = 450'));
  });

  test('writer chapter sheet exposes move and import draft actions', () {
    final source = File(
      'lib/src/presentation/screens/writer_pad_screen.dart',
    ).readAsStringSync();
    final english = englishL10n();

    expect(source, contains('l10n.importFromDrafts'));
    expect(source, contains('l10n.moveChapterToDraftsTitle'));
    expect(source, contains('final sourceStatus = _statusForChapterMove();'));
    expect(source, contains('final targetStatus = _statusForChapterMove();'));
    expect(source, contains('status: sourceStatus'));
    expect(source, contains('status: targetStatus'));
    expect(source, contains('moveChapterToStandaloneDraft'));
    expect(source, contains('importSingleDraftsToBook'));
    expect(source, contains('Icons.file_upload_outlined'));
    expect(source, contains('Icons.file_download_outlined'));
    expect(english['importFromDrafts'], 'Import from drafts');
    expect(english['moveToDrafts'], 'Move to drafts');
  });

  test('message rows use participant photos in chat list avatars', () {
    final source = File(
      'lib/src/presentation/screens/messages_screen.dart',
    ).readAsStringSync();

    expect(source, contains('final photoUrl = other?.photoURL?.trim();'));
    expect(source, contains('CachedNetworkImageProvider(photoUrl)'));
    expect(source, contains('title.characters.first.toUpperCase()'));
  });

  test(
    'daily topic admin paginates seven at a time and refreshes home topics',
    () {
      final adminScreenSource = File(
        'lib/src/presentation/screens/admin_daily_topics_screen.dart',
      ).readAsStringSync();
      final adminProviderSource = File(
        'lib/src/presentation/providers/admin_topic_providers.dart',
      ).readAsStringSync();
      final dailyTopicProviderSource = File(
        'lib/src/presentation/providers/daily_topic_providers.dart',
      ).readAsStringSync();

      expect(adminScreenSource, contains('int _visibleTopicCount = 7;'));
      expect(adminScreenSource, contains('_visibleTopicCount += 7'));
      expect(adminProviderSource, contains('refreshNow()'));
      expect(dailyTopicProviderSource, contains('Future<void> refreshNow()'));
    },
  );

  test('writer dashboard and pad expose simple chapter draft flow', () {
    final dashboardSource = File(
      'lib/src/presentation/screens/writer_dashboard_screen.dart',
    ).readAsStringSync();
    final writerSource = File(
      'lib/src/presentation/screens/writer_pad_screen.dart',
    ).readAsStringSync();
    final routeSource = File(
      'lib/src/presentation/routing/writer_pad_mode.dart',
    ).readAsStringSync();
    final english = englishL10n();

    expect(routeSource, contains('enum WriterPadMode'));
    expect(routeSource, contains('chapterDraft'));
    expect(dashboardSource, contains('l10n.createDraft'));
    expect(dashboardSource, contains('WriterPadMode.chapterDraft'));
    expect(writerSource, contains('bool get _isChapterDraftMode'));
    expect(writerSource, contains('l10n.addToBook'));
    expect(writerSource, contains('_chapterDraftTitleForSave'));
    expect(writerSource, contains('_addChapterDraftToBook'));
    expect(writerSource, contains('importSingleDraftsToBook'));
    expect(english['createDraft'], 'Create Draft Chapter');
    expect(english['addToBook'], 'Add to book');
    expect(english['draftAddedToBook'], 'Draft added to book.');
  });

  test('collab chapter draft moves create user-owned standalone drafts', () {
    final repositorySource = File(
      'lib/src/data/repositories/firebase_writer_repository.dart',
    ).readAsStringSync();
    final writerSource = File(
      'lib/src/presentation/screens/writer_pad_screen.dart',
    ).readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(repositorySource, contains('required String ownerUserId'));
    expect(repositorySource, contains('authorId: draftOwnerId'));
    expect(repositorySource, contains('authorIds: [draftOwnerId]'));
    expect(repositorySource, contains('collaborationStatus: null'));
    expect(repositorySource, contains('if (book.authorId?.trim() != userId)'));
    expect(repositorySource, contains('if (isAcceptedCollaboration(book))'));
    expect(writerSource, contains('ownerUserId: user.id'));
    expect(mainSource, contains('if (Firebase.apps.isNotEmpty)'));
    expect(mainSource, contains("error.code == 'duplicate-app'"));
    expect(mainSource, contains('if (!firebaseReady) {'));
    expect(mainSource, contains('if (firebaseRetrying) {'));
    expect(mainSource, contains('onPressed: onRetryFirebase'));
    expect(
      mainSource,
      isNot(
        contains('Future.delayed(\n        const Duration(milliseconds: 100)'),
      ),
    );
  });

  test('app startup configures bounded Firestore persistence', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    expect(mainSource, contains('FirebaseFirestore.instance.settings'));
    expect(mainSource, contains('persistenceEnabled: true'));
    expect(mainSource, contains('cacheSizeBytes: 80 * 1024 * 1024'));
  });

  test('live comment listeners are ordered and capped', () {
    final source = File(
      'lib/src/presentation/providers/comment_providers.dart',
    ).readAsStringSync();
    expect(source, contains('const int liveCommentLimit = 80'));
    expect(source, contains(".orderBy('timestamp', descending: true)"));
    expect(source, contains('.limit(liveCommentLimit)'));
  });

  test('feed cards use stored comment counts instead of per-card listeners', () {
    final source = File(
      'lib/src/presentation/components/feed_post_card.dart',
    ).readAsStringSync();
    expect(
      source,
      contains(
        'final commentsCount = post.commentCount ?? post.comments?.length ?? 0;',
      ),
    );
    expect(source, isNot(contains('liveFeedPostCommentsProvider(post.id!')));
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
    expect(find.textContaining('Published:'), findsOneWidget);
  });

  testWidgets('writer card uses glass surface in dark mode', (tester) async {
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

    expect(find.byType(GlassSurface), findsOneWidget);
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
      'account',
      'preferences',
      'theme',
      'support',
      'submitError',
      'help',
      'legal',
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
    final legalSource = File(
      'lib/src/data/services/legal_document_service.dart',
    ).readAsStringSync();

    expect(source, contains('AppLinkHelper.privacyPolicyUrl'));
    expect(source, contains('AppLinkHelper.termsUrl'));
    expect(source, contains('LegalDocumentScreen'));
    expect(legalSource, contains('sanitizeLegalHtml'));
  });

  test('book detail exposes original author profile and follow actions', () {
    final source = File(
      'lib/src/presentation/screens/book_detail_screen.dart',
    ).readAsStringSync();
    final collaborationAuthorBlock = source.substring(
      source.indexOf('return Wrap('),
      source.indexOf('class _AuthorPill'),
    );

    expect(source, contains('book.isOriginal'));
    expect(source, contains('AppRoutes.publicProfile'));
    expect(source, contains('PublicProfileArguments'));
    expect(source, contains('class _AuthorFollowSlot'));
    expect(source, contains('_AuthorFollowSlot(authorId: authorId)'));
    expect(source, contains('isFollowingProvider'));
    expect(source, contains('followRepositoryProvider'));
    expect(collaborationAuthorBlock, isNot(contains('_AuthorFollowSlot')));
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
    expect(readerSource, contains('_markInitialScrollRestored'));
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
    expect(readerSource, contains("l10n.viewComments"));
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
    expect(readerSource, contains('completedChapterIndex: chapterIndex'));
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
      expect(source, contains('liveBookCommentsProvider(book.id)'));
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
    expect(source, isNot(contains('FieldValue.increment(1)')));
    expect(source, isNot(contains('FieldValue.increment(-deletedCount)')));
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
      expect(source, contains('_hasRecipientReply'));
      expect(source, contains('hasRecipientReply: hasRecipientReply'));
      expect(source, contains('_recipientHasRepliedFromConversation'));
      expect(source, contains("'deletedFor': FieldValue.arrayUnion([userId])"));
      expect(
        source,
        contains("'deletedFor': FieldValue.arrayRemove([senderId])"),
      );
      expect(
        source,
        contains("'deletedFor': FieldValue.arrayRemove([currentUser.id])"),
      );
      expect(source, contains('_sendMessageDocument'));
      expect(source, contains('transaction.set(messageRef'));
      expect(source, contains('transaction.update(conversationRef'));
      expect(source, isNot(contains(".collection('conversations').add")));
      expect(source, isNot(contains("'participants': FieldValue.arrayRemove")));
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
      expect(
        feedSource,
        isNot(contains("'commentCount': FieldValue.increment(1)")),
      );
      expect(
        feedSource,
        isNot(contains("'commentCount': FieldValue.increment(-1)")),
      );
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

  test('feed comment writes leave comment counts to Cloud Functions', () {
    final feedSource = File(
      'lib/src/data/repositories/firebase_feed_repository.dart',
    ).readAsStringSync();

    final setIndex = feedSource.indexOf('await commentRef.set');
    expect(setIndex, greaterThan(-1));
    expect(feedSource, isNot(contains("'commentCount': FieldValue.increment")));
    expect(
      feedSource,
      isNot(contains('Comment saved but count update failed')),
    );
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
    final rulesSource = readFirestoreRules();
    final firebaseConfig = File('firebase.json').readAsStringSync();

    expect(feedCardSource, contains('l10n.signInToContinueAction'));
    expect(postDetailSource, contains('l10n.signInToContinueAction'));
    expect(followSource, contains('_followDocId'));
    expect(rulesSource, contains('followerId'));
    expect(rulesSource, contains("ownsIncoming('followerId')"));
    expect(rulesSource, contains("ownsIncoming('userId')"));
    expect(rulesSource, contains("onlyChanges(['commentCount'])"));
    expect(firebaseConfig, isNot(contains('"rules": "firestore.rules"')));
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

  test('shared firestore rules preserve android and web compatibility paths', () {
    final rulesSource = readFirestoreRules();

    expect(
      rulesSource,
      contains("function ownsIncomingAny(primary, fallback)"),
    );
    expect(
      rulesSource,
      isNot(contains("function ownsExistingAny(primary, fallback)")),
    );
    expect(rulesSource, contains("function isBookAuthor(bookId)"));
    expect(
      rulesSource,
      contains("function allowsLegacyEmbeddedFeedCommentMutation()"),
    );
    expect(
      rulesSource,
      contains("request.auth.token.get('admin', false) == true"),
    );
    expect(rulesSource, contains('function validSelfUserUpdate(userId)'));
    expect(rulesSource, isNot(contains("'fcmTokenRegistry'")));
    expect(
      rulesSource,
      contains(
        "request.resource.data.get('totalPoints', null) == resource.data.get('totalPoints', null)",
      ),
    );
    expect(
      rulesSource,
      contains(
        "request.resource.data.get('isDeactivated', null) == resource.data.get('isDeactivated', null)",
      ),
    );
    expect(
      rulesSource,
      isNot(contains('userId == uid() ||\n        isAdmin()')),
    );

    expect(rulesSource, contains("ownsIncoming('followerId')"));
    expect(rulesSource, contains("onlyChanges(['commentCount'])"));
    expect(rulesSource, contains("allowsLegacyEmbeddedFeedCommentMutation()"));
    expect(rulesSource, contains("onlyChanges(['likes', 'likesCount'])"));
    expect(rulesSource, contains("onlyChanges(['replies', 'repliesCount'])"));
    expect(
      rulesSource,
      contains("request.resource.data.highlightedByUserId == uid()"),
    );
    expect(rulesSource, contains("ownsIncomingAny('authorId', 'userId')"));
    expect(rulesSource, contains("function canEditBookData(data)"));
    expect(
      rulesSource,
      contains("request.resource.data.reporterId == uid() ||"),
    );
    expect(rulesSource, contains("request.resource.data.userId == uid()"));
  });

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
    expect(
      readerSource,
      contains('NotificationService.instance.ttsActionEvents'),
    );
    expect(readerSource, contains('_syncTtsMiniPlayer'));
    expect(readerSource, contains('_pauseTtsFromNotification'));
    expect(readerSource, contains('_resumeTtsFromNotification'));
    expect(readerSource, contains('SelectionArea'));
    expect(readerSource, contains('_isTtsPlaying || _isTtsPreparing'));
    expect(readerSource, contains('AppLinkHelper.chapter'));
    expect(repositorySource, contains(".collection('views')"));
    expect(repositorySource, contains('runTransaction'));
    expect(repositorySource, contains('FieldValue.increment(1)'));
    expect(repositorySource, contains('existingView.exists'));
    expect(readerSource, contains('_shouldPersistProgress'));
    expect(readerSource, contains('const Duration(seconds: 30)'));
    expect(readerSource, contains('(position - lastPosition).abs() >= 0.025'));
    expect(readerSource, contains('_ReaderTopBar'));
    expect(readerSource, contains('contentPadding: readerContentPadding'));
    expect(
      readerSource,
      isNot(contains('bottomNavigationBar: _ReaderBottomBar')),
    );
    expect(
      readerSource,
      isNot(contains('preferredSize: Size.fromHeight(_showReaderChrome')),
    );
  });

  test(
    'deprecated firebase index config stays compatible but is not deployed',
    () {
      final firebaseConfig = File('firebase.json').readAsStringSync();
      final indexes = readFirestoreIndexes();

      expect(
        firebaseConfig,
        isNot(contains('"indexes": "firestore.indexes.json"')),
      );
      expect(indexes, contains('"collectionGroup": "comments"'));
      expect(indexes, contains('"fieldPath": "timestamp"'));
      expect(indexes, contains('"collectionGroup": "books"'));
      expect(indexes, contains('"collectionGroup": "feed"'));
    },
  );

  test('archive search scope and home ia recommendations stay wired', () {
    final archiveServiceSource = File(
      'lib/src/data/services/archive_book_service.dart',
    ).readAsStringSync();
    final homepageSource = File(
      'lib/src/presentation/providers/homepage_providers.dart',
    ).readAsStringSync();
    final archiveRepositorySource = File(
      'lib/src/data/repositories/archive_book_repository.dart',
    ).readAsStringSync();

    expect(archiveServiceSource, contains('allowedSearchCollections'));
    expect(archiveServiceSource, contains('JaiGyan'));
    expect(archiveServiceSource, contains('digitallibraryindia'));
    expect(archiveServiceSource, contains('booksbylanguage_hindi'));
    expect(archiveServiceSource, contains('mediatype:texts'));
    expect(archiveRepositorySource, isNot(contains('isUnsafeSearchQuery')));
    expect(archiveRepositorySource, isNot(contains('filterSafeArchiveBooks')));
    expect(homepageSource, contains('homepage_ia_books_cache_v3'));
    expect(homepageSource, contains('_positiveRecommendationIds'));
    expect(homepageSource, contains('homepageRecommendedBooksProvider'));
    expect(homepageSource, contains('getBooksByIds(communityIds)'));
    final iaProviderStart = homepageSource.indexOf(
      'final homepageIABooksProvider',
    );
    final iaProviderSource = homepageSource.substring(iaProviderStart);
    expect(iaProviderSource, isNot(contains('repo.getUpvotedIABooks')));
  });

  test(
    'reader progress is chapter-only and selection tts avoids scroll jumps',
    () {
      final readerSource = File(
        'lib/src/presentation/screens/reader_screen.dart',
      ).readAsStringSync();

      expect(readerSource, isNot(contains('_chapterContentEndKey')));
      expect(readerSource, isNot(contains('_progressScrollRange')));
      expect(readerSource, isNot(contains('RenderAbstractViewport.maybeOf')));
      expect(
        readerSource,
        contains('final maxScroll = position.maxScrollExtent'),
      );
      expect(readerSource, contains('position.pixels / maxScroll'));
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
      expect(readerSource, contains('pushReplacementNamed'));
      expect(readerSource, contains('BookDetailArguments'));
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
      expect(repositorySource, contains('getUserChapterReview'));
      expect(repositorySource, contains('upsertChapterReview'));
      expect(repositorySource, contains('toggleReviewHighlight'));
      expect(repositorySource, contains('maxHighlighted = 3'));
      expect(readerSource, contains('int _chapterRating = 5'));
      expect(readerSource, contains('_isOwnOriginalBook'));
      expect(readerSource, contains('l10n.authorsCannotReviewOwnBook'));
      expect(readerSource, contains('upsertChapterReview'));
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
      expect(cardSource, isNot(contains('officialLiteraryProfile')));
      expect(cardSource, isNot(contains('@\${user.username}')));
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
    expect(readerSettingsSource, isNot(contains('reader_font_index')));
    expect(readerSource, isNot(contains('Serif Font')));
    expect(readerSettingsSource, isNot(contains('serif')));
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
      expect(source, contains('AppHaptics.light()'));
    }

    expect(feedPostSource, contains('AppHaptics.light()'));
    expect(readerSource, contains('AppHaptics.selection()'));
    expect(followSource, contains('AppHaptics.medium()'));
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
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(routerSource, contains('_resolveIncomingName(name)'));
    expect(routerSource, contains('AppLinkHelper.resolve(name)'));
    expect(routerSource, contains('notFoundRouteSettingsForAppLink'));
    expect(routerSource, contains('NotFoundArguments'));
    expect(routerSource, contains('AppRoutes.notFound'));
    expect(routerSource, contains('Open in in-app browser'));
    expect(mainSource, contains('notFoundRouteSettingsForAppLink'));
    expect(
      mainSource,
      contains('navigator.pushNamedAndRemoveUntil(AppRoutes.main'),
    );
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
    expect(source, isNot(contains('SectionError')));
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
    expect(writerPadSource, contains('GlassScaffold'));
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
    final conversationSource = File(
      'lib/src/presentation/screens/conversation_screen.dart',
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
    expect(writerSource, contains('l10n.collabEditWarning'));
    expect(writerSource, contains('canRemoveAccepted'));
    expect(writerSource, contains('canChangeCollaborator'));
    expect(
      writerSource,
      contains('collaborationStatus == collaborationStatusPending'),
    );
    expect(bookDetailSource, contains('l10n.shareToFeed'));
    expect(bookDetailSource, contains('l10n.defaultShareMessage'));
    expect(bookDetailSource, contains('collabBookInfo'));
    expect(bookDetailSource, contains('_localizedContentType'));
    expect(bookDetailSource, contains('contentTypeStory'));
    expect(bookDetailSource, contains('chapterCount > 1'));
    expect(bookDetailSource, isNot(contains('_CollabChip')));
    expect(feedCardSource, contains('_showEditPostSheet'));
    expect(feedCardSource, contains('pickImage'));
    expect(feedCardSource, contains('updateFeedPost'));
    expect(feedCardSource, isNot(contains(RegExp(r'height:\s*3\b'))));
    expect(helpScreenSource, contains('SubmitErrorDialog'));
    expect(discoverySource, isNot(contains("@\${author.username}")));
    expect(messagesSource, contains('_ConversationSwipeShell'));
    expect(conversationSource, contains('_hasLoadedRecipientReply'));
    expect(conversationSource, contains('_isWaitingForReply('));
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
    expect(commentTileSource, contains('AppHaptics.selection'));
    expect(commentTileSource, contains('if (canHighlight)'));
    expect(commentTileSource, contains('color: Colors.black'));
    expect(readerSource, contains('_shareReviewToFeed'));
    expect(readerSource, contains('Share to feed'));
  });

  test('account-scoped notification token and pager reset stay wired', () {
    final authRepositorySource = File(
      'lib/src/data/repositories/firebase_auth_repository.dart',
    ).readAsStringSync();
    final authContractSource = File(
      'lib/src/domain/repositories/auth_repository.dart',
    ).readAsStringSync();
    final navigationSource = File(
      'lib/src/presentation/screens/main_navigation_shell.dart',
    ).readAsStringSync();
    final notificationProviderSource = File(
      'lib/src/presentation/providers/notification_providers.dart',
    ).readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();
    final functionsSource = File('functions/index.js').readAsStringSync();

    expect(authContractSource, contains('claimFcmToken'));
    expect(authContractSource, contains('removeFcmToken'));
    expect(authRepositorySource, contains("httpsCallable('claimFcmToken')"));
    expect(authRepositorySource, contains("httpsCallable('removeFcmToken')"));
    expect(
      authRepositorySource,
      isNot(contains("where('fcmTokens', arrayContains: token)")),
    );
    expect(authRepositorySource, isNot(contains('using client fallback')));
    expect(
      authRepositorySource,
      contains('FirebaseMessaging.instance.getToken()'),
    );
    expect(navigationSource, contains('claimFcmToken'));
    expect(notificationProviderSource, contains('_loadedUserId'));
    expect(
      notificationProviderSource,
      contains('previousUserId != nextUserId'),
    );
    expect(mainSource, contains('ref.invalidate(pagedNotificationsProvider)'));
    expect(functionsSource, contains('exports.claimFcmToken'));
    expect(functionsSource, contains('exports.removeFcmToken'));
    expect(functionsSource, contains('registryWithoutToken'));
  });

  test('feed image uploads use Cloudinary instead of Firebase Storage', () {
    final feedRepositorySource = File(
      'lib/src/data/repositories/firebase_feed_repository.dart',
    ).readAsStringSync();
    final cloudinaryUploadSource = File(
      'lib/src/data/services/cloudinary_upload_service.dart',
    ).readAsStringSync();

    expect(feedRepositorySource, contains('CloudinaryUploadService'));
    expect(feedRepositorySource, contains("folder: 'feed_posts'"));
    expect(feedRepositorySource, isNot(contains('FirebaseStorage.instance')));
    expect(feedRepositorySource, isNot(contains('feed_images')));
    expect(cloudinaryUploadSource, contains('f_auto,q_auto,w_1200,c_limit'));
    expect(cloudinaryUploadSource, contains('_withDeliveryTransform'));
  });

  test('profile privacy and collab localization hardening stays wired', () {
    final profileSource = File(
      'lib/src/presentation/screens/profile_screen.dart',
    ).readAsStringSync();
    final publicProfileSource = File(
      'lib/src/presentation/screens/public_profile_screen.dart',
    ).readAsStringSync();
    final settingsSource = File(
      'lib/src/presentation/screens/profile_settings_screen.dart',
    ).readAsStringSync();
    final repositorySource = File(
      'lib/src/data/repositories/firebase_profile_repository.dart',
    ).readAsStringSync();
    final hiL10n =
        jsonDecode(File('lib/l10n/app_hi.arb').readAsStringSync())
            as Map<String, dynamic>;

    expect(profileSource, contains('_safeProfileDisplayName'));
    expect(profileSource, contains('_safeProfileInitial'));
    expect(publicProfileSource, contains('_safePublicProfileDisplayName'));
    expect(publicProfileSource, contains('_safePublicProfileInitial'));
    expect(
      settingsSource,
      contains('_blankToNull(_displayNameController.text)'),
    );
    expect(settingsSource, contains('_blankToNull(_penNameController.text)'));
    expect(repositorySource, contains('_emptyStringDeletes'));
    expect(hiL10n['collaboration'], 'सहलेखन');
    expect(hiL10n['collab'], 'सहलेखन');
    expect(hiL10n['helpCategoryCollaboration'], 'सहलेखन');
  });

  test('bug UI hardening avoids blank startup and raw placeholder strings', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final collaborationSource = File(
      'lib/src/presentation/screens/collaboration_request_screen.dart',
    ).readAsStringSync();
    final readerSource = File(
      'lib/src/presentation/screens/reader_screen.dart',
    ).readAsStringSync();
    final routerSource = File(
      'lib/src/presentation/routing/app_router.dart',
    ).readAsStringSync();
    final homeSource = File(
      'lib/src/presentation/screens/home_books_screen.dart',
    ).readAsStringSync();
    final enL10n = englishL10n();

    expect(mainSource, contains('_bootstrapFirebaseBeforeRunApp'));
    expect(
      mainSource.indexOf('_bootstrapFirebaseBeforeRunApp'),
      lessThan(mainSource.indexOf('runApp(')),
    );
    expect(mainSource, contains('_guardedStartupStep'));
    expect(collaborationSource, contains('l10n.collaborationRequestTitle'));
    expect(collaborationSource, contains('l10n.collaborationRequestMessage'));
    expect(
      collaborationSource,
      isNot(contains(r'Could not update request: $')),
    );
    expect(readerSource, contains('l10n.readerSettings'));
    expect(readerSource, contains('l10n.fontSizeValue'));
    expect(readerSource, isNot(contains(r'Read aloud failed: $')));
    expect(routerSource, contains('certificateUnavailableBody'));
    expect(routerSource, contains('competitionUnavailableBody'));
    expect(routerSource, isNot(contains('can be expanded')));
    expect(routerSource, isNot(contains('can be surfaced')));
    expect(homeSource, contains('Expanded('));
    expect(homeSource, contains('memCacheWidth'));

    for (final key in [
      'collaborationRequestTitle',
      'collaborationRequestMessage',
      'readAloudFailed',
      'fontSizeValue',
      'certificateUnavailableBody',
      'competitionUnavailableBody',
      'hapticFeedback',
    ]) {
      expect(enL10n[key], isA<String>());
    }
  });

  test('google sign-in initialization is centralized before auth', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final authRepositorySource = File(
      'lib/src/data/repositories/firebase_auth_repository.dart',
    ).readAsStringSync();
    final initializerSource = File(
      'lib/src/data/services/google_sign_in_initializer.dart',
    ).readAsStringSync();

    expect(initializerSource, contains('class GoogleSignInInitializer'));
    expect(
      initializerSource,
      contains('static Future<void>? _initializeFuture'),
    );
    expect(initializerSource, contains('serverClientId: serverClientId'));
    expect(initializerSource, contains('clientId: serverClientId'));
    expect(mainSource, contains('GoogleSignInInitializer.ensureInitialized()'));
    expect(mainSource, isNot(contains('const String _googleServerClientId')));
    expect(
      authRepositorySource.indexOf(
        'GoogleSignInInitializer.ensureInitialized()',
      ),
      lessThan(authRepositorySource.indexOf('_googleSignIn.authenticate()')),
    );
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

    final reply = CommentReply.fromJson({
      'id': 'r1',
      'userId': 'user2',
      'username': 'listener',
      'text': '',
      'timestamp': 456,
      'audioUrl': 'https://cdn.example.com/reply.m4a',
      'audioObjectKey': 'audio-reviews/user2/book1/reply-c1/456.m4a',
      'audioDurationMs': 18000,
      'audioMimeType': 'audio/mp4',
      'audioSizeBytes': 54321,
    });

    expect(reply.text, isEmpty);
    expect(reply.audioUrl, 'https://cdn.example.com/reply.m4a');
    expect(reply.audioDurationMs, 18000);
    expect(reply.toJson(), containsPair('audioMimeType', 'audio/mp4'));
    expect(reply.toJson(), containsPair('audioSizeBytes', 54321));
  });

  test('embedded reply audio metadata survives Firestore normalization', () {
    final data = mapFirestoreData({
      'bookId': 'book1',
      'userId': 'user1',
      'username': 'reader',
      'text': 'Parent',
      'timestamp': 123,
      'replies': [
        {
          'id': 'r1',
          'userId': 'user2',
          'username': 'listener',
          'text': '',
          'timestamp': '456',
          'audioUrl': 'https://cdn.example.com/reply.m4a',
          'audioObjectKey': 'audio-reviews/user2/book1/reply-c1/456.m4a',
          'audioDurationMs': '18000',
          'audioMimeType': 'audio/mp4',
          'audioSizeBytes': '54321',
        },
      ],
    }, 'c1');

    final comment = Comment.fromJson(data);
    final reply = comment.replies!.single;
    expect(reply.audioUrl, 'https://cdn.example.com/reply.m4a');
    expect(reply.audioObjectKey, 'audio-reviews/user2/book1/reply-c1/456.m4a');
    expect(reply.audioDurationMs, 18000);
    expect(reply.audioMimeType, 'audio/mp4');
    expect(reply.audioSizeBytes, 54321);
  });

  test('reader sharing and privacy fixes stay wired', () {
    final readerSource = File(
      'lib/src/presentation/screens/reader_screen.dart',
    ).readAsStringSync();
    final replySheetSource = File(
      'lib/src/presentation/components/book/comment_reply_sheet.dart',
    ).readAsStringSync();
    final mediaSource = File(
      'lib/src/presentation/widgets/writer_media_embed.dart',
    ).readAsStringSync();
    final commentSource = File(
      'lib/src/presentation/widgets/comment_widgets.dart',
    ).readAsStringSync();
    final reviewShareSource = File(
      'lib/src/presentation/components/review_share_card.dart',
    ).readAsStringSync();
    final androidSource = File(
      'android/app/src/main/kotlin/in/wreadom/app/MainActivity.kt',
    ).readAsStringSync();

    expect(commentSource, contains('hasReplyAudio'));
    expect(commentSource, contains('reply.audioObjectKey'));
    expect(commentSource, contains("_AudioCommentPlayer("));
    expect(
      replySheetSource,
      contains('liveBookCommentsProvider(widget.bookId)'),
    );
    expect(replySheetSource, contains('await _stopRecording()'));
    expect(readerSource, contains('await _stopAudioReviewRecording(null)'));
    expect(readerSource, contains('_showChapterReplySheet'));
    expect(readerSource, contains('CommentReplySheet(comment: comment'));
    expect(readerSource, contains('MethodChannel'));
    expect(readerSource, contains('setSecureReader'));
    expect(androidSource, contains('FLAG_SECURE'));
    expect(readerSource, contains('LaunchMode.externalApplication'));
    expect(mediaSource, contains('LaunchMode.externalApplication'));
    expect(readerSource, contains('sigmaX: 3, sigmaY: 3'));
    expect(readerSource, contains('_linePreservingText'));
    expect(readerSource, contains("tag == 'br'"));
    expect(reviewShareSource, contains('child: Center('));
    expect(reviewShareSource, contains('textAlign: TextAlign.center'));
  });

  test('reader quote sharing restores poem line breaks', () {
    expect(
      restoreReaderQuoteLineBreaks(
        'line oneline twoline three',
        '<p>line one</p><p>line two</p><p>line three</p>',
      ),
      'line one\nline two\nline three',
    );
    expect(
      restoreReaderQuoteLineBreaks(
        'line oneline twoline three',
        '<p>line one<br>line two<br>line three</p>',
      ),
      'line one\nline two\nline three',
    );
    expect(
      restoreReaderQuoteLineBreaks(
        'line oneline twoline three',
        'line one\nline two\nline three',
      ),
      'line one\nline two\nline three',
    );
    expect(
      restoreReaderQuoteLineBreaks(
        'line one line two',
        '<p>before</p><p>line one line two</p><p>after</p>',
      ),
      'line one line two',
    );
  });

  test(
    'message soft delete rules preserve participant-only deletedFor writes',
    () {
      final rulesSource = readFirestoreRules();

      expect(rulesSource, contains("onlyChanges(['deletedFor'])"));
      expect(
        rulesSource,
        contains(
          "request.resource.data.deletedFor.hasAll(resource.data.get('deletedFor', []))",
        ),
      );
      expect(
        rulesSource,
        contains('uid() in request.resource.data.deletedFor'),
      );
    },
  );

  test('onboarding is wired as a once-per-user signed-in gate', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final gateSource = File(
      'lib/src/presentation/screens/onboarding_gate.dart',
    ).readAsStringSync();
    final enArb = englishL10n();

    expect(mainSource, contains('OnboardingGate'));
    expect(mainSource, contains('userId: user.uid'));
    expect(gateSource, contains("onboarding_seen_\${widget.userId}_v2"));
    expect(gateSource, contains('setBool(_prefsKey, true)'));
    for (final key in [
      'onboardingWelcomeTitle',
      'onboardingWelcomeTagline',
      'onboardingReadersTitle',
      'onboardingAuthorsTitle',
      'onboardingCommunityTitle',
      'onboardingCommunityBulletMessage',
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
    expect(profileSource, contains('length: 6'));
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
    expect(routerSource, contains('LegalDocumentScreen'));
    expect(routerSource, isNot(contains('LaunchMode.externalApplication')));
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
    final serviceSource = File(
      'lib/src/data/services/notification_service.dart',
    ).readAsStringSync();
    final routerSource = File(
      'lib/src/presentation/routing/app_router.dart',
    ).readAsStringSync();

    expect(notificationSource, contains('_groupNotificationItems'));
    expect(
      notificationSource,
      contains(RegExp(r'displayItem\s*\.\s*notifications')),
    );
    expect(notificationSource, contains('_openingNotificationKey'));
    expect(notificationSource, contains('_markNotificationItemRead'));
    expect(notificationSource, contains('CircularProgressIndicator'));
    expect(notificationSource, contains('PostDetailArguments'));
    expect(notificationSource, contains('BookDetailArguments'));
    expect(resolverSource, contains('commentId'));
    expect(resolverSource, contains('replyId'));
    expect(serviceSource, contains('_duplicateNavigationWindow'));
    expect(serviceSource, contains('_isDuplicateNavigation'));
    expect(routerSource, contains('targetCommentId'));
    expect(routerSource, contains('targetReplyId'));
  });

  test('target comments and onboarding swipe hints are wired', () {
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
    final onboardingSource = File(
      'lib/src/presentation/screens/onboarding_gate.dart',
    ).readAsStringSync();
    final l10n = englishL10n();

    expect(postSource, contains('l10n.fromNotifications'));
    expect(bookSource, contains('targetCommentId'));
    expect(commentSource, contains('isTargetComment'));
    expect(commentSource, contains('isTargetReply'));
    expect(bookSource, isNot(contains('swipe_hint_seen_book_comments_v1')));
    expect(messagesSource, isNot(contains('swipe_hint_seen_messages_v1')));
    expect(
      conversationSource,
      isNot(contains('swipe_hint_seen_conversation_v1')),
    );
    expect(onboardingSource, contains('l10n.swipeHintBookComments'));
    expect(onboardingSource, contains('l10n.swipeHintMessages'));
    for (final key in [
      'targetComment',
      'fromNotifications',
      'removeReadingHistoryTitle',
      'removeReadingHistoryBody',
      'gotIt',
      'swipeHintBookComments',
      'swipeHintMessages',
    ]) {
      expect(l10n[key], isA<String>());
    }
  });

  test('web policy links are used from auth and routing surfaces', () {
    final loginSource = File(
      'lib/src/presentation/screens/login_screen.dart',
    ).readAsStringSync();
    final routerSource = File(
      'lib/src/presentation/routing/app_router.dart',
    ).readAsStringSync();
    final linkSource = File(
      'lib/src/utils/app_link_helper.dart',
    ).readAsStringSync();

    expect(linkSource, contains("privacyPolicyUrl = '\$origin/privacy'"));
    expect(linkSource, contains("termsUrl = '\$origin/terms'"));
    expect(loginSource, contains('AppRoutes.privacy'));
    expect(loginSource, contains('AppRoutes.terms'));
    expect(loginSource, contains('AppRouter.openExternalPolicy'));
    expect(routerSource, isNot(contains('LaunchMode.externalApplication')));
    expect(routerSource, contains('AppLinkHelper.privacyPolicyUrl'));
    expect(routerSource, contains('AppLinkHelper.termsUrl'));
    expect(routerSource, contains('openExternalPolicy'));
    expect(routerSource, contains('LegalDocumentScreen'));
  });

  test('chapter reads and reader progress are chapter scoped', () {
    final repoSource = File(
      'lib/src/data/repositories/firebase_book_repository.dart',
    ).readAsStringSync();
    final readerSource = File(
      'lib/src/presentation/screens/reader_screen.dart',
    ).readAsStringSync();
    final rulesSource = readFirestoreRules();

    expect(repoSource, contains('chapterKey'));
    expect(repoSource, contains('chapterIndex'));
    expect(repoSource, contains('Future<bool> recordBookView'));
    expect(readerSource, contains('_chapterContentStartKey'));
    expect(readerSource, contains('position.pixels / maxScroll'));
    expect(readerSource, contains('_incrementView(chapterIndex: index)'));
    expect(readerSource, contains('late SharedPreferences _sharedPreferences'));
    expect(
      readerSource,
      contains('_sharedPreferences = ref.read(sharedPreferencesProvider)'),
    );
    expect(readerSource, contains('_sharedPreferences.getString(prefsKey)'));
    expect(readerSource, contains('if (!mounted) return;'));
    expect(rulesSource, contains('chapterKey'));
    expect(rulesSource, contains('chapterIndex'));
  });

  test('homepage cache warming and background refresh are wired', () {
    final homeProviderSource = File(
      'lib/src/presentation/providers/homepage_providers.dart',
    ).readAsStringSync();
    final dailyTopicProviderSource = File(
      'lib/src/presentation/providers/daily_topic_providers.dart',
    ).readAsStringSync();
    final loginSource = File(
      'lib/src/presentation/screens/login_screen.dart',
    ).readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();
    final homeScreenSource = File(
      'lib/src/presentation/screens/home_books_screen.dart',
    ).readAsStringSync();
    final homeFeedSource = File(
      'lib/src/presentation/screens/home_feed_screen.dart',
    ).readAsStringSync();
    final profileSettingsSource = File(
      'lib/src/presentation/screens/profile_settings_screen.dart',
    ).readAsStringSync();
    final dailyTopicBuildSource = dailyTopicProviderSource.substring(
      dailyTopicProviderSource.indexOf('FutureOr<List<DailyTopic>> build()'),
      dailyTopicProviderSource.indexOf('Future<void> fetchMore()'),
    );

    expect(homeProviderSource, contains('warmPublicHomepageCache'));
    expect(homeProviderSource, contains('warmUserHomepageCache'));
    expect(homeProviderSource, contains('_queueHomepageBackgroundRefresh'));
    expect(homeProviderSource, contains('_refreshHomepageCachesInBackground'));
    expect(homeProviderSource, contains('_homepageGenreBooksCacheKeyPrefix'));
    expect(homeScreenSource, contains('_currentBooksOrNull'));
    expect(homeFeedSource, contains('RefreshIndicator'));
    expect(homeFeedSource, contains('AlwaysScrollableScrollPhysics'));
    expect(profileSettingsSource, contains('ExpansionTile'));
    expect(profileSettingsSource, contains('initiallyExpanded: false'));
    expect(dailyTopicProviderSource, contains('daily_topics_cache_v1'));
    expect(dailyTopicBuildSource, contains('_readCachedTopics()'));
    expect(
      dailyTopicBuildSource,
      contains('_queueBackgroundRefresh(metadataTopics)'),
    );
    expect(
      dailyTopicBuildSource,
      isNot(contains('await _fetchRemoteTopics()')),
    );
    expect(loginSource, contains('warmPublicHomepageCache(ref)'));
    expect(mainSource, contains('warmUserHomepageCache(ref)'));
  });
}
