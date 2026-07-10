import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/components/profile/premium_ranks_widget.dart';
import 'package:librebook_flutter/src/presentation/widgets/glass_surface.dart';
import 'package:librebook_flutter/src/utils/tier_utils.dart';

void main() {
  testWidgets('hides both inactive tracks without reserving a card', (
    tester,
  ) async {
    await _pump(tester, _user());
    expect(find.byType(GlassSurface), findsNothing);
  });

  testWidgets('author starts on author status and flips to reader status', (
    tester,
  ) async {
    await _pump(
      tester,
      _user(
        authorPoints: 500,
        authorRank: 12,
        readerPoints: 5000,
        readerRank: 4,
      ),
    );
    expect(find.text('AUTHOR STATUS'), findsOneWidget);
    expect(find.text('Storyteller'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    await tester.tap(find.text('Storyteller'));
    await tester.pumpAndSettle();

    expect(find.text('READER STATUS'), findsOneWidget);
    expect(find.text('Word Enthusiast'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('reader-only card does not flip', (tester) async {
    await _pump(tester, _user(readerPoints: 500, readerRank: 8));
    expect(find.text('READER STATUS'), findsOneWidget);
    await tester.tap(find.text('Curious Reader'));
    await tester.pumpAndSettle();
    expect(find.text('READER STATUS'), findsOneWidget);
    expect(find.text('AUTHOR STATUS'), findsNothing);
  });

  testWidgets('arrow selects visible track without flipping card', (
    tester,
  ) async {
    RankTrack? selected;
    await _pump(
      tester,
      _user(authorPoints: 500, authorRank: 12, readerPoints: 500),
      onTrackSelected: (track) => selected = track,
    );

    await tester.tap(find.byKey(const ValueKey('rank-leaderboard-arrow')));
    await tester.pump();

    expect(selected, RankTrack.author);
    expect(find.text('AUTHOR STATUS'), findsOneWidget);
  });

  testWidgets('reduced motion switches faces immediately', (tester) async {
    await _pump(
      tester,
      _user(authorPoints: 500, readerPoints: 500),
      disableAnimations: true,
    );
    await tester.tap(find.text('Storyteller'));
    await tester.pump();
    expect(find.text('Curious Reader'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  UserModel user, {
  ValueChanged<RankTrack>? onTrackSelected,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = const Size(600, 800);
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
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: PremiumRanksWidget(
              user: user,
              onTrackSelected: onTrackSelected,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

UserModel _user({
  int? authorPoints,
  int? authorRank,
  int? readerPoints,
  int? readerRank,
}) => UserModel(
  id: 'user-1',
  username: 'reader',
  email: 'reader@example.com',
  displayName: 'Reader',
  readingHistory: const [],
  savedBooks: const [],
  bookmarks: const [],
  authorPoints: authorPoints,
  authorRank: authorRank,
  readerPoints: readerPoints,
  readerRank: readerRank,
);
