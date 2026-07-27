import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/leaderboard_model.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/components/profile/profile_share_card.dart';

void main() {
  test(
    'leaderboard and public profile keep the requested rank presentation',
    () {
      final leaderboard = File(
        'lib/src/presentation/components/profile/leaderboard_tab.dart',
      ).readAsStringSync();
      final publicProfile = File(
        'lib/src/presentation/screens/public_profile_screen.dart',
      ).readAsStringSync();

      expect(leaderboard, isNot(contains("value: 'daily'")));
      expect(leaderboard, isNot(contains('PremiumRanksWidget(')));
      expect(leaderboard, contains('Scrollable.ensureVisible'));
      expect(leaderboard, contains('_scrollController.jumpTo(0)'));
      expect(leaderboard, contains('(_activeTargetPoints ?? 0) <= 0'));
      expect(leaderboard, isNot(contains('Ã')));
      expect(leaderboard, contains('appendTarget'));
      expect(leaderboard, isNot(contains('_buildPinnedUserCard')));
      expect(
        leaderboard.indexOf("value: 'total'"),
        lessThan(leaderboard.indexOf("value: 'monthly'")),
      );
      expect(
        leaderboard,
        contains('final isHighlighted = entry.userId == highlightedUserId;'),
      );
      expect(leaderboard, isNot(contains('entry.userId == currentUserId ||')));
      expect(
        publicProfile,
        contains('PremiumRanksWidget(user: user, compact: true)'),
      );
      expect(publicProfile, contains('_ExpandableBio(text: user.bio!)'));
    },
  );

  testWidgets('share card fits a long name and places ranks below stats', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const longName =
        'A Very Long Wreadom Creator Name That Must Fit Completely';
    final user = UserModel(
      id: 'user-1',
      username: 'creator',
      email: 'creator@example.com',
      displayName: longName,
      readingHistory: const [],
      savedBooks: const [],
      bookmarks: const [],
      followersCount: 20,
      followingCount: 10,
      authorRank: 4,
      readerRank: 8,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ProfileShareCard(user: user, worksCount: 6)),
      ),
    );
    await tester.pump();

    expect(find.text(longName), findsOneWidget);
    expect(find.byType(FittedBox), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-share-wreadom-logo')),
      findsOneWidget,
    );
    expect(find.text('WREADOM CREATOR'), findsOneWidget);
    expect(find.text('wreadom.in'), findsOneWidget);

    expect(
      tester.getTopLeft(find.text('FOLLOWERS')).dy,
      lessThan(tester.getTopLeft(find.text('Author rank')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  test('leaderboard snapshot reads lifetime points for the selected track', () {
    final reader = LeaderboardRank.fromMap({
      'rank': 4,
      'userId': 'reader',
      'points': 60,
      'readerPoints': 600,
    }, type: 'reader');
    final author = LeaderboardRank.fromMap({
      'rank': 7,
      'userId': 'author',
      'points': 80,
      'authorPoints': 1200,
    });

    expect(reader.points, 60);
    expect(reader.allTimePoints, 600);
    expect(author.points, 80);
    expect(author.allTimePoints, 1200);
  });

  test('leaderboard names skip blank profile fields', () {
    expect(
      resolveLeaderboardDisplayName({
        'penName': '  ',
        'displayName': ' आशुतोष गुप्ता ',
        'username': 'ashutosh',
      }),
      'आशुतोष गुप्ता',
    );
    expect(
      LeaderboardRank.fromMap({
        'rank': 18,
        'userId': 'ashutosh',
        'displayName': '',
        'username': 'ashutosh',
        'photoURL': '',
        'points': 122,
      }).displayName,
      'ashutosh',
    );
  });
}
