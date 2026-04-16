import 'package:hive_ce/hive.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';

class OfflineService {
  static const String _booksBoxName = 'offline_books';
  static const String _chaptersBoxName = 'offline_chapters';

  Future<void> init() async {
    await Hive.openBox(_booksBoxName);
    await Hive.openBox(_chaptersBoxName);
  }

  Box get _booksBox => Hive.box(_booksBoxName);
  Box get _chaptersBox => Hive.box(_chaptersBoxName);

  Future<bool> isBookDownloaded(String bookId) async {
    return _booksBox.containsKey(bookId);
  }

  Future<void> downloadBook(Book book, List<Chapter> chapters) async {
    try {
      // 1. Save metadata
      await _booksBox.put(book.id, book.toJson());

      // 2. Save chapters
      final chaptersJson = chapters.map((c) => c.toJson()).toList();
      await _chaptersBox.put(book.id, chaptersJson);

      // 3. Download related files if any (e.g. cover or epub for local storage)
      // For now, we mainly cache the text content in Hive for simplicity
      // but we could also download the physical file.
      
      debugPrint('[OfflineService] Book ${book.title} downloaded successfully.');
    } catch (e) {
      debugPrint('[OfflineService] Error downloading book: $e');
      rethrow;
    }
  }

  List<Book> getDownloadedBooks() {
    return _booksBox.values.map((json) {
      return Book.fromJson(Map<String, dynamic>.from(json));
    }).toList();
  }

  Future<List<Chapter>> getDownloadedChapters(String bookId) async {
    final chaptersJson = _chaptersBox.get(bookId);
    if (chaptersJson == null) return [];
    
    return (chaptersJson as List).map((json) {
      return Chapter.fromJson(Map<String, dynamic>.from(json));
    }).toList();
  }

  Future<void> deleteBook(String bookId) async {
    await _booksBox.delete(bookId);
    await _chaptersBox.delete(bookId);
    debugPrint('[OfflineService] Book $bookId deleted from offline storage.');
  }
}
