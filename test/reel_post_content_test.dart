import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/feed_post.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/components/feed_post_card.dart';
import 'package:librebook_flutter/src/presentation/components/reel_post_content.dart';

void main() {
  FeedPost post({
    String type = 'post',
    String text = 'A quiet page made for reading.',
    String? quote,
    int? rating,
    String? question,
    String? imageUrl,
    List<StoryImage>? images,
    dynamic bookId,
    String? bookTitle,
  }) {
    return FeedPost(
      id: 'post-1',
      userId: 'user-1',
      username: 'writer',
      displayName: 'Writer Name',
      type: type,
      text: text,
      quote: quote,
      rating: rating,
      question: question,
      imageUrl: imageUrl,
      images: images,
      bookId: bookId,
      bookTitle: bookTitle,
      timestamp: 1,
      likes: const [],
      visibility: 'public',
    );
  }

  Widget app(FeedPost value) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox.expand(
          child: ReelPostContent(
            post: value,
            isActive: true,
            onDoubleTapLike: () {},
            onBookTap: () {},
            onQuestionTap: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders editorial text without regular feed chrome', (
    tester,
  ) async {
    await tester.pumpWidget(app(post()));

    expect(find.text('A quiet page made for reading.'), findsOneWidget);
    expect(find.byType(FeedPostCard), findsNothing);
    expect(find.text('Writer Name'), findsNothing);
    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
  });

  testWidgets('renders quote, review, question, and book content', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        post(
          type: 'review',
          text: 'A thoughtful review.',
          rating: 4,
          question: 'What did this story change?',
          bookId: 'book-1',
          bookTitle: 'The Test Book',
        ),
      ),
    );

    expect(find.text('What did this story change?'), findsOneWidget);
    expect(find.text('A thoughtful review.'), findsOneWidget);
    expect(find.text('The Test Book'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));

    await tester.pumpWidget(
      app(post(type: 'quote', text: '', quote: 'Words deserve room.')),
    );
    expect(find.text('Words deserve room.'), findsOneWidget);
  });

  testWidgets('supports imageUrl and StoryImage collections together', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        post(
          text: '',
          imageUrl: 'https://example.com/cover.jpg',
          images: const [
            StoryImage(
              id: 'image-2',
              url: 'https://example.com/second.jpg',
              caption: 'Second page',
              likes: [],
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2 photos'), findsOneWidget);
    expect(find.text('Second page'), findsOneWidget);
  });
}
