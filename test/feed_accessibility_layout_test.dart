// ignore_for_file: subtype_of_sealed_class

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/repositories/leaderboard_repository.dart';
import 'package:librebook_flutter/src/domain/models/leaderboard_model.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';
import 'package:librebook_flutter/src/presentation/components/profile/leaderboard_tab.dart';
import 'package:librebook_flutter/src/presentation/components/ai_edit_dialog.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Fakes for LeaderboardRepository unit test
class FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  final bool _exists;
  FakeDocumentSnapshot(this._data, this._exists);

  @override
  bool get exists => _exists;
  @override
  Map<String, dynamic>? data() => _data;
}

class FakeDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  final DocumentSnapshot<Map<String, dynamic>> _snapshot;
  FakeDocumentReference(this._snapshot);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async => _snapshot;
}

class FakeQuerySnapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;
  FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;
}

class FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  final Future<QuerySnapshot<Map<String, dynamic>>> Function() _onGet;
  FakeQuery(this._onGet);

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) => _onGet();
}

class FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  final Map<String, DocumentSnapshot<Map<String, dynamic>>> _docs;
  final Future<QuerySnapshot<Map<String, dynamic>>> Function()? onQueryGet;

  FakeCollectionReference(this._docs, {this.onQueryGet});

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final snap = _docs[path] ?? FakeDocumentSnapshot({}, false);
    return FakeDocumentReference(snap);
  }

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Object? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return FakeQuery(onQueryGet!);
  }
}

class FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, FakeCollectionReference> _collections;
  FakeFirestore(this._collections);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _collections[path]!;
  }
}

