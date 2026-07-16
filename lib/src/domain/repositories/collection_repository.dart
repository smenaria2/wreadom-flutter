import '../models/book_collection.dart';
import '../models/collection_book.dart';

abstract interface class CollectionRepository {
  Future<List<BookCollection>> getUserCollections(String userId);
  Stream<List<BookCollection>> watchUserCollections(String userId);
  Stream<BookCollection?> watchCollection(String collectionId);
  Stream<List<CollectionBook>> watchCollectionEntries(String collectionId);
  Future<Set<String>> collectionIdsContainingBook(
    String ownerId,
    String bookId,
  );
  Future<String> createCollection({
    required String title,
    String description = '',
  });
  Future<void> updateCollection(
    String collectionId, {
    required String title,
    String description = '',
  });
  Future<void> deleteCollection(String collectionId);
  Future<void> addBooks(String collectionId, List<String> bookIds);
  Future<void> removeBook(String collectionId, String bookId);
  Future<void> reorderBooks(String collectionId, List<String> orderedBookIds);
}

enum CollectionFailureKind {
  unauthenticated,
  permissionDenied,
  validation,
  limit,
  conflict,
  unavailable,
  unknown,
}

class CollectionFailure implements Exception {
  const CollectionFailure(this.kind, this.message, [this.cause]);
  final CollectionFailureKind kind;
  final String message;
  final Object? cause;
  @override
  String toString() => message;
}
