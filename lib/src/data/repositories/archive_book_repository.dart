import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../domain/repositories/book_repository.dart';
import '../services/archive_book_service.dart';

class ArchiveBookRepository implements BookRepository {
  ArchiveBookRepository({ArchiveBookService? service})
      : _service = service ?? ArchiveBookService();

  final ArchiveBookService _service;

  @override
  Future<Book?> getBook(String bookId) async {
    try {
      return await _service.getBookMetadata(bookId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Book>> getBooks({int limit = 10, dynamic lastDoc}) async {
    final result = await _service.searchBooks(rows: limit);
    return result['results'] as List<Book>;
  }

  @override
  Future<List<Book>> getBooksByBookshelf(String bookshelf, {int limit = 10, dynamic lastDoc}) async {
    final result = await _service.searchBooks(subject: bookshelf, rows: limit);
    return result['results'] as List<Book>;
  }

  @override
  Future<List<Book>> getOriginalBooks({int limit = 10}) async {
    // Archive doesn't have "Originals" in the same sense as Librebook Firestore
    return [];
  }

  @override
  Future<List<Book>> getUserBooks(String userId) async {
    // Archive doesn't store per-user books in our sense
    return [];
  }

  @override
  Future<List<Book>> getPopularBooks({int limit = 10}) async {
    final result = await _service.searchBooks(rows: limit, sort: 'downloads desc');
    return result['results'] as List<Book>;
  }

  @override
  Future<List<Book>> getRecentBooks({int limit = 10}) async {
    final result = await _service.searchBooks(rows: limit, sort: 'publicdate desc');
    return result['results'] as List<Book>;
  }

  @override
  Future<List<Book>> searchBooks(String query, {int limit = 20}) async {
    final result = await _service.searchBooks(query: query, rows: limit);
    return result['results'] as List<Book>;
  }

  @override
  Future<List<Book>> getBooksByIds(List<String> ids) async {
    try {
      return await _service.getBooksByIds(ids);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> incrementViewCount(String bookId) async {
    // We don't increment view counts on Archive.org
  }

  @override
  Future<void> updateReadingHistory(String userId, String bookId) async {
    // Handled by Composite/Firebase repository
  }

  @override
  Future<void> updateReadingProgress(String userId, String bookId,
      {required int chapterIndex, required double position}) async {
    // Handled by Composite/Firebase repository
  }

  @override
  Future<List<Book>> getBooksByGenre(String genre, {int limit = 10, dynamic lastDoc}) async {
    // Map genre to archive subjects
    final result = await _service.searchBooks(subject: genre, rows: limit);
    return result['results'] as List<Book>;
  }

  @override
  Future<List<Chapter>> getChapters(String bookId) async {
    return await _service.fetchBookChapters(bookId);
  }

  @override
  Future<List<String>> getUpvotedIABookIds() async => [];
}
