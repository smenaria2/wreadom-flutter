import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/chapter.dart';
import 'package:librebook_flutter/src/presentation/utils/chapter_review_prompt_policy.dart';

void main() {
  const chapter = Chapter(
    id: 'chapter/one',
    title: 'One',
    content: 'Text',
    index: 0,
  );

  test('local day is stable and zero padded', () {
    expect(
      ChapterReviewPromptPolicy.localDay(DateTime(2026, 6, 9, 23, 30)),
      '2026-06-09',
    );
  });

  test('prompt keys are scoped to user, book, and chapter', () {
    final first = ChapterReviewPromptPolicy.promptedChapterKey(
      userId: 'reader@example.com',
      bookId: 'book/1',
      chapter: chapter,
      chapterIndex: 0,
    );
    final second = ChapterReviewPromptPolicy.promptedChapterKey(
      userId: 'reader@example.com',
      bookId: 'book/1',
      chapter: chapter.copyWith(id: 'chapter/two'),
      chapterIndex: 1,
    );

    expect(first, isNot(second));
    expect(first, contains(Uri.encodeComponent('reader@example.com')));
    expect(first, contains(Uri.encodeComponent('chapter/one')));
  });

  test('missing chapter id falls back to chapter index', () {
    final key = ChapterReviewPromptPolicy.promptedChapterKey(
      userId: 'reader',
      bookId: 'book',
      chapter: chapter.copyWith(id: ''),
      chapterIndex: 4,
    );

    expect(key, contains(Uri.encodeComponent('index:4')));
  });

  test('voice emphasis rotates onto every third prompt', () {
    expect(ChapterReviewPromptPolicy.emphasizeVoice(0), isFalse);
    expect(ChapterReviewPromptPolicy.emphasizeVoice(1), isFalse);
    expect(ChapterReviewPromptPolicy.emphasizeVoice(2), isTrue);
    expect(ChapterReviewPromptPolicy.emphasizeVoice(3), isFalse);
    expect(ChapterReviewPromptPolicy.emphasizeVoice(5), isTrue);
  });
}
