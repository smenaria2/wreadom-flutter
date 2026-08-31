import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/feed_post.dart';
import 'package:librebook_flutter/src/presentation/components/book/shared_review_card.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

void main() {
  testWidgets('SharedReviewCard renders reviewer attribution and quote',
      (tester) async {
    final post = FeedPost(
      userId: 'sharer123',
      username: 'sharer_user',
      displayName: 'Sharer User',
      type: 'review',
      bookId: 'book123',
      bookTitle: 'Flutter Architecture',
      bookAuthorName: 'Jane Author',
      text: 'Must read this review!',
      quote: 'This book completely changed my perspectives on state management.',
      rating: 5,
      targetUserId: 'original_reviewer1',
      targetUsername: 'top_reviewer',
      targetUserDisplayName: 'Alice Critic',
      likes: const [],
      visibility: 'public',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SharedReviewCard(
            post: post,
            bookTitle: 'Flutter Architecture',
            bookAuthorName: 'Jane Author',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alice Critic'), findsOneWidget);
    expect(
      find.text('This book completely changed my perspectives on state management.'),
      findsOneWidget,
    );
    expect(find.text('Flutter Architecture'), findsNWidgets(2));
    expect(find.text('by Jane Author'), findsOneWidget);
  });
}
