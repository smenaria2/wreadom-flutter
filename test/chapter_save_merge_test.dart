import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/repositories/chapter_save_merge.dart';
import 'package:librebook_flutter/src/domain/models/chapter.dart';

void main() {
  Chapter chapter(
    String id, {
    int index = 0,
    String title = 'Chapter',
    String content = '<p>Text</p>',
    bool isHidden = false,
    int revision = 0,
  }) {
    return Chapter(
      id: id,
      title: title,
      content: content,
      index: index,
      isHidden: isHidden,
      revision: revision,
    );
  }

  test('stale save preserves remote-only chapters', () {
    final result = mergeAuthoringChaptersForSave(
      incomingChapters: [
        chapter('chapter-1', index: 0, revision: 2),
        chapter('chapter-3', index: 1, title: 'Local new'),
      ],
      existingChapters: [
        chapter('chapter-1', index: 0, revision: 2),
        chapter('chapter-2', index: 1, title: 'Remote new', revision: 1),
      ],
    );

    expect(result.chapters.map((item) => item.id), [
      'chapter-1',
      'chapter-2',
      'chapter-3',
    ]);
  });

  test('local matching chapter wins when base revision matches', () {
    final result = mergeAuthoringChaptersForSave(
      incomingChapters: [
        chapter('chapter-1', content: '<p>Local edit</p>', revision: 4),
      ],
      existingChapters: [
        chapter('chapter-1', content: '<p>Old</p>', revision: 4),
      ],
      baseChapterRevisions: const {'chapter-1': 4},
    );

    expect(result.chapters.single.content, '<p>Local edit</p>');
    expect(result.chapters.single.revision, 5);
  });

  test('explicit deleted chapter ids remove only selected chapters', () {
    final result = mergeAuthoringChaptersForSave(
      incomingChapters: [chapter('chapter-1')],
      existingChapters: [chapter('chapter-1'), chapter('chapter-2')],
      deletedChapterIds: const {'chapter-2'},
    );

    expect(result.chapters.map((item) => item.id), ['chapter-1']);
  });

  test('hidden remote-only chapters stay out of public projection', () {
    final result = mergeAuthoringChaptersForSave(
      incomingChapters: [chapter('chapter-1')],
      existingChapters: [
        chapter('chapter-1'),
        chapter('chapter-2', index: 1, isHidden: true),
      ],
    );

    final visible = visibleChaptersForBookProjection(result.chapters);
    expect(
      result.chapters.singleWhere((item) => item.id == 'chapter-2').isHidden,
      isTrue,
    );
    expect(visible.map((item) => item.id), ['chapter-1']);
  });

  test('same-chapter save with newer remote revision conflicts', () {
    expect(
      () => mergeAuthoringChaptersForSave(
        incomingChapters: [chapter('chapter-1', content: '<p>Local</p>')],
        existingChapters: [
          chapter('chapter-1', content: '<p>Remote</p>', revision: 2),
        ],
        baseChapterRevisions: const {'chapter-1': 1},
      ),
      throwsA(isA<ChapterSaveConflictException>()),
    );
  });

  test('legacy chapters without revision are treated as revision zero', () {
    final result = mergeAuthoringChaptersForSave(
      incomingChapters: [chapter('chapter-1', content: '<p>Local</p>')],
      existingChapters: [chapter('chapter-1', content: '<p>Remote</p>')],
      baseChapterRevisions: const {'chapter-1': 0},
    );

    expect(result.chapters.single.revision, 1);
  });
}
