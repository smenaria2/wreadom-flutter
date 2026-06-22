import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../domain/repositories/writer_repository.dart';
import '../../utils/book_collaboration_utils.dart';
import '../../utils/map_utils.dart';
import '../utils/firestore_utils.dart';

class FirebaseWriterRepository implements WriterRepository {
  FirebaseWriterRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  static const int _batchChunkSize = 450;

  @override
  Future<String> createBook(Book book) async {
    final bookRef = _firestore.collection('books').doc();
    final data = _bookToFirestoreJson(book)..remove('id');
    final now = DateTime.now().millisecondsSinceEpoch;
    data['createdAt'] ??= now;
    data['updatedAt'] = now;
    data['isOriginal'] = true;
    data['source'] = 'firestore';
    await _writeBookAndAuthorChapters(
      bookRef: bookRef,
      data: data,
      chapters: book.chapters ?? const <Chapter>[],
      mergeBook: false,
      readExistingChapters: false,
    );
    return bookRef.id;
  }

  @override
  Future<List<Chapter>> getAuthoringChapters(String bookId) async {
    final snapshot = await _firestore
        .collection('books')
        .doc(bookId)
        .collection('authorChapters')
        .orderBy('index')
        .get();
    if (snapshot.docs.isEmpty) {
      final book = await _firestore.collection('books').doc(bookId).get();
      if (!book.exists) return const <Chapter>[];
      final parsed = Book.fromJson(
        normalizeBookMapForModel(book.data(), book.id),
      );
      return parsed.chapters ?? const <Chapter>[];
    }
    return snapshot.docs.map((doc) => _chapterFromFirestore(doc)).toList();
  }

  @override
  Future<List<Book>> getImportableSingleChapterDrafts(
    String userId, {
    String? excludeBookId,
  }) async {
    final books = await getUserBooks(userId, status: 'draft');
    return books.where((book) {
      if (book.id == excludeBookId) return false;
      if (book.status == 'deleted') return false;
      if (book.authorId?.trim() != userId) return false;
      if (isAcceptedCollaboration(book)) return false;
      return (book.chapters ?? const <Chapter>[]).length == 1;
    }).toList();
  }

