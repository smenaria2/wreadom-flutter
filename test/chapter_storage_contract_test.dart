import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/chapter_storage.dart';

void main() {
  test('final schema is required', () {
    requireChapterSchema(2);
    for (final value in [null, 1, 3, '2']) {
      expect(
        () => requireChapterSchema(value),
        throwsA(isA<ChapterStorageException>()),
      );
    }
  });
  test('ordering matches web fixtures', () {
    expect(chapterOrderKey(12), '000000000012');
    expect(
      ([1000, 1, 99, 0, 10].map(chapterOrderKey).toList()..sort()),
      [0, 1, 10, 99, 1000].map(chapterOrderKey).toList(),
    );
  });
  test('empty bodies are valid but missing and stale bodies are not', () {
    const entry = ChapterDirectoryEntry(
      id: 'a',
      title: 'अध्याय',
      orderKey: '000000000000',
      publishedRevision: 2,
    );
    expect(entry.readBody({'content': '', 'publishedRevision': 2}), '');
    expect(() => entry.readBody(null), throwsA(isA<ChapterStorageException>()));
    expect(
      () => entry.readBody({'content': 'stale', 'publishedRevision': 1}),
      throwsA(isA<ChapterStorageException>()),
    );
  });
  test('byte limits account for Unicode', () {
    assertChapterBudget({'content': 'a' * 240000});
    expect(
      () => assertChapterBudget({'content': 'अ' * 240000}),
      throwsA(isA<ChapterStorageException>()),
    );
  });
  test('directory entries carry the stored word count', () {
    final entry = ChapterDirectoryEntry.fromMap('a', {
      'title': 'One',
      'orderKey': '000000000000',
      'publishedRevision': 1,
      'wordCount': 42,
    });
    expect(entry.wordCount, 42);
  });
}
