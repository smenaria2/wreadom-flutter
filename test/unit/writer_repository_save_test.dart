import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/repositories/chapter_save_write_plan.dart';
import 'package:librebook_flutter/src/data/repositories/firebase_writer_repository.dart';
import 'package:librebook_flutter/src/data/utils/firestore_utils.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/domain/models/chapter.dart';

void main() {
  group('Chapter save write plan', () {
    test(
      'status-only save updates metadata without reading chapter bodies',
      () {
        final plan = buildChapterSaveWritePlan(
          incomingChapterIds: List.generate(12, (index) => 'chapter-$index'),
          changedChapterIds: const <String>{},
          changedChapterIdsAreAuthoritative: true,
        );

        expect(plan.fullChapterIds, isEmpty);
        expect(plan.metadataOnlyChapterIds, hasLength(12));
        expect(plan.writeCount(deletedChapterCount: 0), 13);
      },
    );

    test('legacy empty changed set retains full chapter writes', () {
      final plan = buildChapterSaveWritePlan(
        incomingChapterIds: const ['chapter-1', 'chapter-2'],
        changedChapterIds: const <String>{},
      );

      expect(plan.fullChapterIds, {'chapter-1', 'chapter-2'});
      expect(plan.metadataOnlyChapterIds, isEmpty);
    });

    test('changed bodies are read while other statuses are metadata-only', () {
      final plan = buildChapterSaveWritePlan(
        incomingChapterIds: const ['chapter-1', 'chapter-2', 'chapter-3'],
        changedChapterIds: const {'chapter-2'},
        changedChapterIdsAreAuthoritative: true,
      );

      expect(plan.fullChapterIds, {'chapter-2'});
      expect(plan.metadataOnlyChapterIds, {'chapter-1', 'chapter-3'});
    });

    test(
      'newly added chapter in multi-chapter book is included in full writes',
      () {
        final plan = buildChapterSaveWritePlan(
          incomingChapterIds: const ['chapter-1', 'chapter-2', 'chapter-3-new'],
          changedChapterIds: const {'chapter-3-new'},
          changedChapterIdsAreAuthoritative: true,
        );

        expect(plan.fullChapterIds, {'chapter-3-new'});
        expect(plan.metadataOnlyChapterIds, {'chapter-1', 'chapter-2'});
        expect(plan.writeCount(deletedChapterCount: 0), 4);
      },
    );
  });

  group('WriterRepository Book Model & Normalization Tests', () {
    test(
      'Book.fromJson safely handles leaves containing strings instead of maps',
      () {
        final raw = <String, dynamic>{
          'title': 'Test Story',
          'leaves': ['leaf_id_1', 'leaf_id_2', 'leaf_id_3'],
          'leafCount': 3,
        };

        final normalized = normalizeBookMapForModel(raw, 'book-123');
        final book = Book.fromJson(normalized);
        expect(book.id, 'book-123');
        expect(book.title, 'Test Story');
        expect(book.leaves, isEmpty);
      },
    );

    test('Book.fromJson parses valid map leaves correctly', () {
      final raw = <String, dynamic>{
        'title': 'Story with Leaves',
        'leaves': [
          {
            'id': 'leaf-1',
            'type': 'text',
            'createdBy': 'user-1',
            'createdAt': 123456789,
            'textPlain': 'Leaf content note',
          },
        ],
        'leafCount': 1,
      };

      final normalized = normalizeBookMapForModel(raw, 'book-456');
      final book = Book.fromJson(normalized);
      expect(book.leaves?.length, 1);
      expect(book.leaves?.first.id, 'leaf-1');
      expect(book.leaves?.first.textPlain, 'Leaf content note');
    });

    test('Book.fromJson treats a non-list leaves value as empty', () {
      final normalized = normalizeBookMapForModel(<String, dynamic>{
        'title': 'Legacy Story',
      }, 'book-legacy-leaves');
      normalized['leaves'] = 'legacy_leaf_id';

      final book = Book.fromJson(normalized);

      expect(book.leaves, isEmpty);
    });

    test('Book.fromJson tolerates leaf maps with non-string keys', () {
      final normalized = normalizeBookMapForModel(<String, dynamic>{
        'title': 'Mixed Map Story',
      }, 'book-mixed-leaf-map');
      normalized['leaves'] = <dynamic>[
        <dynamic, dynamic>{
          'id': 'leaf-1',
          'type': 'text',
          'createdAt': 1,
          'createdBy': 'user-1',
          7: 'legacy-extra-value',
        },
      ];

      final book = Book.fromJson(normalized);

      expect(book.leaves?.single.id, 'leaf-1');
    });

    test('normalizeBookMapForModel normalizes multi-chapter book data', () {
      final raw = <String, dynamic>{
        'title': 'निसर्गपिशाचिनी',
        'status': 'published',
        'chapters': List.generate(
          12,
          (index) => {
            'id': 'chap-$index',
            'title': 'Chapter ${index + 1}',
            'content': 'Content of chapter $index',
            'index': index,
            'wordCount': 500,
          },
        ),
        'leaves': ['legacy_leaf_str'],
      };

      final normalized = normalizeBookMapForModel(raw, 'book-multi-chap');
      final book = Book.fromJson(normalized);

      expect(book.id, 'book-multi-chap');
      expect(book.title, 'निसर्गपिशाचिनी');
      expect(book.chapters?.length, 12);
      expect(book.leaves, isEmpty);
    });
  });

  test(
    'repository transaction preserves unchanged bodies and writes new chapters',
    () async {
      final firestore = FakeFirebaseFirestore();
      final bookRef = firestore.collection('books').doc('book-transaction');
      await bookRef.set({
        'title': 'Transaction Book',
        'authors': [const Author(name: 'Writer').toJson()],
        'subjects': <String>[],
        'languages': ['en'],
        'formats': <String, String>{},
        'downloadCount': 0,
        'mediaType': 'text',
        'bookshelves': <String>[],
        'source': 'firestore',
        'isOriginal': true,
        'contentType': 'story',
        'authorId': 'user-1',
        'chapters': <Map<String, dynamic>>[],
        'status': 'draft',
        'createdAt': 1,
        'updatedAt': 1,
      });
      await bookRef.collection('authorChapters').doc('chapter-1').set({
        'title': 'One',
        'content': '<p>Remote one</p>',
        'index': 0,
        'order': 0,
        'status': 'draft',
        'revision': 4,
      });
      await bookRef.collection('authorChapters').doc('chapter-2').set({
        'title': 'Two',
        'content': '<p>Remote two</p>',
        'index': 1,
        'order': 1,
        'status': 'draft',
        'revision': 2,
      });

      final chapters = <Chapter>[
        const Chapter(
          id: 'chapter-2',
          title: 'Two',
          content: '<p>Updated two</p>',
          index: 0,
          status: 'published',
          revision: 2,
        ),
        const Chapter(
          id: 'chapter-1',
          title: 'One',
          content: '<p>Stale local one</p>',
          index: 1,
          status: 'published',
          revision: 4,
        ),
        const Chapter(
          id: 'chapter-3-new',
          title: 'Three',
          content: '<p>New three</p>',
          index: 2,
          status: 'published',
        ),
      ];
      final book = Book(
        id: 'book-transaction',
        title: 'Transaction Book',
        authors: const [Author(name: 'Writer')],
        subjects: const [],
        languages: const ['en'],
        formats: const {},
        downloadCount: 0,
        mediaType: 'text',
        bookshelves: const [],
        source: 'firestore',
        isOriginal: true,
        contentType: 'story',
        authorId: 'user-1',
        chapters: chapters,
        status: 'published',
        createdAt: 1,
        updatedAt: 2,
        chapterCount: 3,
      );

      final saved = await FirebaseWriterRepository(firestore: firestore)
          .updateBook(
            book.id,
            book,
            baseChapterRevisions: const {'chapter-2': 2},
            changedChapterIds: const {'chapter-2', 'chapter-3-new'},
            changedChapterIdsAreAuthoritative: true,
          );

      expect(saved.map((chapter) => chapter.id), [
        'chapter-2',
        'chapter-1',
        'chapter-3-new',
      ]);
      final chapterOne = await bookRef
          .collection('authorChapters')
          .doc('chapter-1')
          .get();
      final chapterTwo = await bookRef
          .collection('authorChapters')
          .doc('chapter-2')
          .get();
      final chapterThree = await bookRef
          .collection('authorChapters')
          .doc('chapter-3-new')
          .get();

      expect(chapterOne.data()?['content'], '<p>Remote one</p>');
      expect(chapterOne.data()?['revision'], 4);
      expect(chapterOne.data()?['index'], 1);
      expect(chapterOne.data()?['order'], 1);
      expect(chapterOne.data()?['status'], 'published');
      expect(chapterTwo.data()?['content'], '<p>Updated two</p>');
      expect(chapterTwo.data()?['revision'], 3);
      expect(chapterThree.data()?['content'], '<p>New three</p>');
      expect(chapterThree.data()?['revision'], 1);

      final updatedBookDoc = await bookRef.get();
      expect(updatedBookDoc.data()?['wordCount'], greaterThan(0));
      expect(updatedBookDoc.data()?['readingTimeMinutes'], greaterThan(0));
    },
  );

  test('updateBook projects exact word count and reading time on book doc', () async {
    final firestore = FakeFirebaseFirestore();
    final bookRef = firestore.collection('books').doc('book-reading-test');
    final chapters = [
      Chapter(
        id: 'c1',
        title: 'Ch 1',
        content: List.generate(400, (i) => 'word$i').join(' '),
        index: 0,
        status: 'published',
      ),
      Chapter(
        id: 'c2',
        title: 'Ch 2',
        content: List.generate(600, (i) => 'word$i').join(' '),
        index: 1,
        status: 'published',
      ),
    ];
    final book = Book(
      id: 'book-reading-test',
      title: 'Word Test Book',
      authors: const [Author(name: 'Author')],
      subjects: const [],
      languages: const ['en'],
      formats: const {},
      downloadCount: 0,
      mediaType: 'text',
      bookshelves: const [],
      chapters: chapters,
      status: 'published',
    );

    await FirebaseWriterRepository(firestore: firestore).updateBook(
      book.id,
      book,
      changedChapterIds: {'c1', 'c2'},
    );

    final savedDoc = await bookRef.get();
    // 400 + 600 = 1000 words -> 1000 / 200 = 5 mins
    expect(savedDoc.data()?['wordCount'], 1000);
    expect(savedDoc.data()?['readingTimeMinutes'], 5);
  });
}
