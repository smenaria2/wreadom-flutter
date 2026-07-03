import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/feed_post.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/components/feed_post_card.dart';
import 'package:librebook_flutter/src/presentation/providers/auth_providers.dart';

void main() {
  Widget testApp(FeedPost post) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: FeedPostCard(post: post, openOnTap: false)),
      ),
    );
  }

  testWidgets('renders first supported link preview after post text', (
    tester,
  ) async {
    const post = FeedPost(
      id: 'post-1',
      userId: 'user-1',
      username: 'writer',
      displayName: 'Writer',
      type: 'post',
      text:
          'A plain link https://example.com/story then a video https://youtu.be/dQw4w9WgXcQ.',
      timestamp: 1,
      likes: [],
      visibility: 'public',
    );

    await tester.pumpWidget(testApp(post));
    await tester.pump();

    expect(find.text(post.text), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('https://youtu.be/dQw4w9WgXcQ'), findsOneWidget);
    expect(find.text('Unsupported link'), findsNothing);
  });
}
