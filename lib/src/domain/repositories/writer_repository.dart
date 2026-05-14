import '../models/book.dart';
import '../models/chapter.dart';

abstract class WriterRepository {
  Future<List<Book>> getUserBooks(String userId, {String status = 'all'});
  Future<List<Book>> getImportableSingleChapterDrafts(
    String userId, {
    String? excludeBookId,
  });
  Future<String> createBook(Book book);
  Future<void> updateBook(String bookId, Book book);
  Future<String> moveChapterToStandaloneDraft({
    required Book sourceBook,
    required Chapter chapter,
    required List<Chapter> remainingChapters,
    required String ownerUserId,
  });
  Future<List<Chapter>> importSingleDraftsToBook({
    required Book targetBook,
    required List<Book> sourceDrafts,
  });
  Future<void> respondToCollaborationRequest({
    required String bookId,
    required String userId,
    required bool accept,
  });
  Future<void> deleteBook(String bookId);
}
