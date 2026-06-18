import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/comment.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/providers/auth_providers.dart';
import 'package:librebook_flutter/src/presentation/widgets/comment_widgets.dart';

void main() {
  const longChapterTitle =
      'A chapter title that is deliberately much longer than the chip';
  const review = Comment(
    id: 'review-1',
    bookId: 'book-1',
    bookTitle: 'Test Book',
    userId: 'reader-1',
    username: 'reader',
    displayName: 'Reader',
    text: 'A thoughtful review.',
    rating: 4,
    chapterTitle: longChapterTitle,
    chapterIndex: 1,
    chapterId: 'chapter-2',
    timestamp: 1,
  );

  Widget testApp({required int chapterCount, bool showContext = true}) {
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
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CommentTile(
              comment: review,
              bookId: 'book-1',
              bookTitle: 'Test Book',
              bookAuthorId: 'author-1',
              bookAuthorName: 'Author',
              chapterCount: chapterCount,
              showChapterContext: showContext,
              onReply: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('multi chapter review shows truncated chapter after rating', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(testApp(chapterCount: 3));
    await tester.pump();

    final chapterFinder = find.text(longChapterTitle);
    expect(chapterFinder, findsOneWidget);

    final chapterText = tester.widget<Text>(chapterFinder);
    expect(chapterText.maxLines, 1);
    expect(chapterText.overflow, TextOverflow.ellipsis);
    expect(chapterText.softWrap, isFalse);

    final lastStar = find.byIcon(Icons.star_border_rounded);
    expect(lastStar, findsOneWidget);
    expect(
      tester.getTopLeft(chapterFinder).dx,
      greaterThan(tester.getTopRight(lastStar).dx),
    );
  });

  testWidgets('single chapter review hides chapter context', (tester) async {
    await tester.pumpWidget(testApp(chapterCount: 1));
    await tester.pump();

    expect(find.text(longChapterTitle), findsNothing);
  });

  testWidgets('chapter discussion context suppresses recursive chapter chip', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(chapterCount: 3, showContext: false));
    await tester.pump();

    expect(find.text(longChapterTitle), findsNothing);
  });
}
