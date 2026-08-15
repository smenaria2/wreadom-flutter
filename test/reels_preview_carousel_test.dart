import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/feed_post.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';
import 'package:librebook_flutter/src/presentation/widgets/reels_preview_carousel.dart';

void main() {
  FeedPost post({
    String id = 'post-1',
    String text = 'A story worth reading.',
    String? imageUrl,
    String? bookCover,
  }) {
    return FeedPost(
      id: id,
      userId: 'user-1',
      username: 'writer',
      type: 'post',
      text: text,
      timestamp: 1,
      likes: const [],
      visibility: 'public',
      imageUrl: imageUrl,
      bookCover: bookCover,
    );
  }

  Widget app(FeedPost value) {
    return MaterialApp(
      routes: {
        AppRoutes.feedReels: (_) => const Scaffold(body: Text('Reel opened')),
      },
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(
            child: SizedBox(height: 180, child: ReelPreviewCard(post: value)),
          ),
        ),
      ),
    );
  }

  testWidgets('shows post text over post images and book covers', (
    tester,
  ) async {
    for (final value in [
      post(imageUrl: 'https://example.com/post.jpg'),
      post(id: 'post-2', bookCover: 'https://example.com/book.jpg'),
    ]) {
      await tester.pumpWidget(app(value));

      expect(find.text('A story worth reading.'), findsOneWidget);
    }
  });

  testWidgets('shows trimmed text on gradient cards and skips empty text', (
    tester,
  ) async {
    await tester.pumpWidget(app(post(text: '  Gradient story copy.  ')));
    expect(find.text('Gradient story copy.'), findsOneWidget);

    await tester.pumpWidget(app(post(text: '   ')));
    expect(find.text('Gradient story copy.'), findsNothing);
    expect(find.text('writer'), findsOneWidget);
  });

  testWidgets('caps long overlay copy and keeps the card tappable', (
    tester,
  ) async {
    const longText =
        'A long story preview that should stay inside the compact card without '
        'covering the author name or overflowing the available space.';
    await tester.pumpWidget(app(post(text: longText)));

    final overlay = tester.widget<Text>(find.text(longText));
    expect(overlay.maxLines, 4);
    expect(overlay.overflow, TextOverflow.ellipsis);

    await tester.tap(find.text(longText));
    await tester.pumpAndSettle();
    expect(find.text('Reel opened'), findsOneWidget);
  });
}
