import '../models/book.dart';
import '../models/chapter.dart';
import '../models/chapter_edit_lock.dart';

abstract class WriterRepository {
  Future<List<Book>> getUserBooks(String userId, {String status = 'all'});
  Future<List<Book>> getImportableSingleChapterDrafts(
    String userId, {
    String? excludeBookId,
  });
  Future<String> createBook(Book book);

  /// Returns the canonical chapter revisions committed by the server.
  Future<List<Chapter>> updateBook(
    String bookId,
    Book book, {
    Set<String> deletedChapterIds = const <String>{},
    Map<String, int> baseChapterRevisions = const <String, int>{},
    Set<String> changedChapterIds = const <String>{},
  });
  Future<List<Chapter>> getAuthoringChapters(String bookId);
  Stream<List<ChapterEditLock>> watchChapterLocks(String bookId);
  Future<bool> acquireChapterLock(
    String bookId,
    String chapterId,
    ChapterLockHolder holder,
  );
  Future<void> renewChapterLock(String bookId, String chapterId);
  Future<void> releaseChapterLock(String bookId, String chapterId);
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
