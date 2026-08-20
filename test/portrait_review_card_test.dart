import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/feed_post.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/components/portrait_review_card.dart';

void main() {
  testWidgets('PortraitReviewCard renders compact header, review text, and prominent branding', (tester) async {
    const post = FeedPost(
      id: 'post-1',
      userId: 'user-1',
      username: 'mayank',
      displayName: 'Mayank Upadhyay',
      type: 'review',
      bookId: 'book-1',
      bookTitle: 'ईहा',
      bookAuthorName: 'Sumit Menaria',
      rating: 5,
      text: 'इस भाग में बहुत सारी ऐसी पंक्तियां है जो अपने आप में बेहतरीन है लेकिन उन सभी में मुझे ये पंक्ति सबसे अच्छी लगी कि इच्छा पूरी होने के बाद भी शायद कुछ शेष बच जाता है इच्छा करने को कि जैसा चाहते थे वैसा नहीं हुई और इन्हीं अनगिनत इच्छाओं को रास्ता बनाकर जीवन आगे बढ़ता रहता है।\n\nईहा ने मनन को गुस्से में घटिया बोल दिया... ये शब्द बहुत खतरनाक है अपने आप में...',
      timestamp: 123456789,
      likes: [],
      visibility: 'public',
    );

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PortraitReviewCard(
              post: post,
              bookTitle: 'ईहा',
              bookAuthorName: 'Sumit Menaria',
              reviewer: 'Mayank Upadhyay',
              rating: 5.0,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify book title and author are rendered
    expect(find.text('ईहा'), findsAtLeastNWidgets(1));
    expect(find.text('Sumit Menaria'), findsAtLeastNWidgets(1));

    // Verify reviewer name is rendered
    expect(find.text('Mayank Upadhyay'), findsOneWidget);

    // Verify prominent wreadom.in branding is rendered
    expect(find.text('wreadom.in'), findsOneWidget);

    // Verify rating text is rendered
    expect(find.textContaining('5.0'), findsOneWidget);
  });
}
