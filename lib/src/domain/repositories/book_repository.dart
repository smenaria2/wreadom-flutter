import '../models/book.dart';
import '../models/chapter.dart';

abstract class BookRepository {
  Future<List<Book>> getBooks({int limit = 10, dynamic lastDoc});
  Future<List<Book>> getBooksByBookshelf(
    String bookshelf, {
    int limit = 10,
    dynamic lastDoc,
  });
  Future<List<Book>> getOriginalBooks({int limit = 10});
  Future<List<Book>> getOriginalBooksByTopic(String topic, {int limit = 40});
  Future<List<Book>> getUserBooks(String userId);
  Future<Book?> getBook(String bookId);
  Future<List<Chapter>> getChapters(String bookId);
  Future<List<Book>> getPopularBooks({int limit = 10});
  Future<List<Book>> getRecentBooks({int limit = 10});
  Future<List<Book>> searchBooks(String query, {int limit = 20});
  Future<List<Book>> searchOriginalBooks(String query, {int limit = 20});
  Future<List<Book>> searchArchiveBooks(String query, {int limit = 20});
  Future<List<Book>> getBooksByIds(List<String> ids);
  Future<void> incrementViewCount(String bookId);
  Future<void> updateReadingHistory(String userId, String bookId);
  Future<List<Book>> getBooksByGenre(
    String genre, {
    int limit = 10,
    dynamic lastDoc,
  });
  Future<void> updateReadingProgress(
    String userId,
    String bookId, {
    required int chapterIndex,
    required double position,
    int? completedChapterIndex,
  });
  Future<List<String>> getUpvotedIABookIds();
  Future<List<Book>> getUpvotedIABooks({int limit = 20});
}
