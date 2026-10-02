import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/chapter_command_service.dart';
import '../../domain/models/chapter_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/chapter_edit_lock.dart';
import '../../domain/repositories/writer_repository.dart';
import '../../utils/book_collaboration_utils.dart';
import '../../utils/map_utils.dart';
import '../utils/firestore_utils.dart';
import 'chapter_save_merge.dart';

class FirebaseWriterRepository implements WriterRepository {
  FirebaseWriterRepository({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
    ChapterCommandService? commands,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth,
       _injectedCommands = commands;

  final FirebaseFirestore _firestore;
  final ChapterCommandService? _injectedCommands;
  final firebase_auth.FirebaseAuth? _auth;

  firebase_auth.FirebaseAuth? get _resolvedAuth {
    if (_auth != null) return _auth;
    try {
      return firebase_auth.FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  late final ChapterCommandService _commands =
      _injectedCommands ?? ChapterCommandService(auth: _resolvedAuth);
  final Map<String, List<Chapter>> _baselines = {};
  final Map<String, int> _structureRevisions = {};
  String get editorSessionId => _commands.editorSessionId;

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
      publication: book.status == 'published' ? 'published' : null,
    );
    return bookRef.id;
  }

  @override
  Future<List<Chapter>> getAuthoringChapters(String bookId) async {
    final parent = _firestore.collection('books').doc(bookId);
    final book = await parent.get();
    requireChapterSchema(book.data()?['chapterStorageVersion']);
    final snapshot = await parent
        .collection('authorChapters')
        .orderBy('orderKey')
        .get();
    final chapters = snapshot.docs
        .where((doc) => doc.data()['deletedAt'] == null)
        .map(_chapterFromFirestore)
        .toList();
    final ordered = [
      for (var i = 0; i < chapters.length; i++) chapters[i].copyWith(index: i),
    ];
    _baselines[bookId] = ordered;
    // Saves are checked against the book root's live structure revision.
    _structureRevisions[bookId] =
        (book.data()?['structureRevision'] as num?)?.toInt() ?? 0;
    return ordered;
  }

  Future<({List<ChapterVersion> versions, String? cursor})>
  getChapterHistoryPage(
    String bookId,
    String chapterId, {
    String? cursor,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('books')
        .doc(bookId)
        .collection('authorChapters')
        .doc(chapterId)
        .collection('revisions')
        .orderBy('timestamp', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(51);
    if (cursor != null) query = query.startAfter(jsonDecode(cursor) as List);
    final snapshot = await query.get();
    final documents = snapshot.docs.take(50).toList();
    final next = snapshot.docs.length > 50
        ? jsonEncode([documents.last.data()['timestamp'], documents.last.id])
        : null;
    return (
      versions: documents
          .map((doc) => ChapterVersion.fromJson(doc.data()))
          .toList()
          .reversed
          .toList(),
      cursor: next,
    );
  }

  @override
  Stream<List<ChapterEditLock>> watchChapterLocks(String bookId) {
    return _firestore
        .collection('books')
        .doc(bookId)
        .collection('chapterLocks')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _chapterLockFromFirestore(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  @override
  Future<bool> acquireChapterLock(
    String bookId,
    String chapterId,
    ChapterLockHolder holder,
  ) async {
    final result = await _commands.send({
      'operation': 'acquireLease',
      'bookId': bookId,
      'chapterId': chapterId,
      'holderName': holder.name,
    });
    if (result['acquired'] == true && result['leaseToken'] is String) {
      _commands.leaseTokens['$bookId/$chapterId'] =
          result['leaseToken'] as String;
    }
    return result['acquired'] == true;
  }

  @override
  Future<void> renewChapterLock(String bookId, String chapterId) async {
    final token = _commands.leaseTokens['$bookId/$chapterId'];
    if (token == null) {
      throw StateError(
        'Editing session expired. Your local draft is preserved.',
      );
    }
    await _commands.send({
      'operation': 'renewLease',
      'bookId': bookId,
      'chapterId': chapterId,
      'leaseToken': token,
    });
  }

  @override
  Future<void> releaseChapterLock(String bookId, String chapterId) async {
    final token = _commands.leaseTokens.remove('$bookId/$chapterId');
    if (token == null) return;
    await _commands.send({
      'operation': 'releaseLease',
      'bookId': bookId,
      'chapterId': chapterId,
      'leaseToken': token,
    });
  }

  ChapterEditLock _chapterLockFromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    final normalized = asStringMap(data);
    normalized['isCurrentSession'] =
        normalized['editorSessionId'] == editorSessionId;
    normalized['chapterId'] = normalized['chapterId']?.toString() ?? docId;
    return ChapterEditLock.fromJson(normalized);
  }

  @override
  Future<List<Book>> getImportableSingleChapterDrafts(
    String userId, {
    String? excludeBookId,
  }) async {
    final books = await getUserBooks(userId, status: 'draft');
    final result = <Book>[];
    for (final book in books) {
      if (book.id == excludeBookId ||
          book.status == 'deleted' ||
          book.authorId?.trim() != userId ||
          isAcceptedCollaboration(book)) {
        continue;
      }
      final chapters = await getAuthoringChapters(book.id);
      if (chapters.length == 1) result.add(book.copyWith(chapters: chapters));
    }
    return result;
  }

  @override
  Future<void> deleteBook(String bookId) async {
    await _commands.send({'operation': 'deleteBook', 'bookId': bookId});
  }

  @override
  Future<String> moveChapterToStandaloneDraft({
    required Book sourceBook,
    required Chapter chapter,
    required List<Chapter> remainingChapters,
    required String ownerUserId,
  }) async {
    if (sourceBook.id.trim().isEmpty || ownerUserId.trim().isEmpty) {
      throw StateError('Save this book before moving a chapter.');
    }
    final result = await _commands.send({
      'operation': 'exportChapter',
      'bookId': sourceBook.id,
      'chapterId': chapter.id,
      'baseChapterRevision': chapter.revision,
      'baseStructureRevision': _structureRevisions[sourceBook.id] ?? 0,
      'leaseToken': _commands.leaseTokens['${sourceBook.id}/${chapter.id}'],
    });
    final targetBookId = result['targetBookId'];
    if (targetBookId is! String || targetBookId.isEmpty) {
      throw StateError(
        'The move needs verification. Your local draft is preserved.',
      );
    }
    // The move changed the source book's structure; refresh the baseline so
    // the next save is not refused. The move itself already succeeded.
    try {
      await getAuthoringChapters(sourceBook.id);
    } catch (error) {
      debugPrint(
        '[FirebaseWriterRepository] refresh after move failed: $error',
      );
    }
    return targetBookId;
  }

  @override
  Future<List<Chapter>> importSingleDraftsToBook({
    required Book targetBook,
    required List<Book> sourceDrafts,
  }) async {
    if (targetBook.id.trim().isEmpty) {
      throw StateError('Save this book before importing drafts.');
    }
    if (sourceDrafts.isEmpty) return [];
    final existingIds = (targetBook.chapters ?? <Chapter>[])
        .map((chapter) => chapter.id)
        .toSet();
    await _commands.send({
      'operation': 'importSingles',
      'bookId': targetBook.id,
      'sourceBookIds': sourceDrafts.map((book) => book.id).toList(),
      'baseStructureRevision': _structureRevisions[targetBook.id] ?? 0,
    });
    final refreshed = await getAuthoringChapters(targetBook.id);
    return refreshed
        .where((chapter) => !existingIds.contains(chapter.id))
        .toList();
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
  Future<List<Chapter>> updateBook(
    String bookId,
    Book book, {
    Set<String> deletedChapterIds = const <String>{},
    Map<String, int> baseChapterRevisions = const <String, int>{},
    Set<String> changedChapterIds = const <String>{},
    bool changedChapterIdsAreAuthoritative = false,
    String? publication,
  }) async {
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
        data['collaborationRemovedBy'] = _resolvedAuth?.currentUser?.uid;
        data['collaborationRemovedAt'] = DateTime.now().millisecondsSinceEpoch;
        data['removedCollaboratorId'] = removedCollaboratorId;
      } else if (book.collaborationStatus == collaborationStatusPending) {
        data['collaborationRemovedBy'] = null;
        data['collaborationRemovedAt'] = null;
        data['removedCollaboratorId'] = null;
      }
    }
    return _writeBookAndAuthorChapters(
      bookRef: bookRef,
      data: data,
      chapters: book.chapters ?? const <Chapter>[],
      mergeBook: true,
      readExistingChapters: true,
      deletedChapterIds: deletedChapterIds,
      baseChapterRevisions: baseChapterRevisions,
      changedChapterIds: changedChapterIds,
      changedChapterIdsAreAuthoritative: changedChapterIdsAreAuthoritative,
      publication: publication,
    );
  }

  @override
  Future<void> respondToCollaborationRequest({
    required String bookId,
    required String userId,
    required bool accept,
  }) async {
    await _commands.send({
      'operation': 'respondToCollaboration',
      'bookId': bookId,
      'accept': accept,
    });
  }

  Map<String, dynamic> _draftPayload(Chapter chapter) {
    final data = <String, dynamic>{
      'id': chapter.id,
      'title': chapter.title,
      'content': chapter.content,
      'orderKey': chapterOrderKey(chapter.index),
      'isHidden': chapter.isHidden,
      'isTitleLocked': chapter.isTitleLocked == true,
      'originalBookId': chapter.originalBookId,
      'status': chapter.status == 'published' ? 'published' : 'draft',
    };
    assertChapterBudget(data);
    return data;
  }

  Future<List<Chapter>> _writeBookAndAuthorChapters({
    required DocumentReference<Map<String, dynamic>> bookRef,
    required Map<String, dynamic> data,
    required List<Chapter> chapters,
    required bool mergeBook,
    required bool readExistingChapters,
    Set<String> deletedChapterIds = const {},
    Map<String, int> baseChapterRevisions = const {},
    Set<String> changedChapterIds = const {},
    bool changedChapterIdsAreAuthoritative = false,
    String? publication,
  }) async {
    final previous = {
      for (final ch in _baselines[bookRef.id] ?? <Chapter>[]) ch.id: ch,
    };
    final changed = chapters
        .where(
          (ch) =>
              previous[ch.id] == null ||
              jsonEncode(_draftPayload(ch)) !=
                  jsonEncode(_draftPayload(previous[ch.id]!)),
        )
        .toList();
    final metadata = Map<String, dynamic>.from(data)
      ..remove('chapters')
      ..remove('chapterCount')
      ..remove('wordCount')
      ..remove('readingTimeMinutes')
      ..remove('id');
    if (readExistingChapters && publication == null) metadata.remove('status');
    try {
      final result = await _commands.send({
        'operation': 'saveBook',
        'bookId': bookRef.id,
        'isNew': !readExistingChapters,
        'metadata': metadata,
        'chapters': changed.map(_draftPayload).toList(),
        'baseChapterRevisions': baseChapterRevisions.isNotEmpty
            ? baseChapterRevisions
            : {for (final ch in previous.values) ch.id: ch.revision},
        'baseStructureRevision': _structureRevisions[bookRef.id] ?? 0,
        'deletedChapterIds': deletedChapterIds.toList(),
        'leaseTokens': {
          for (final ch in changed)
            ch.id: _commands.leaseTokens['${bookRef.id}/${ch.id}'],
        },
        'publication': publication == null
            ? null
            : {
                'status': publication,
                'chapterIds': chapters
                    .where((ch) => !ch.isHidden && ch.status == 'published')
                    .map((ch) => ch.id)
                    .toList(),
              },
      });
      final revisions = Map<String, dynamic>.from(
        result['revisions'] as Map? ?? {},
      );
      final saved = chapters
          .map(
            (ch) => ch.copyWith(
              revision: (revisions[ch.id] as num?)?.toInt() ?? ch.revision,
            ),
          )
          .toList();
      _baselines[bookRef.id] = saved;
      _structureRevisions[bookRef.id] =
          (result['structureRevision'] as num?)?.toInt() ??
          _structureRevisions[bookRef.id] ??
          0;
      return saved;
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'aborted') {
        throw ChapterSaveConflictException(changed.map((ch) => ch.id).toList());
      }
      rethrow;
    }
  }

  Chapter _chapterFromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return _chapterFromSnapshot(doc);
  }

  Chapter _chapterFromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = asStringMap(doc.data() ?? const <String, dynamic>{});
    data['id'] = doc.id;
    data['title'] = data['title']?.toString() ?? 'Chapter';
    data['content'] = data['content']?.toString() ?? '';
    data['index'] = data['index'] is num
        ? (data['index'] as num).toInt()
        : data['order'] is num
        ? (data['order'] as num).toInt()
        : 0;
    data['revision'] = data['revision'] is num
        ? (data['revision'] as num).toInt()
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
    data.remove('chapters');
    data['leaves'] = book.leaves?.map((leaf) => leaf.toJson()).toList();
    return data;
  }
}
