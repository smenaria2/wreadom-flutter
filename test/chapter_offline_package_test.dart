import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:librebook_flutter/src/data/services/offline_service.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/domain/models/chapter.dart';

void main() {
  late Directory temporary;
  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp(
      'librebook-chapter-package-',
    );
    Hive.init(temporary.path);
    await OfflineService().init();
  });
  tearDownAll(() async {
    await Hive.close();
    if (temporary.path.contains('librebook-chapter-package-')) {
      await temporary.delete(recursive: true);
    }
  });
  test(
    'offline package is complete in one record and excludes private history',
    () async {
      final book = Book(
        id: 'offline-a',
        title: 'Offline',
        authors: const [Author(name: 'Writer')],
        subjects: const [],
        languages: const [],
        formats: const {},
        downloadCount: 0,
        mediaType: 'text',
        bookshelves: const [],
        isOriginal: true,
      );
      const chapter = Chapter(
        id: 'c1',
        title: 'One',
        content: '<p>Published text</p>',
        index: 0,
        status: 'published',
        revision: 4,
        versions: [
          ChapterVersion(content: 'Private', timestamp: 1, wordCount: 1),
        ],
      );
      final service = OfflineService();
      await service.downloadBook(book, [chapter]);
      final record = Hive.box('offline_books').get(book.id) as Map;
      expect(record['complete'], true);
      expect(record['schemaVersion'], 2);
      expect((record['chapters'] as List).single['versions'], null);
      expect(Hive.box('offline_chapters').containsKey(book.id), false);
      expect(
        (await service.getDownloadedChapters(book.id)).single.content,
        chapter.content,
      );
      await expectLater(service.downloadBook(book, []), throwsStateError);
      expect(
        (await service.getDownloadedChapters(book.id)).single.content,
        chapter.content,
      );
      expect(await service.isBookDownloaded(book.id), true);
    },
  );

  test(
    'old packages keep their public chapters and drop hidden ones',
    () async {
      await Hive.box('offline_books').put('legacy-a', {
        'id': 'legacy-a',
        'title': 'Legacy',
        'isOriginal': true,
      });
      await Hive.box('offline_chapters').put('legacy-a', [
        {'id': 'c1', 'title': 'One', 'content': '<p>Public</p>', 'index': 0},
        {
          'id': 'c2',
          'title': 'Two',
          'content': '<p>Hidden</p>',
          'index': 1,
          'isHidden': true,
        },
      ]);
      await Hive.box(
        'offline_books',
      ).put('legacy-empty', {'id': 'legacy-empty'});
      await Hive.box('offline_chapters').put('legacy-empty', [
        {'id': 'd1', 'content': '<p>Draft</p>', 'status': 'draft'},
      ]);
      // Reopening the boxes runs the one-time conversion again.
      await Hive.box('offline_books').close();
      await Hive.box('offline_chapters').close();
      final service = OfflineService();
      await service.init();

      final chapters = await service.getDownloadedChapters('legacy-a');
      expect(chapters.map((chapter) => chapter.id), ['c1']);
      expect(await service.isBookDownloaded('legacy-empty'), false);
      expect(Hive.box('offline_books').containsKey('legacy-empty'), false);
    },
  );
}