  @override
  Future<void> deleteBook(String bookId) async {
    await _firestore.collection('books').doc(bookId).update({
      'status': 'deleted',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<String> moveChapterToStandaloneDraft({
    required Book sourceBook,
    required Chapter chapter,
    required List<Chapter> remainingChapters,
    required String ownerUserId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final sourceBookId = sourceBook.id.trim();
    final draftOwnerId = ownerUserId.trim();
    if (sourceBookId.isEmpty) {
      throw StateError('Source book must be saved before moving a chapter.');
    }
    if (draftOwnerId.isEmpty) {
      throw StateError('Draft owner is required.');
    }

    final movedTitle = chapter.title.trim().isEmpty
        ? sourceBook.title
        : chapter.title.trim();
    final standalone = sourceBook.copyWith(
      id: '',
      title: movedTitle,
      description: sourceBook.title.trim().isEmpty
          ? 'Draft exported from content'
          : 'Draft exported from ${sourceBook.title}',
      status: 'draft',
      source: 'firestore',
      isOriginal: true,
      createdAt: now,
      updatedAt: now,
      publishedAt: null,
      authorId: draftOwnerId,
      authorIds: [draftOwnerId],
      collaborationStatus: null,
      collaboratorId: null,
      collaboratorName: null,
      collaboratorPhotoURL: null,
      collaborationRequestedBy: null,
      collaborationRequestedAt: null,
      collaborationRespondedAt: null,
      recommendationCount: null,
      weightedScore: null,
      averageRating: null,
      viewCount: null,
      ratingsCount: null,
      chapterCount: 1,
      chapters: [chapter.copyWith(index: 0, status: 'draft', lastSavedAt: now)],
    );

    final newBookId = await createBook(standalone);
    await _restoreEngagementDataToStandalone(
      sourceBookId: sourceBookId,
      newBookId: newBookId,
      newBookTitle: movedTitle,
      chapterId: chapter.id,
    );
    await updateBook(
      sourceBookId,
      sourceBook.copyWith(
        chapters: remainingChapters,
        chapterCount: remainingChapters.where((item) => !item.isHidden).length,
        updatedAt: now,
      ),
    );
    return newBookId;
  }

  @override
  Future<List<Chapter>> importSingleDraftsToBook({
    required Book targetBook,
    required List<Book> sourceDrafts,
  }) async {
    final targetBookId = targetBook.id.trim();
    if (targetBookId.isEmpty) {
      throw StateError('Target book must be saved before importing drafts.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final currentChapters = List<Chapter>.from(
      targetBook.chapters ?? const <Chapter>[],
    );
    final imported = <Chapter>[];
    var nextIndex = currentChapters.length;

    for (final sourceDraft in sourceDrafts) {
      final sourceBookId = sourceDraft.id.trim();
      final sourceChapter = sourceDraft.chapters?.firstOrNull;
      if (sourceBookId.isEmpty || sourceChapter == null) continue;

      final importedChapter = sourceChapter.copyWith(
        id: sourceBookId,
        title: sourceDraft.title.trim().isEmpty
            ? sourceChapter.title
            : sourceDraft.title.trim(),
        index: nextIndex++,
        status: 'draft',
        lastSavedAt: now,
        originalBookId: sourceBookId,
      );
      currentChapters.add(importedChapter);
      imported.add(importedChapter);

      await _migrateEngagementDataToChapter(
        sourceBookId: sourceBookId,
        targetBookId: targetBookId,
        targetBookTitle: targetBook.title,
        newChapterId: importedChapter.id,
        newChapterTitle: importedChapter.title,
        newChapterIndex: importedChapter.index,
      );
      await deleteBook(sourceBookId);
    }

    if (imported.isNotEmpty) {
      await updateBook(
        targetBookId,
        targetBook.copyWith(
          chapters: currentChapters,
          chapterCount: currentChapters.where((item) => !item.isHidden).length,
          updatedAt: now,
        ),
      );
    }

    return imported;
  }

  @override
  Future<List<Book>> getUserBooks(
    String userId, {
    String status = 'all',
  }) async {
    final byId = <String, Book>{};

    Future<void> addBooksFrom(Query<Map<String, dynamic>> query) async {
      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        try {
          final data = normalizeBookMapForModel(doc.data(), doc.id);
          final book = Book.fromJson(data);
          if (book.status == 'deleted') continue;
          final isPrimary = book.authorId?.trim() == userId;
          if (!isPrimary && !isAcceptedCollaboration(book)) continue;
          byId[book.id] = book;
        } catch (e) {
          debugPrint(
            '[FirebaseWriterRepository] Error parsing book ${doc.id}: $e',
          );
        }
      }
    }

    await Future.wait([
      addBooksFrom(
        _firestore.collection('books').where('authorId', isEqualTo: userId),
      ),
      addBooksFrom(
        _firestore
            .collection('books')
            .where('authorIds', arrayContains: userId),
      ),
    ]);

    final items = byId.values.toList();

    items.sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
    return items;
  }

  @override
  Future<void> updateBook(String bookId, Book book) async {
    final data = _bookToFirestoreJson(book)..remove('id');
    data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    final bookRef = _firestore.collection('books').doc(bookId);
    final existing = await bookRef.get();
    if (existing.exists) {
      final existingBook = Book.fromJson(
        normalizeBookMapForModel(existing.data(), existing.id),
      );
      final removedCollaboratorId = existingBook.collaboratorId?.trim();
      final isCollabRemoval =
          existingBook.collaborationStatus == collaborationStatusAccepted &&
          removedCollaboratorId != null &&
          removedCollaboratorId.isNotEmpty &&
          book.collaborationStatus == null &&
          book.collaboratorId == null;
      if (isCollabRemoval) {
        data['collaborationRemovedBy'] = _auth.currentUser?.uid;
        data['collaborationRemovedAt'] = DateTime.now().millisecondsSinceEpoch;
        data['removedCollaboratorId'] = removedCollaboratorId;
      } else if (book.collaborationStatus == collaborationStatusPending) {
        data['collaborationRemovedBy'] = null;
        data['collaborationRemovedAt'] = null;
        data['removedCollaboratorId'] = null;
      }
    }
    await _writeBookAndAuthorChapters(
      bookRef: bookRef,
      data: data,
      chapters: book.chapters ?? const <Chapter>[],
      mergeBook: true,
      readExistingChapters: true,
    );
  }

  @override
  Future<void> respondToCollaborationRequest({
    required String bookId,
    required String userId,
    required bool accept,
  }) async {
    final bookRef = _firestore.collection('books').doc(bookId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(bookRef);
      if (!snapshot.exists) {
        throw StateError('Book not found.');
      }
      final book = Book.fromJson(
        normalizeBookMapForModel(snapshot.data(), snapshot.id),
      );
      if (book.collaboratorId?.trim() != userId ||
          book.collaborationStatus != collaborationStatusPending) {
        throw StateError('This collaboration request is no longer available.');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final primaryId = book.authorId?.trim();
      final collaboratorId = book.collaboratorId?.trim();
      final update = <String, dynamic>{
        'collaborationStatus': accept
            ? collaborationStatusAccepted
            : collaborationStatusDeclined,
        'collaborationRespondedAt': now,
        'updatedAt': now,
      };
      if (accept && primaryId != null && collaboratorId != null) {
        update['authorIds'] = <String>[primaryId, collaboratorId];
      }
      transaction.set(bookRef, update, SetOptions(merge: true));
    });
  }

  Future<void> _writeBookAndAuthorChapters({
    required DocumentReference<Map<String, dynamic>> bookRef,
    required Map<String, dynamic> data,
    required List<Chapter> chapters,
    required bool mergeBook,
    required bool readExistingChapters,
  }) async {
    if (chapters.length > _batchChunkSize) {
      throw StateError(
        'A book cannot contain more than $_batchChunkSize chapters.',
      );
    }

    final canonical = <Chapter>[
      for (var i = 0; i < chapters.length; i++) chapters[i].copyWith(index: i),
    ];
    final visible = <Chapter>[
      for (final chapter in canonical)
        if (!chapter.isHidden) chapter,
    ];
    data['chapters'] = <Map<String, dynamic>>[
      for (var i = 0; i < visible.length; i++)
        _chapterToFirestore(visible[i].copyWith(index: i, isHidden: false)),
    ];
    data['chapterCount'] = visible.length;

    final existing = readExistingChapters
        ? await bookRef.collection('authorChapters').get()
        : null;
    final incomingIds = canonical.map((chapter) => chapter.id).toSet();
    final writeCount = canonical.length + (existing?.docs.length ?? 0) + 1;
    if (writeCount > 500) {
      throw StateError(
        'This book has too many chapter changes for one atomic save.',
      );
    }
    final batch = _firestore.batch();
    batch.set(bookRef, data, SetOptions(merge: mergeBook));
    for (final chapter in canonical) {
      batch.set(
        bookRef.collection('authorChapters').doc(chapter.id),
        _chapterToFirestore(chapter),
      );
    }
    for (final stale in existing?.docs ?? const []) {
      if (!incomingIds.contains(stale.id)) batch.delete(stale.reference);
    }
    await batch.commit();
  }

  Map<String, dynamic> _chapterToFirestore(Chapter chapter) {
    final data = chapter.toJson();
    data['versions'] = chapter.versions
        ?.map((version) => version.toJson())
        .toList();
    data['order'] = chapter.index;
    return data;
  }

  Chapter _chapterFromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = asStringMap(doc.data());
    data['id'] = doc.id;
    data['title'] = data['title']?.toString() ?? 'Chapter';
    data['content'] = data['content']?.toString() ?? '';
    data['index'] = data['index'] is num
        ? (data['index'] as num).toInt()
        : data['order'] is num
        ? (data['order'] as num).toInt()
        : 0;
    if (data['lastSavedAt'] is Timestamp) {
      data['lastSavedAt'] =
          (data['lastSavedAt'] as Timestamp).millisecondsSinceEpoch;
    }
    return Chapter.fromJson(data);
  }

  Map<String, dynamic> _bookToFirestoreJson(Book book) {
    final data = book.toJson();
    data['authors'] = book.authors.map((author) => author.toJson()).toList();
    data['chapters'] = book.chapters?.map((chapter) {
      final chapterData = chapter.toJson();
      chapterData['versions'] = chapter.versions
          ?.map((version) => version.toJson())
          .toList();
      return chapterData;
    }).toList();
    data['leaves'] = book.leaves?.map((leaf) => leaf.toJson()).toList();
    return data;
  }

  Future<void> _migrateEngagementDataToChapter({
    required String sourceBookId,
    required String targetBookId,
    required String targetBookTitle,
    required String newChapterId,
    required String newChapterTitle,
    required int newChapterIndex,
  }) async {
    final comments = await _firestore
        .collection('comments')
        .where('bookId', isEqualTo: sourceBookId)
        .get();
    final feedPosts = await _firestore
        .collection('feed')
        .where('bookId', isEqualTo: sourceBookId)
        .get();

    await _commitQueryDocUpdates(
      docs: comments.docs,
      dataFor: (_) => {
        'bookId': targetBookId,
        'bookTitle': targetBookTitle,
        'chapterId': newChapterId,
        'chapterTitle': newChapterTitle,
        'chapterIndex': newChapterIndex,
      },
    );
    await _commitQueryDocUpdates(
      docs: feedPosts.docs,
      dataFor: (_) => {
        'bookId': targetBookId,
        'bookTitle': targetBookTitle,
        'chapterId': newChapterId,
        'chapterTitle': newChapterTitle,
      },
    );
  }

  Future<void> _restoreEngagementDataToStandalone({
    required String sourceBookId,
    required String newBookId,
    required String newBookTitle,
    required String chapterId,
  }) async {
    final comments = await _firestore
        .collection('comments')
        .where('bookId', isEqualTo: sourceBookId)
        .where('chapterId', isEqualTo: chapterId)
        .get();
    final feedPosts = await _firestore
        .collection('feed')
        .where('bookId', isEqualTo: sourceBookId)
        .where('chapterId', isEqualTo: chapterId)
        .get();

    await _commitQueryDocUpdates(
      docs: comments.docs,
      dataFor: (_) => {
        'bookId': newBookId,
        'bookTitle': newBookTitle,
        'chapterId': null,
        'chapterTitle': null,
        'chapterIndex': 0,
      },
    );
    await _commitQueryDocUpdates(
      docs: feedPosts.docs,
      dataFor: (_) => {
        'bookId': newBookId,
        'bookTitle': newBookTitle,
        'chapterId': null,
        'chapterTitle': null,
      },
    );
  }

  Future<void> _commitQueryDocUpdates({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required Map<String, dynamic> Function(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
    )
    dataFor,
  }) async {
    for (var i = 0; i < docs.length; i += _batchChunkSize) {
      final batch = _firestore.batch();
      final chunk = docs.skip(i).take(_batchChunkSize);
      for (final doc in chunk) {
        batch.update(doc.reference, dataFor(doc));
      }
      await batch.commit();
    }
  }
}
