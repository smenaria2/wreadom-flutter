import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/book_collection.dart';
import '../../domain/models/collection_book.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/collection_repository.dart';
import '../utils/collection_firestore_utils.dart';

class FirebaseCollectionRepository implements CollectionRepository {
  FirebaseCollectionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required BookRepository bookRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _books = bookRepository;

  static const maxCollectionsPerUser = 50;
  static const maxBooksPerCollection = 200;
  static const maxTitleLength = 60;
  static const maxDescriptionLength = 300;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final BookRepository _books;

  CollectionReference<Map<String, dynamic>> get _collections =>
      _firestore.collection('collections');

  @override
  Stream<List<BookCollection>> watchUserCollections(String userId) =>
      _collections
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => normalizeCollection(doc.data(), doc.id))
                .toList(),
          );

  @override
  Stream<BookCollection?> watchCollection(String collectionId) => _collections
      .doc(collectionId)
      .snapshots()
      .map(
        (doc) => doc.exists && doc.data() != null
            ? normalizeCollection(doc.data(), doc.id)
            : null,
      );

  @override
  Stream<List<CollectionBook>> watchCollectionEntries(String collectionId) =>
      _collections
          .doc(collectionId)
          .collection('books')
          .orderBy('position')
          .snapshots()
          .map((snapshot) {
            final entries = snapshot.docs
                .map((doc) => normalizeCollectionBook(doc.data(), doc.id))
                .toList();
            entries.sort(
              (a, b) => a.position != b.position
                  ? a.position.compareTo(b.position)
                  : a.bookId.compareTo(b.bookId),
            );
            return entries;
          });

  @override
  Future<Set<String>> collectionIdsContainingBook(
    String ownerId,
    String bookId,
  ) async {
    final collections = await _collections
        .where('ownerId', isEqualTo: ownerId)
        .limit(maxCollectionsPerUser)
        .get();
    final checks = await Future.wait(
      collections.docs.map(
        (collection) =>
            collection.reference.collection('books').doc(bookId).get(),
      ),
    );
    return {
      for (var i = 0; i < checks.length; i++)
        if (checks[i].exists) collections.docs[i].id,
    };
  }

  @override
  Future<String> createCollection({
    required String title,
    String description = '',
  }) async {
    final user = _requireUser();
    final values = _validate(title, description);
    try {
      final existing = await _collections
          .where('ownerId', isEqualTo: user.uid)
          .limit(maxCollectionsPerUser)
          .get();
      if (existing.size >= maxCollectionsPerUser) {
        throw const CollectionFailure(
          CollectionFailureKind.limit,
          'You can create up to 50 collections.',
        );
      }
      final document = await _collections.add({
        'ownerId': user.uid,
        'title': values.$1,
        'description': values.$2,
        'bookCount': 0,
        'coverBookIds': <String>[],
        'coverBooks': <Map<String, String>>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return document.id;
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> updateCollection(
    String collectionId, {
    required String title,
    String description = '',
  }) async {
    final values = _validate(title, description);
    await _requireOwner(collectionId);
    try {
      await _collections.doc(collectionId).update({
        'title': values.$1,
        'description': values.$2,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    await _requireOwner(collectionId);
    try {
      final entries = await _collections
          .doc(collectionId)
          .collection('books')
          .limit(maxBooksPerCollection + 1)
          .get();
      if (entries.size > maxBooksPerCollection) {
        throw const CollectionFailure(
          CollectionFailureKind.limit,
          'This collection is larger than the supported deletion limit.',
        );
      }
      final batch = _firestore.batch();
      for (final entry in entries.docs) {
        batch.delete(entry.reference);
      }
      batch.delete(_collections.doc(collectionId));
      await batch.commit();
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> addBooks(String collectionId, List<String> bookIds) async {
    await _requireOwner(collectionId);
    final uniqueIds = bookIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (uniqueIds.isEmpty) return;
    try {
      final booksRef = _collections.doc(collectionId).collection('books');
      final existing = await booksRef.get();
      final existingIds = existing.docs.map((doc) => doc.id).toSet();
      final additions = uniqueIds
          .where((id) => !existingIds.contains(id))
          .toList();
      if (existing.size + additions.length > maxBooksPerCollection) {
        throw const CollectionFailure(
          CollectionFailureKind.limit,
          'A collection can contain up to 200 books.',
        );
      }
      if (additions.isEmpty) return;
      var maxPosition = -1;
      for (final doc in existing.docs) {
        final position = (doc.data()['position'] as num?)?.toInt() ?? 0;
        if (position > maxPosition) maxPosition = position;
      }
      final batch = _firestore.batch();
      for (var i = 0; i < additions.length; i++) {
        batch.set(booksRef.doc(additions[i]), {
          'bookId': additions[i],
          'position': maxPosition + i + 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      await _refreshMetadata(collectionId);
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> removeBook(String collectionId, String bookId) async {
    await _requireOwner(collectionId);
    try {
      await _collections
          .doc(collectionId)
          .collection('books')
          .doc(bookId)
          .delete();
      await _refreshMetadata(collectionId);
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> reorderBooks(
    String collectionId,
    List<String> orderedBookIds,
  ) async {
    await _requireOwner(collectionId);
    if (orderedBookIds.length > maxBooksPerCollection ||
        orderedBookIds.toSet().length != orderedBookIds.length) {
      throw const CollectionFailure(
        CollectionFailureKind.validation,
        'The requested collection order is invalid.',
      );
    }
    try {
      final booksRef = _collections.doc(collectionId).collection('books');
      final existing = await booksRef.get();
      if (existing.docs
              .map((doc) => doc.id)
              .toSet()
              .difference(orderedBookIds.toSet())
              .isNotEmpty ||
          existing.size != orderedBookIds.length) {
        throw const CollectionFailure(
          CollectionFailureKind.conflict,
          'The collection changed. Refresh it and try again.',
        );
      }
      final batch = _firestore.batch();
      for (var i = 0; i < orderedBookIds.length; i++) {
        batch.update(booksRef.doc(orderedBookIds[i]), {'position': i});
      }
      await batch.commit();
      await _refreshMetadata(collectionId);
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  Future<void> _refreshMetadata(String collectionId) async {
    final booksRef = _collections.doc(collectionId).collection('books');
    final snapshot = await booksRef.orderBy('position').get();
    final ids = snapshot.docs.map((doc) => doc.id).toList();
    final coverIds = ids.take(4).toList();
    final resolved = await _books.getBooksByIds(coverIds);
    final byId = {for (final book in resolved) book.id: book};
    final covers = <Map<String, String>>[];
    for (final id in coverIds) {
      final coverUrl = byId[id]?.coverUrl?.trim();
      if (coverUrl != null && coverUrl.isNotEmpty) {
        covers.add({'bookId': id, 'coverUrl': coverUrl});
      }
    }
    await _collections.doc(collectionId).update({
      'bookCount': ids.length,
      'coverBookIds': coverIds,
      'coverBooks': covers,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const CollectionFailure(
        CollectionFailureKind.unauthenticated,
        'Sign in to manage collections.',
      );
    }
    return user;
  }

  Future<void> _requireOwner(String collectionId) async {
    final user = _requireUser();
    final snapshot = await _collections.doc(collectionId).get();
    if (!snapshot.exists || snapshot.data()?['ownerId'] != user.uid) {
      throw const CollectionFailure(
        CollectionFailureKind.permissionDenied,
        'Only the collection owner can make this change.',
      );
    }
  }

  (String, String) _validate(String title, String description) {
    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();
    if (normalizedTitle.isEmpty || normalizedTitle.length > maxTitleLength) {
      throw const CollectionFailure(
        CollectionFailureKind.validation,
        'Collection names must contain 1Ã¢â‚¬â€œ60 characters.',
      );
    }
    if (normalizedDescription.length > maxDescriptionLength) {
      throw const CollectionFailure(
        CollectionFailureKind.validation,
        'Collection descriptions can contain up to 300 characters.',
      );
    }
    return (normalizedTitle, normalizedDescription);
  }

  CollectionFailure _mapFailure(Object error) {
    if (error is CollectionFailure) return error;
    if (error is FirebaseException) {
      final kind = switch (error.code) {
        'permission-denied' => CollectionFailureKind.permissionDenied,
        'unauthenticated' => CollectionFailureKind.unauthenticated,
        'aborted' || 'already-exists' => CollectionFailureKind.conflict,
        'unavailable' ||
        'deadline-exceeded' => CollectionFailureKind.unavailable,
        _ => CollectionFailureKind.unknown,
      };
      return CollectionFailure(
        kind,
        error.message ?? 'Collection operation failed.',
        error,
      );
    }
    return CollectionFailure(
      CollectionFailureKind.unknown,
      'Collection operation failed.',
      error,
    );
  }
}
