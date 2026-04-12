import '../models/user_model.dart';

abstract class BookmarkRepository {
  Future<List<Bookmark>> getUserBookmarks(String userId);
  Future<List<Bookmark>> getBookBookmarks(String userId, String bookId);
  Future<String> addBookmark(Bookmark bookmark);
  Future<void> removeBookmark(String bookmarkId);
}
