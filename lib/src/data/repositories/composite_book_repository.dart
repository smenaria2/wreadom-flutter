import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../domain/repositories/book_repository.dart';
import 'firebase_book_repository.dart';
import 'archive_book_repository.dart';

class CompositeBookRepository implements BookRepository {
  CompositeBookRepository({
    FirebaseBookRepository? firebaseRepo,
    ArchiveBookRepository? archiveRepo,
  })  : _firebaseRepo = firebaseRepo ?? FirebaseBookRepository(),
        _archiveRepo = archiveRepo ?? ArchiveBookRepository();

  final FirebaseBookRepository _firebaseRepo;
  final ArchiveBookRepository _archiveRepo;

  List<String>? _cachedUpvotedIds;
  DateTime? _lastCacheTime;

  Future<List<String>> _getUpvotedIds() async {
    final now = DateTime.now();
    if (_cachedUpvotedIds != null &&
        _lastCacheTime != null &&
        now.difference(_lastCacheTime!) < const Duration(minutes: 5)) {
      return _cachedUpvotedIds!;
    }
    _cachedUpvotedIds = await _firebaseRepo.getUpvotedIABookIds();
    _lastCacheTime = now;
    return _cachedUpvotedIds!;
  }

  Future<List<Book>> _filterArchiveBooks(List<Book> books) async {
    final upvotedIds = await _getUpvotedIds();
    final idSet = upvotedIds.toSet();
    return books.where((b) => idSet.contains(b.id)).toList();
  }

  bool _isFirebaseId(String id) {
    if (id.startsWith('local-')) return false;
    return id.length == 20 && RegExp(r'^[a-zA-Z0-9]{20}$').hasMatch(id);
  }

  @override
  Future<Book?> getBook(String bookId) async {
    // Try Firebase first (handles both Firestore doc IDs and numeric IDs
    // stored as documents in the books collection)
    try {
      final firebaseBook = await _firebaseRepo.getBook(bookId);
      if (firebaseBook != null) return firebaseBook;
    } catch (_) {
      // Firebase lookup failed, try Archive
    }
    
    // Fall back to Internet Archive
    try {
      return await _archiveRepo.getBook(bookId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Book>> getBooks({int limit = 10, dynamic lastDoc}) {
    return _firebaseRepo.getBooks(limit: limit, lastDoc: lastDoc);
  }

  @override
  Future<List<Book>> getBooksByBookshelf(String bookshelf, {int limit = 10, dynamic lastDoc}) {
    // Bookshelves are common in Firebase, Archive is handled by subject
    return _firebaseRepo.getBooksByBookshelf(bookshelf, limit: limit, lastDoc: lastDoc);
  }

  @override
  Future<List<Book>> getOriginalBooks({int limit = 10}) {
    return _firebaseRepo.getOriginalBooks(limit: limit);
  }

  @override
  Future<List<Book>> getUserBooks(String userId) {
    return _firebaseRepo.getUserBooks(userId);
  }

  @override
  Future<List<Book>> getPopularBooks({int limit = 10}) async {
    final firebaseResults = await _firebaseRepo.getPopularBooks(limit: limit);
    if (firebaseResults.length < limit) {
      final archiveResults = await _archiveRepo.getPopularBooks(limit: limit * 2);
      final filteredArchive = await _filterArchiveBooks(archiveResults);
      
      final combined = [...firebaseResults, ...filteredArchive];
      return combined.length > limit ? combined.sublist(0, limit) : combined;
    }
    return firebaseResults;
  }

  @override
  Future<List<Book>> getRecentBooks({int limit = 10}) async {
    final firebaseResults = await _firebaseRepo.getRecentBooks(limit: limit);
    if (firebaseResults.length < limit) {
      final archiveResults = await _archiveRepo.getRecentBooks(limit: limit * 2); // Fetch more for filtering
      final filteredArchive = await _filterArchiveBooks(archiveResults);
      
      final combined = [...firebaseResults, ...filteredArchive];
      return combined.length > limit ? combined.sublist(0, limit) : combined;
    }
    return firebaseResults;
  }

  @override
  Future<List<Book>> getBooksByGenre(String genre, {int limit = 10, dynamic lastDoc}) async {
    // Try Firebase first
    final firebaseResults = await _firebaseRepo.getBooksByGenre(genre, limit: limit, lastDoc: lastDoc);
    
    // If we want more or have none, Archive is great for genre (subject) browsing
    if (firebaseResults.length < limit) {
      final archiveResults = await _archiveRepo.getBooksByGenre(genre, limit: limit * 2); // Fetch more for filtering
      final filteredArchive = await _filterArchiveBooks(archiveResults);
      
      final combined = [...firebaseResults, ...filteredArchive];
      return combined.length > limit ? combined.sublist(0, limit) : combined;
    }
    
    return firebaseResults;
  }

  @override
  Future<List<Book>> searchBooks(String query, {int limit = 20}) async {
    // Search both repositories in parallel
    final results = await Future.wait([
      _firebaseRepo.searchBooks(query, limit: limit),
      _archiveRepo.searchBooks(query, limit: limit * 2),
    ]);

    final firebaseResults = results[0];
    final archiveResults = results[1];
    
    // Filter Archive results by upvotes
    final filteredArchive = await _filterArchiveBooks(archiveResults);

    // Combine and limit
    final combined = [...firebaseResults, ...filteredArchive];
    return combined.length > limit ? combined.sublist(0, limit) : combined;
  }

  @override
  Future<List<Book>> getBooksByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final firebaseIds = <String>[];
    final archiveIds = <String>[];

    for (final id in ids) {
      if (_isFirebaseId(id)) {
        firebaseIds.add(id);
      } else {
        archiveIds.add(id);
      }
    }

    final results = <Book>[];
    if (firebaseIds.isNotEmpty) {
      results.addAll(await _firebaseRepo.getBooksByIds(firebaseIds));
    }
    if (archiveIds.isNotEmpty) {
      results.addAll(await _archiveRepo.getBooksByIds(archiveIds));
    }

    // Sort to original order
    final idMap = {for (var book in results) book.id: book};
    return ids.map((id) => idMap[id]).whereType<Book>().toList();
  }

  @override
  Future<void> incrementViewCount(String bookId) async {
    if (_isFirebaseId(bookId)) {
      await _firebaseRepo.incrementViewCount(bookId);
    }
  }

  @override
  Future<List<Chapter>> getChapters(String bookId) async {
    if (_isFirebaseId(bookId)) {
      return await _firebaseRepo.getChapters(bookId);
    } else {
      return await _archiveRepo.getChapters(bookId);
    }
  }

  @override
  Future<List<String>> getUpvotedIABookIds() {
    return _firebaseRepo.getUpvotedIABookIds();
  }

  @override
  Future<void> updateReadingHistory(String userId, String bookId) async {
    // History is tracked in Firebase regardless of book source
    await _firebaseRepo.updateReadingHistory(userId, bookId);
  }

  @override
  Future<void> updateReadingProgress(String userId, String bookId,
      {required int chapterIndex, required double position}) async {
    // Progress is tracked in Firebase regardless of book source
    await _firebaseRepo.updateReadingProgress(userId, bookId,
        chapterIndex: chapterIndex, position: position);
  }
}
