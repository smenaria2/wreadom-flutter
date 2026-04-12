import '../../domain/models/book.dart';

abstract class BookRepository {
  Future<List<Book>> getBooks({int limit = 10, dynamic lastDoc});
  Future<List<Book>> getBooksByBookshelf(String bookshelf, {int limit = 10, dynamic lastDoc});
  Future<List<Book>> getOriginalBooks({int limit = 10});
  Future<List<Book>> getUserBooks(String userId);
  Future<Book?> getBook(String bookId);
  Future<List<Book>> getPopularBooks({int limit = 10});
  Future<List<Book>> getRecentBooks({int limit = 10});
  Future<List<Book>> searchBooks(String query, {int limit = 20});
  Future<void> incrementViewCount(String bookId);
}
