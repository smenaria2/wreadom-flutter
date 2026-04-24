import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../domain/repositories/book_repository.dart';
import '../utils/firestore_utils.dart';
import '../../utils/map_utils.dart';

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
      return snapshot.docs
          .map((doc) {
            try {
              final data = normalizeBookMapForModel(
                asStringMap(doc.data()),
                doc.id,
              );
              return Book.fromJson(data);
            } catch (_) {
              return null;
            }
          })
          .whereType<Book>()
          .toList();
    } catch (e, stack) {
      debugPrint('[FirebaseBookRepository] Error getting books: $e');
      Error.throwWithStackTrace(e, stack);
    }
  }

  @override
  Future<List<Book>> getBooksByBookshelf(
    String bookshelf, {
    int limit = 10,
    dynamic lastDoc,
  }) async {
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
      return snapshot.docs
          .map((doc) {
            try {
              final data = normalizeBookMapForModel(
                asStringMap(doc.data()),
                doc.id,
              );
              return Book.fromJson(data);
            } catch (_) {
              return null;
            }
          })
          .whereType<Book>()
          .toList();
    } catch (e, stack) {
      debugPrint('[FirebaseBookRepository] Error getting bookshelf books: $e');
      Error.throwWithStackTrace(e, stack);
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

      return snapshot.docs
          .map((doc) {
            try {
              final data = normalizeBookMapForModel(
                asStringMap(doc.data()),
                doc.id,
              );
              return Book.fromJson(data);
            } catch (_) {
              return null;
            }
          })
          .whereType<Book>()
          .toList();
    } catch (e, stack) {
      debugPrint('[FirebaseBookRepository] Error getting original books: $e');
      Error.throwWithStackTrace(e, stack);
    }
  }

  @override
  Future<List<Book>> getOriginalBooksByTopic(
    String topic, {
    int limit = 40,
  }) async {
    final term = topic.trim();
    if (term.isEmpty) return [];

    try {
      final candidates = _topicSearchTerms(term);
      final byId = <String, Book>{};

      for (final topicValue in candidates) {
        final snapshot = await _firestore
            .collection(_collection)
            .where('isOriginal', isEqualTo: true)
            .where('status', isEqualTo: 'published')
            .where('topics', arrayContains: topicValue)
            .limit(limit)
            .get();

        for (final doc in snapshot.docs) {
          try {
            final data = normalizeBookMapForModel(
              asStringMap(doc.data()),
              doc.id,
            );
            final book = Book.fromJson(data);
            byId[book.id] = book;
          } catch (_) {}
        }
      }

      final books = byId.values.toList()
        ..sort(
          (a, b) => (b.updatedAt ?? b.createdAt ?? 0).compareTo(
            a.updatedAt ?? a.createdAt ?? 0,
          ),
        );
      return books.take(limit).toList();
    } catch (e) {
      debugPrint('[FirebaseBookRepository] Error getting topic originals: $e');
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

      return snapshot.docs
          .map((doc) {
            try {
              final data = normalizeBookMapForModel(
                asStringMap(doc.data()),
                doc.id,
              );
              return Book.fromJson(data);
            } catch (_) {
              return null;
            }
          })
          .whereType<Book>()
          .toList();
    } catch (e, stack) {
      debugPrint('[FirebaseBookRepository] Error getting user books: $e');
      Error.throwWithStackTrace(e, stack);
    }
  }

  @override
  Future<Book?> getBook(String bookId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(bookId).get();
      if (!doc.exists) return null;
      final data = normalizeBookMapForModel(asStringMap(doc.data()), doc.id);
      return Book.fromJson(data);
    } catch (e, stack) {
      debugPrint('[FirebaseBookRepository] Error getting book $bookId: $e');
      Error.throwWithStackTrace(e, stack);
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
          return snapshot.docs
              .map((doc) {
                try {
                  final data = normalizeBookMapForModel(
                    asStringMap(doc.data()),
                    doc.id,
                  );
                  return Book.fromJson(data);
                } catch (_) {
                  return null;
                }
              })
              .whereType<Book>()
              .toList();
        }
      } catch (_) {}

      // Fallback – download_count
      final fallback = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'published')
          .orderBy('download_count', descending: true)
          .limit(limit)
          .get();

      return fallback.docs
          .map((doc) {
            try {
              final data = normalizeBookMapForModel(
                asStringMap(doc.data()),
                doc.id,
              );
              return Book.fromJson(data);
            } catch (_) {
              return null;
            }
          })
          .whereType<Book>()
          .toList();
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

      return snapshot.docs
          .map((doc) {
            try {
              final data = normalizeBookMapForModel(
                asStringMap(doc.data()),
                doc.id,
              );
              return Book.fromJson(data);
            } catch (_) {
              return null;
            }
          })
          .whereType<Book>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Book>> searchBooks(String query, {int limit = 20}) async {
    final term = query.trim();
    if (term.isEmpty) return [];

    try {
      Query dbQuery = _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'published');

      if (term.startsWith('subject:')) {
        final genre = term.split(':').last.trim();
        dbQuery = dbQuery.where('genres', arrayContains: genre);
      } else if (term.startsWith('topic:')) {
        final topic = term.split(':').last.trim();
        // IA uses 'subject', Firebase uses 'subjects' or 'bookshelves'
        // For localized topics/subject tags, 'subjects' is the model field
        dbQuery = dbQuery.where('subjects', arrayContains: topic);
      } else {
        // Standard title prefix search
        dbQuery = dbQuery
            .where('title', isGreaterThanOrEqualTo: term)
            .where('title', isLessThanOrEqualTo: '$term\uf8ff');
      }

      final snapshot = await dbQuery.limit(limit).get();
      final books = _booksFromDocs(snapshot.docs);
      if (books.isNotEmpty) return books;
    } catch (e) {
      debugPrint('[FirebaseBookRepository] Error searching books: $e');
    }
    return [];
  }

  @override
  Future<List<Book>> searchOriginalBooks(String query, {int limit = 20}) async {
    final term = query.trim();
    if (term.isEmpty) return [];

    try {
      Query dbQuery = _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'published')
          .where('isOriginal', isEqualTo: true);

      if (term.startsWith('subject:')) {
        dbQuery = dbQuery.where(
          'subjects',
          arrayContains: term.split(':').last.trim(),
        );
      } else if (term.startsWith('topic:')) {
        dbQuery = dbQuery.where(
          'topics',
          arrayContains: term.split(':').last.trim(),
        );
      } else {
        dbQuery = dbQuery
            .where('title', isGreaterThanOrEqualTo: term)
            .where('title', isLessThanOrEqualTo: '$term\uf8ff');
      }

      final snapshot = await dbQuery.limit(limit).get();
      final books = _booksFromDocs(snapshot.docs);
      if (books.isNotEmpty) return books;
    } catch (e) {
      debugPrint('[FirebaseBookRepository] Error searching originals: $e');
    }
    return [];
  }

  @override
  Future<List<Book>> searchArchiveBooks(String query, {int limit = 20}) async {
    return [];
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

        books.addAll(
          snapshot.docs.map((doc) {
            try {
              final data = normalizeBookMapForModel(
                asStringMap(doc.data()),
                doc.id,
              );
              return Book.fromJson(data);
            } catch (_) {
              return null;
            }
          }).whereType<Book>(),
        );
      }

      // Maintain order if possible (optional but good for history/library)
      final idMap = {for (var book in books) book.id: book};
      return ids.map((id) => idMap[id]).whereType<Book>().toList();
    } catch (e) {
      debugPrint('[FirebaseBookRepository] Error in getBooksByIds: $e');
      return [];
    }
  }

  @override
  Future<void> recordBookView(String bookId, String viewerKey) async {
    final normalizedViewerKey = viewerKey.trim();
    if (bookId.trim().isEmpty || normalizedViewerKey.isEmpty) return;

    final bookRef = _firestore.collection(_collection).doc(bookId);
    final viewRef = bookRef
        .collection('views')
        .doc(Uri.encodeComponent(normalizedViewerKey));

    await _firestore.runTransaction((transaction) async {
      final existingView = await transaction.get(viewRef);
      if (existingView.exists) return;

      transaction.set(viewRef, {
        'viewerKey': normalizedViewerKey,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(bookRef, {
        'viewCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    });
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
      debugPrint('[FirebaseBookRepository] Error updating reading history: $e');
    }
  }

  @override
  Future<List<Book>> getBooksByGenre(
    String genre, {
    int limit = 10,
    dynamic lastDoc,
  }) async {
    final term = genre.trim();
    if (term.isEmpty) return [];

    try {
      final byId = <String, Book>{};
      final values = _searchTerms(term);

      for (final field in const [
        'genres',
        'subjects',
        'topics',
        'bookshelves',
      ]) {
        for (final value in values) {
          Query query = _firestore
              .collection(_collection)
              .where(field, arrayContains: value)
              .where('status', isEqualTo: 'published')
              .limit(limit);

          if (lastDoc != null && lastDoc is DocumentSnapshot) {
            query = query.startAfterDocument(lastDoc);
          }

          try {
            final snapshot = await query.get();
            for (final book in _booksFromDocs(snapshot.docs)) {
              byId[book.id] = book;
            }
          } catch (_) {}

          if (byId.length >= limit) {
            return byId.values.take(limit).toList();
          }
        }
      }

      if (byId.isNotEmpty) return byId.values.take(limit).toList();
    } catch (e) {
      debugPrint('[FirebaseBookRepository] Error getting genre books: $e');
    }
    return [];
  }

  List<Book> _booksFromDocs(Iterable<QueryDocumentSnapshot> docs) {
    return docs
        .map((doc) {
          try {
            final data = normalizeBookMapForModel(
              asStringMap(doc.data()),
              doc.id,
            );
            return Book.fromJson(data);
          } catch (_) {
            return null;
          }
        })
        .whereType<Book>()
        .toList();
  }

  List<String> _searchTerms(String term) {
    final trimmed = term.trim();
    final lower = trimmed.toLowerCase();
    final title = trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
    return {trimmed, lower, title, trimmed.replaceAll(' ', '_')}.toList();
  }

  List<String> _topicSearchTerms(String term) {
    final trimmed = term.trim();
    final normalizedSpaces = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    final lower = normalizedSpaces.toLowerCase();
    final title = normalizedSpaces
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
    return <String>{
      trimmed,
      normalizedSpaces,
      normalizedSpaces.replaceAll(' ', '_'),
      lower,
      lower.replaceAll(' ', '_'),
      title,
      title.replaceAll(' ', '_'),
    }.where((value) => value.trim().isNotEmpty).toList();
  }

  @override
  Future<void> updateReadingProgress(
    String userId,
    String bookId, {
    required int chapterIndex,
    required double position,
    int? completedChapterIndex,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final userSnapshot = await userDoc.get();
      final userData = userSnapshot.data();
      final readingProgressRaw = userData?['readingProgress'];
      final readingProgress = readingProgressRaw is Map
          ? Map<String, dynamic>.from(readingProgressRaw)
          : <String, dynamic>{};
      final existingProgressRaw = readingProgress[bookId];
      final existingProgress = existingProgressRaw is Map
          ? Map<String, dynamic>.from(existingProgressRaw)
          : <String, dynamic>{};
      final completedRaw = existingProgress['completedChapterIndexes'];
      final completedChapterIndexes = completedRaw is List
          ? completedRaw
                .whereType<num>()
                .map((index) => index.toInt())
                .toSet()
                .toList()
          : <int>[];
      if (completedChapterIndex != null &&
          !completedChapterIndexes.contains(completedChapterIndex)) {
        completedChapterIndexes.add(completedChapterIndex);
        completedChapterIndexes.sort();
      }

      await userDoc.set({
        'readingProgress': {
          bookId: {
            ...existingProgress,
            'chapterIndex': chapterIndex,
            'position': position,
            'completedChapterIndexes': completedChapterIndexes,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint(
        '[FirebaseBookRepository] Error updating reading progress: $e',
      );
    }
  }

  @override
  Future<List<Chapter>> getChapters(String bookId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(bookId)
          .collection('chapters')
          .orderBy('order')
          .get();

      if (snapshot.docs.isEmpty) {
        // Fallback: check if they are embedded in the book document
        final book = await getBook(bookId);
        return book?.chapters ?? [];
      }

      return snapshot.docs.map((doc) {
        final data = asStringMap(doc.data());
        data['id'] = doc.id;
        data['title'] = data['title']?.toString() ?? 'Chapter';
        data['content'] = data['content']?.toString() ?? '';
        data['index'] = data['index'] is num
            ? (data['index'] as num).toInt()
            : data['order'] is num
            ? (data['order'] as num).toInt()
            : int.tryParse(data['index']?.toString() ?? '') ??
                  int.tryParse(data['order']?.toString() ?? '') ??
                  0;
        if (data['lastSavedAt'] is Timestamp) {
          data['lastSavedAt'] =
              (data['lastSavedAt'] as Timestamp).millisecondsSinceEpoch;
        }
        return Chapter.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('[FirebaseBookRepository] Error getting chapters: $e');
      return [];
    }
  }

  @override
  Future<List<String>> getUpvotedIABookIds() async {
    try {
      final snapshot = await _firestore.collection('ia_upvotes').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('[FirebaseBookRepository] Error getting upvoted IA IDs: $e');
      return [];
    }
  }

  @override
  Future<List<Book>> getUpvotedIABooks({int limit = 20}) async {
    return [];
  }
}
