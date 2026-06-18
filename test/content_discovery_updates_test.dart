import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/utils/profile_search_utils.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/domain/models/feed_post.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/widgets/see_more_content_button.dart';
import 'package:librebook_flutter/src/utils/book_collaboration_utils.dart';

void main() {
  test('question answer posts preserve their stable leaf id', () {
    const post = FeedPost(
      id: 'answer-1',
      userId: 'reader-1',
      username: 'reader',
      type: 'post',
      bookId: 'book-1',
      text: 'My answer',
      timestamp: 1,
      likes: [],
      visibility: 'public',
      question: 'Why?',
      questionLeafId: 'leaf-question-1',
    );

    expect(FeedPost.fromJson(post.toJson()).questionLeafId, 'leaf-question-1');
  });

  test('profile search terms cover words, email and Hindi prefixes', () {
    final terms = buildProfileSearchTerms(
      username: 'sumit_reader',
      email: 'sumit@example.com',
      displayName: 'Sumit Menaria',
      penName: 'कहानीकार',
    );

    expect(terms, containsAll(['sum', 'men', 'sumit@', 'कहा']));
    expect(normalizeProfileSearchText('  SUMIT   Menaria '), 'sumit menaria');
  });

  test('unpublished books are visible only to their accepted authors', () {
    final draft = _book(
      status: 'draft',
      authorId: 'author-1',
      collaboratorId: 'author-2',
      collaborationStatus: collaborationStatusAccepted,
      authorIds: const ['author-1', 'author-2'],
    );

    expect(canViewBook(draft, null), isFalse);
    expect(canViewBook(draft, 'reader-1'), isFalse);
    expect(canViewBook(draft, 'author-1'), isTrue);
    expect(canViewBook(draft, 'author-2'), isTrue);
    expect(canViewBook(_book(status: 'published'), null), isTrue);
    expect(canViewBook(_book(source: 'archive'), null), isTrue);
  });

  testWidgets('shared pagination action uses See more content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SeeMoreContentButton(onPressed: () {})),
      ),
    );

    expect(find.text('See more content'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
  });

  test('question answer previews show two lines and open post details', () {
    final source = File(
      'lib/src/presentation/components/book/leaf_components.dart',
    ).readAsStringSync();

    expect(source, contains('questionLeafAnswersProvider'));
    expect(source, contains('maxLines: 2'));
    expect(source, contains('AppRoutes.postDetail'));
    expect(source, contains('answer.displayName'));
  });

  test('book review metadata uses separated layout and darker light stars', () {
    final source = File(
      'lib/src/presentation/widgets/comment_widgets.dart',
    ).readAsStringSync();

    expect(source, contains('runSpacing: 8'));
    expect(source, contains('const Color(0xFF9A5700)'));
    expect(source, contains('const SizedBox(height: 8)'));
  });
}

Book _book({
  String? status,
  String? source,
  String? authorId,
  String? collaboratorId,
  String? collaborationStatus,
  List<String>? authorIds,
}) {
  return Book(
    id: 'book-1',
    title: 'Book',
    authors: const [],
    subjects: const [],
    languages: const [],
    formats: const {},
    downloadCount: 0,
    mediaType: 'texts',
    bookshelves: const [],
    status: status,
    source: source,
    authorId: authorId,
    collaboratorId: collaboratorId,
    collaborationStatus: collaborationStatus,
    authorIds: authorIds,
  );
}
