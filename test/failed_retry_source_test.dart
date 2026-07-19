import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final notifierSource = File(
    'lib/src/presentation/providers/local_comments_notifier.dart',
  ).readAsStringSync();
  final feedCommentsSource = File(
    'lib/src/presentation/components/feed_post_card.dart',
  ).readAsStringSync();
  final bookReplySource = File(
    'lib/src/presentation/components/book/comment_reply_sheet.dart',
  ).readAsStringSync();
  final reviewSource = File(
    'lib/src/presentation/components/book/review_sheet.dart',
  ).readAsStringSync();

  test('failed comments retain an explicit destination for retry', () {
    expect(
      notifierSource,
      contains('enum FailedCommentTarget { book, feedPost }'),
    );
    expect(notifierSource, contains('switch (item.target)'));
    expect(notifierSource, isNot(contains("startsWith('post_')")));
    expect(notifierSource, isNot(contains('RegExp')));
    expect(
      feedCommentsSource,
      contains('target: FailedCommentTarget.feedPost'),
    );
    expect(bookReplySource, contains('target: FailedCommentTarget.book'));
  });

  test('background review publishing uses a live provider container', () {
    expect(reviewSource, contains('ProviderScope.containerOf(context'));
    expect(
      reviewSource,
      contains('container.read(feedRepositoryProvider).createFeedPost(post)'),
    );
    expect(reviewSource, contains('failedReviewsProvider.notifier'));
  });
}
