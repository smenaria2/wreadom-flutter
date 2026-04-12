import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../utils/firestore_utils.dart';

class FirebaseBookRepository implements BookRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'books';

  @override
  Future<List<Book>> getBooks({int limit = 10, dynamic lastDoc}) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'published')
          .limit(limit);

      if (lastDoc != null && lastDoc is DocumentSnapshot) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        try {
          final data = mapFirestoreData(doc.data() as Map<String, dynamic>, doc.id);
          return Book.fromJson(data);
        } catch (_) {
          return null;
        }
      }).whereType<Book>().toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Book>> getBooksByBookshelf(String bookshelf,
      {int limit = 10, dynamic lastDoc}) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('bookshelves', arrayContains: bookshelf)
          .where('status', isEqualTo: 'published')
          .limit(limit);

      if (lastDoc != null && lastDoc is DocumentSnapshot) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        try {
          final data = mapFirestoreData(doc.data() as Map<String, dynamic>, doc.id);
          return Book.fromJson(data);
        } catch (_) {
          return null;
        }
      }).whereType<Book>().toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Book>> getOriginalBooks({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isOriginal', isEqualTo: true)
          .where('status', isEqualTo: 'published')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        try {
          final data = mapFirestoreData(doc.data() as Map<String, dynamic>, doc.id);
          return Book.fromJson(data);
        } catch (_) {
          return null;
        }
      }).whereType<Book>().toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Book>> getUserBooks(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('authorId', isEqualTo: userId)
          .where('status', isEqualTo: 'published')
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        try {
          final data = mapFirestoreData(doc.data() as Map<String, dynamic>, doc.id);
          return Book.fromJson(data);
        } catch (_) {
          return null;
        }
      }).whereType<Book>().toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Book?> getBook(String bookId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(bookId).get();
      if (!doc.exists) return null;
      final data = mapFirestoreData(doc.data()!, doc.id);
      return Book.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Book>> getPopularBooks({int limit = 10}) async {
    try {
      // Try viewCount first
      try {
        final snapshot = await _firestore
            .collection(_collection)
            .where('status', isEqualTo: 'published')
            .orderBy('viewCount', descending: true)
            .limit(limit)
            .get();

        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) {
            try {
              final data = mapFirestoreData(doc.data() as Map<String, dynamic>, doc.id);
              return Book.fromJson(data);
            } catch (_) {
              return null;
            }
          }).whereType<Book>().toList();
        }
      } catch (_) {}

      // Fallback – download_count
      final fallback = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'published')
          .orderBy('download_count', descending: true)
          .limit(limit)
          .get();

      return fallback.docs.map((doc) {
        try {
          final data = mapFirestoreData(doc.data() as Map<String, dynamic>, doc.id);
          return Book.fromJson(data);
        } catch (_) {
          return null;
        }
      }).whereType<Book>().toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Book>> getRecentBooks({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'published')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        try {
          final data = mapFirestoreData(doc.data() as Map<String, dynamic>, doc.id);
          return Book.fromJson(data);
        } catch (_) {
          return null;
        }
      }).whereType<Book>().toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Book>> searchBooks(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    try {
      final term = query.trim();
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'published')
          .where('title', isGreaterThanOrEqualTo: term)
          .where('title', isLessThanOrEqualTo: '$term\uf8ff')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        try {
          final data = mapFirestoreData(doc.data() as Map<String, dynamic>, doc.id);
          return Book.fromJson(data);
        } catch (_) {
          return null;
        }
      }).whereType<Book>().toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> incrementViewCount(String bookId) async {
    await _firestore.collection(_collection).doc(bookId).set({
      'viewCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}
