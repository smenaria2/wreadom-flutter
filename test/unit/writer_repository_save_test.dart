import 'package:librebook_flutter/src/data/services/chapter_command_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:librebook_flutter/src/data/repositories/chapter_save_merge.dart';
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
    'new client sends explicit commands and never writes canonical documents directly',
    () async {
      final firestore = FakeFirebaseFirestore();
      final commands = RecordingChapterCommands();
      final repository = FirebaseWriterRepository(
        firestore: firestore,
        commands: commands,
      );
      final book = chapterTestBook();
      final saved = await repository.updateBook(
        book.id,
        book,
        baseChapterRevisions: const {'c1': 3},
      );
      final request = commands.requests.single;
      expect(request['operation'], 'saveBook');
      expect((request['metadata'] as Map).containsKey('chapters'), false);
      expect((request['metadata'] as Map).containsKey('status'), false);
      expect(request['publication'], null);
      expect((request['chapters'] as List).single['versions'], null);
      expect(saved.single.revision, 4);
      expect(
        (await firestore.collection('books').doc(book.id).get()).exists,
        false,
      );
      expect(
        (await firestore
                .collection('books')
                .doc(book.id)
                .collection('authorChapters')
                .get())
            .docs,
        isEmpty,
      );
    },
  );

  test(
    'publication is explicit and acknowledgement skips unchanged bodies on next save',
    () async {
      final commands = RecordingChapterCommands();
      final repository = FirebaseWriterRepository(
        firestore: FakeFirebaseFirestore(),
        commands: commands,
      );
      final book = chapterTestBook();
      final saved = await repository.updateBook(
        book.id,
        book,
        publication: 'published',
      );
      expect((commands.requests.first['publication'] as Map)['chapterIds'], [
        'c1',
      ]);
      await repository.updateBook(book.id, book.copyWith(chapters: saved));
      expect(commands.requests.last['chapters'], isEmpty);
      expect(commands.requests.last['publication'], null);
    },
  );

  test(
    'conflict is reported without fetching a newer baseline and overwriting',
    () async {
      final commands = RecordingChapterCommands()..fail = true;
      final repository = FirebaseWriterRepository(
        firestore: FakeFirebaseFirestore(),
        commands: commands,
      );
      final book = chapterTestBook();
      await expectLater(
        repository.updateBook(
          book.id,
          book,
          baseChapterRevisions: const {'c1': 3},
        ),
        throwsA(isA<ChapterSaveConflictException>()),
      );
      expect(commands.requests, hasLength(1));
      expect(commands.requests.single['baseChapterRevisions'], {'c1': 3});
      expect(book.chapters!.single.content, '<p>Local candidate</p>');
    },
  );
  test(
    'chapter transfer sends one command and never deletes the source directly',
    () async {
      final firestore = FakeFirebaseFirestore();
      final commands = RecordingChapterCommands();
      final repository = FirebaseWriterRepository(
        firestore: firestore,
        commands: commands,
      );
      final book = chapterTestBook();
      await firestore.collection('books').doc(book.id).set({'title': 'Source'});
      final target = await repository.moveChapterToStandaloneDraft(
        sourceBook: book,
        chapter: book.chapters!.single,
        remainingChapters: [],
        ownerUserId: 'owner',
      );
      expect(target, 'standalone-draft');
      expect(commands.requests.single['operation'], 'exportChapter');
      expect(commands.requests.single['baseChapterRevision'], 3);
      expect((await firestore.collection('books').doc(book.id).get()).data(), {
        'title': 'Source',
      });
    },
  );

  test('saves are checked against the book root structure revision', () async {
    final firestore = FakeFirebaseFirestore();
    final commands = RecordingChapterCommands();
    final repository = FirebaseWriterRepository(
      firestore: firestore,
      commands: commands,
    );
    final book = chapterTestBook();
    final root = firestore.collection('books').doc(book.id);
    await root.set({'chapterStorageVersion': 2, 'structureRevision': 7});
    // Written once at export and never updated; must not be used.
    await root.collection('authorState').doc('current').set({
      'structureRevision': 1,
    });
    await root.collection('authorChapters').doc('c1').set({
      'title': 'One',
      'content': '<p>Saved</p>',
      'orderKey': '000000000000',
      'revision': 3,
    });
    await repository.getAuthoringChapters(book.id);
    await repository.updateBook(book.id, book);
    expect(commands.requests.single['baseStructureRevision'], 7);
  });

  test('failed import leaves source and destination untouched', () async {
    final firestore = FakeFirebaseFirestore();
    final commands = RecordingChapterCommands()..fail = true;
    final repository = FirebaseWriterRepository(
      firestore: firestore,
      commands: commands,
    );
    final book = chapterTestBook();
    await firestore.collection('books').doc('single').set({
      'title': 'Original',
    });
    await expectLater(
      repository.importSingleDraftsToBook(
        targetBook: book,
        sourceDrafts: [book.copyWith(id: 'single')],
      ),
      throwsA(isA<FirebaseFunctionsException>()),
    );
    expect(commands.requests.single['operation'], 'importSingles');
    expect((await firestore.collection('books').doc('single').get()).data(), {
      'title': 'Original',
    });
    expect(
      (await firestore.collection('books').doc(book.id).get()).exists,
      false,
    );
  });
}

Book chapterTestBook() => Book(
  id: 'book-command',
  title: 'Command book',
  authors: const [Author(name: 'Writer')],
  subjects: const [],
  languages: const ['en'],
  formats: const {},
  downloadCount: 0,
  mediaType: 'text',
  bookshelves: const [],
  status: 'published',
  chapters: const [
    Chapter(
      id: 'c1',
      title: 'One',
      content: '<p>Local candidate</p>',
      index: 0,
      revision: 3,
      status: 'published',
      versions: [
        ChapterVersion(content: 'private history', timestamp: 1, wordCount: 2),
      ],
    ),
  ],
);

class RecordingChapterCommands extends ChapterCommandService {
  final requests = <Map<String, dynamic>>[];
  bool fail = false;
  @override
  Future<Map<String, dynamic>> send(
    Map<String, dynamic> command, {
    String? mutationId,
  }) async {
    requests.add(command);
    if (fail) {
      throw FirebaseFunctionsException(
        code: 'aborted',
        message: 'Revision conflict',
      );
    }
    return {
      'revisions': {'c1': 4},
      'structureRevision': 1,
      'targetBookId': 'standalone-draft',
    };
  }
}
