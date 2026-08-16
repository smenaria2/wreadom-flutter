import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/repositories/chapter_save_write_plan.dart';
import 'package:librebook_flutter/src/data/utils/firestore_utils.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';

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
}
