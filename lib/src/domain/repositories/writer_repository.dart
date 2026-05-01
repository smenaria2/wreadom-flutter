import '../models/book.dart';

abstract class WriterRepository {
  Future<List<Book>> getUserBooks(String userId, {String status = 'all'});
  Future<String> createBook(Book book);
  Future<void> updateBook(String bookId, Book book);
  Future<void> respondToCollaborationRequest({
    required String bookId,
    required String userId,
    required bool accept,
  });
  Future<void> deleteBook(String bookId);
}
