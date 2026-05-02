import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import '../../domain/models/book.dart';
import '../../domain/repositories/writer_repository.dart';
import '../../utils/book_collaboration_utils.dart';
import '../utils/firestore_utils.dart';

class FirebaseWriterRepository implements WriterRepository {
  FirebaseWriterRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  @override
  Future<String> createBook(Book book) async {
    final data = _bookToFirestoreJson(book)..remove('id');
    final now = DateTime.now().millisecondsSinceEpoch;
    data['createdAt'] ??= now;
    data['updatedAt'] = now;
    data['isOriginal'] = true;
    data['source'] = 'firestore';
    final doc = await _firestore.collection('books').add(data);
    return doc.id;
  }

  @override
  Future<void> deleteBook(String bookId) async {
    await _firestore.collection('books').doc(bookId).update({
      'status': 'deleted',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
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
    await bookRef.set(data, SetOptions(merge: true));
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
    return data;
  }
}