void main() {
  group('Leaderboard Fixes', () {
    test('LeaderboardRepository enrichment failure is non-fatal', () async {
      final latestLeaderboardData = {
        'lastUpdatedAt': 12345678,
        'rankings': [
          {'rank': 1, 'userId': 'user-1', 'displayName': 'User One', 'points': 100},
          {'rank': 2, 'userId': 'user-2', 'displayName': 'User Two', 'points': 90},
        ]
      };
      final fakeDocSnap = FakeDocumentSnapshot(latestLeaderboardData, true);
      final fakeLeaderboardCol = FakeCollectionReference({
        'weekly_author_latest': fakeDocSnap,
      });
      final fakeUsersCol = FakeCollectionReference({}, onQueryGet: () {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Simulated users query failure',
        );
      });

      final firestore = FakeFirestore({
        'leaderboards': fakeLeaderboardCol,
        'users': fakeUsersCol,
      });

      final repository = LeaderboardRepository(firestore: firestore);
      final results = await repository.fetchLeaderboard(period: 'weekly', type: 'author');

      expect(results.length, 2);
      expect(results[0].userId, 'user-1');
      expect(results[0].points, 100);
      expect(results[0].allTimePoints, isNull);
    });

    testWidgets('fresh lifetime points are not overwritten with stale current-user data', (tester) async {
      final currentUser = UserModel(
        id: 'user-me',
        username: 'me',
        email: 'me@example.com',
        displayName: 'Me',
        readingHistory: [],
        savedBooks: [],
        bookmarks: [],
        readerPoints: 120, // stale points
      );

      final rankings = [
        const LeaderboardRank(
          rank: 1,
          userId: 'user-me',
          displayName: 'Me',
          photoUrl: '',
          points: 50,
          allTimePoints: 999, // fresh points (tier 2 threshold at 500)
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LeaderboardTab(
              currentUser: currentUser,
              initialCategory: 'reader',
              initialPeriod: 'weekly',
              onUserClick: (_) {},
              leaderboardLoader: ({required period, required type}) async => rankings,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // For reader, 999 points is "CURIOUS READER" (tier 2), while 120 points is "BEGINNER READER" (tier 1)
      expect(find.text('CURIOUS READER'), findsOneWidget);
      expect(find.text('BEGINNER READER'), findsNothing);
    });
  });

  group('Home Feed Accessibility & Layout Static Tests', () {
    test('Feed scope selector source code includes semantics, 48dp target, scrollable', () {
      final source = File('lib/src/presentation/screens/home_feed_screen.dart').readAsStringSync();

      expect(source, contains('SingleChildScrollView('));
      expect(source, contains('scrollDirection: Axis.horizontal'));
      expect(source, contains('Semantics('));
      expect(source, contains('label: labelFor(filter)'));
      expect(source, contains('selected: isSelected'));
      expect(source, contains('button: true'));
      expect(source, contains('minWidth: 48'));
      expect(source, contains('minHeight: 48'));
    });

    test('Filter button uses localized keys', () {
      final source = File('lib/src/presentation/screens/home_feed_screen.dart').readAsStringSync();

      expect(source, contains('tooltip: l10n.feedFilterTooltip'));
      expect(source, contains('l10n.feedFilterLabel'));
    });

    test('Filter keys exist in ARB files', () {
      final enArb = File('lib/l10n/app_en.arb').readAsStringSync();
      final hiArb = File('lib/l10n/app_hi.arb').readAsStringSync();

      expect(enArb, contains('"feedFilterLabel": "Filter"'));
      expect(enArb, contains('"feedFilterTooltip": "Filter posts"'));
      expect(hiArb, contains('"feedFilterLabel": "फ़िल्टर"'));
      expect(hiArb, contains('"feedFilterTooltip": "पोस्ट फ़िल्टर करें"'));
    });
  });

  group('Notification Service TTS Channel Versioning', () {
    test('TTS channel has been versioned and cleaned up in source code', () {
      final source = File('lib/src/data/services/notification_service.dart').readAsStringSync();

      expect(source, contains('reader_tts_channel_v2'));
      expect(
        source,
        contains(
          RegExp(
            r"deleteNotificationChannel\(\s*channelId:\s*'reader_tts_channel',?\s*\)",
          ),
        ),
      );
      expect(
        source,
        isNot(
          contains(
            RegExp(
              r"AndroidNotificationChannel\(\s*'reader_tts_channel',",
            ),
          ),
        ),
      );
    });
  });

  group('AI Editor Dialog Prioritization', () {
    testWidgets('AI Edit Dialog displays Gemini first (prioritized)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: AiEditDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final geminiFinder = find.text('Gemini');
      final chatGptFinder = find.text('ChatGPT');

      expect(geminiFinder, findsOneWidget);
      expect(chatGptFinder, findsOneWidget);

      final geminiY = tester.getTopLeft(geminiFinder).dy;
      final chatGptY = tester.getTopLeft(chatGptFinder).dy;

      // Gemini must be located above ChatGPT
      expect(geminiY, lessThan(chatGptY));
    });
  });

  group('New Feed, Layout, & Sharing Fixes', () {
    test('Feed story play button is removed', () {
      final source = File('lib/src/presentation/widgets/reels_preview_carousel.dart').readAsStringSync();
      expect(source, isNot(contains('Icons.play_arrow_rounded')));
      expect(source, isNot(contains('Middle Play Badge')));
    });

    test('Author name resolution falls back correctly', () {
      final carouselSource = File('lib/src/presentation/widgets/reels_preview_carousel.dart').readAsStringSync();
      final reelsSource = File('lib/src/presentation/screens/feed_reels_screen.dart').readAsStringSync();

      expect(carouselSource, contains('post.penName != null && post.penName!.trim().isNotEmpty'));
      expect(carouselSource, contains('post.displayName != null && post.displayName!.trim().isNotEmpty'));

      expect(reelsSource, contains('post.displayName != null && post.displayName!.trim().isNotEmpty'));
      expect(reelsSource, contains('post.penName != null && post.penName!.trim().isNotEmpty'));
    });

    test('Question card font size is reduced to 13', () {
      final source = File('lib/src/presentation/screens/home_feed_screen.dart').readAsStringSync();
      expect(source, contains('fontSize: 13'));
      expect(source, contains('theme.textTheme.bodyMedium'));
    });

    test('Quote sharing localization keys exist and are integrated', () {
      final enArb = File('lib/l10n/app_en.arb').readAsStringSync();
      final hiArb = File('lib/l10n/app_hi.arb').readAsStringSync();
      final readerSource = File('lib/src/presentation/screens/reader_screen.dart').readAsStringSync();
      final sheetSource = File('lib/src/presentation/components/book/quote_share_preview_sheet.dart').readAsStringSync();

      expect(enArb, contains('"quoteFromBookSubject": "Quote from {title}"'));
      expect(enArb, contains('"shareQuoteMessage"'));
      expect(hiArb, contains('"quoteFromBookSubject":'));
      expect(hiArb, contains('"shareQuoteMessage"'));

      expect(readerSource, contains('l10n.quoteFromBookSubject(widget.book.title)'));
      expect(readerSource, contains('l10n.shareQuoteMessage('));

      expect(sheetSource, contains('widget.shareText'));
      expect(sheetSource, contains('l10n.quoteFromBookSubject(widget.book.title)'));
    });

    test('Adaptive Review Share Card Size works based on comment length', () {
      final source = File('lib/src/presentation/components/review_share_card.dart').readAsStringSync();

      expect(source, contains('final isLong = post.text.trim().length > 220;'));
      expect(source, contains('_buildPortraitCard('));
      expect(source, contains('_buildLandscapeCard('));
      expect(source, contains('height: 960')); // Landscape height
      expect(source, contains('height: 2172')); // Portrait A4 height
    });
  });
}
