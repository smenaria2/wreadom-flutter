import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/leaderboard_model.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/components/profile/leaderboard_info_modal.dart';
import 'package:librebook_flutter/src/presentation/components/profile/leaderboard_tab.dart';
import 'package:librebook_flutter/src/presentation/providers/auth_providers.dart';

void main() {
  const currentUser = UserModel(
    id: 'current-user',
    username: 'reader',
    email: 'reader@example.com',
    displayName: 'Test Reader',
    readingHistory: [],
    savedBooks: [],
    bookmarks: [],
    readerPoints: 4,
    readerRank: 95,
  );

  List<LeaderboardRank> topTwenty() => List.generate(
    20,
    (index) => LeaderboardRank(
      rank: index + 1,
      userId: 'leader-${index + 1}',
      displayName: 'Leader ${index + 1}',
      photoUrl: '',
      points: 100 - index,
    ),
  );

  Future<void> pumpLeaderboard(
    WidgetTester tester, {
    int targetPoints = 4,
    int targetRank = 95,
    List<LeaderboardRank>? rankings,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LeaderboardTab(
            currentUser: currentUser,
            initialCategory: 'reader',
            initialPeriod: 'total',
            targetUserId: currentUser.id,
            targetUserReaderPoints: targetPoints,
            targetUserReaderRank: targetRank,
            targetUserDisplayName: currentUser.displayName,
            onUserClick: (_) {},
            leaderboardLoader:
                ({required String period, required String type}) async {
                  expect(period, 'total');
                  expect(type, 'reader');
                  return rankings ?? topTwenty();
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'signed-in reader outside top 20 is revealed once and can return to top',
    (tester) async {
      await pumpLeaderboard(tester);

      expect(find.text('Test Reader'), findsOneWidget);
      expect(find.text('95'), findsOneWidget);
      expect(find.text('YOU'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(find.text('Leader 1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Leader 1'), findsOneWidget);
      expect(find.text('Test Reader'), findsNothing);
    },
  );

  testWidgets('target already in top 20 is not duplicated', (tester) async {
    final rankings = topTwenty();
    rankings[9] = const LeaderboardRank(
      rank: 10,
      userId: 'current-user',
      displayName: 'Test Reader',
      photoUrl: '',
      points: 4,
    );

    await pumpLeaderboard(tester, targetRank: 10, rankings: rankings);

    expect(find.text('Test Reader'), findsOneWidget);
  });

  testWidgets('zero-point target is not appended or auto-scrolled', (
    tester,
  ) async {
    await pumpLeaderboard(tester, targetPoints: 0);

    expect(find.text('Test Reader'), findsNothing);
    expect(find.text('Leader 1'), findsOneWidget);
  });

  testWidgets('Rank System modal displays revised English wording', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(currentUser)),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: LeaderboardInfoModal()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wreadom Rank System'), findsOneWidget);
    expect(find.text('How to Earn Points'), findsOneWidget);
    expect(
      find.text(
        'Author can earn points when they publish content, readers read the content or get review on the content.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Reader can earn point by reading content and reviewing content.',
      ),
      findsOneWidget,
    );
  });
}
