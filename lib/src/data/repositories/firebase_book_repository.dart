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
          final data = normalizeBookMapForModel(doc.data() as Map<String, dynamic>, doc.id);
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
          final data = normalizeBookMapForModel(doc.data() as Map<String, dynamic>, doc.id);
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
          final data = normalizeBookMapForModel(doc.data(), doc.id);
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
          final data = normalizeBookMapForModel(doc.data(), doc.id);
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
      final data = normalizeBookMapForModel(doc.data()!, doc.id);
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
              final data = normalizeBookMapForModel(doc.data(), doc.id);
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
          final data = normalizeBookMapForModel(doc.data(), doc.id);
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
          final data = normalizeBookMapForModel(doc.data(), doc.id);
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
          final data = normalizeBookMapForModel(doc.data(), doc.id);
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
  Future<List<Book>> getBooksByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final chunks = <List<String>>[];
      for (var i = 0; i < ids.length; i += 10) {
        chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
      }

      final List<Book> books = [];
      for (final chunk in chunks) {
        final snapshot = await _firestore
            .collection(_collection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        books.addAll(snapshot.docs.map((doc) {
          try {
            final data =
                mapFirestoreData(doc.data(), doc.id);
            return Book.fromJson(data);
          } catch (_) {
            return null;
          }
        }).whereType<Book>());
      }

      // Maintain order if possible (optional but good for history/library)
      final idMap = {for (var book in books) book.id: book};
      return ids.map((id) => idMap[id]).whereType<Book>().toList();
    } catch (e) {
      print('[FirebaseBookRepository] Error in getBooksByIds: $e');
      return [];
    }
  }

  @override
  Future<void> incrementViewCount(String bookId) async {
    await _firestore.collection(_collection).doc(bookId).set({
      'viewCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateReadingHistory(String userId, String bookId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) return;

      final data = snapshot.data();
      List<String> history = List<String>.from(data?['readingHistory'] ?? []);

      // Remove if exists to move to top
      history.remove(bookId);
      // Add to front
      history.insert(0, bookId);

      // Limit to 50 items
      if (history.length > 50) {
        history = history.sublist(0, 50);
      }

      await userDoc.update({'readingHistory': history});
    } catch (e) {
      print('[FirebaseBookRepository] Error updating reading history: $e');
    }
  }

  @override
  Future<List<Book>> getBooksByGenre(String genre, {int limit = 10, dynamic lastDoc}) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('genres', arrayContains: genre)
          .where('status', isEqualTo: 'published')
          .limit(limit);

      if (lastDoc != null && lastDoc is DocumentSnapshot) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        try {
          final data = normalizeBookMapForModel(doc.data() as Map<String, dynamic>, doc.id);
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
  Future<void> updateReadingProgress(String userId, String bookId, {required int chapterIndex, required double position}) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      await userDoc.update({
        'readingProgress.$bookId': {
          'chapterIndex': chapterIndex,
          'position': position,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      print('[FirebaseBookRepository] Error updating reading progress: $e');
    }
  }

  @override
  Future<List<String>> getUpvotedIABookIds() async {
    try {
      final snapshot = await _firestore.collection('ia_upvotes').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('[FirebaseBookRepository] Error getting upvoted IA IDs: $e');
      return [];
    }
  }
}
