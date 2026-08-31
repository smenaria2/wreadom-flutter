import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/comment.dart';
import 'package:librebook_flutter/src/presentation/components/reader/chapter_review_teaser_card.dart';

void main() {
  group('findTopChapterReview', () {
    final comment1 = Comment(
      id: 'c1',
      bookId: 'b1',
      chapterId: 'ch1',
      userId: 'u1',
      username: 'alice',
      displayName: 'Alice',
      text: 'Good chapter!',
      timestamp: 1000,
    );

    final comment2 = Comment(
      id: 'c2',
      bookId: 'b1',
      chapterId: 'ch1',
      userId: 'u2',
      username: 'bob',
      displayName: 'Bob',
      text: 'Amazing chapter with 5 stars!',
      rating: 5,
      timestamp: 2000,
    );

    final comment3 = Comment(
      id: 'c3',
      bookId: 'b1',
      chapterId: 'ch2',
      userId: 'u3',
      username: 'charlie',
      displayName: 'Charlie',
      text: 'Chapter 2 review',
      rating: 4,
      timestamp: 3000,
    );

    test('returns null when comments list is null or empty', () {
      expect(
        findTopChapterReview(null, chapterId: 'ch1', chapterIndex: 0),
        isNull,
      );
      expect(
        findTopChapterReview([], chapterId: 'ch1', chapterIndex: 0),
        isNull,
      );
    });

    test('filters comments for specific chapter and prioritizes rated review', () {
      final top = findTopChapterReview(
        [comment1, comment2, comment3],
        chapterId: 'ch1',
        chapterIndex: 0,
      );
      expect(top, isNotNull);
      expect(top?.id, 'c2');
      expect(top?.displayName, 'Bob');
    });

    test('returns null when no comment exists for requested chapter', () {
      final top = findTopChapterReview(
        [comment1, comment2],
        chapterId: 'ch99',
        chapterIndex: 99,
      );
      expect(top, isNull);
    });
  });
}
