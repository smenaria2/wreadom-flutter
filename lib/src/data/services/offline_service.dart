import 'package:hive_ce/hive.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../utils/map_utils.dart';

class OfflineService {
  factory OfflineService() => _instance;
  OfflineService._();

  static final OfflineService _instance = OfflineService._();
  static const String _booksBoxName = 'offline_books';
  static const String _chaptersBoxName = 'offline_chapters';
  static const int _schemaVersion = 1;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.openBox(_booksBoxName);
    await Hive.openBox(_chaptersBoxName);
    _initialized = true;
  }

  Box get _booksBox => Hive.box(_booksBoxName);
  Box get _chaptersBox => Hive.box(_chaptersBoxName);

  Future<bool> isBookDownloaded(String bookId) async {
    await init();
    return _booksBox.containsKey(bookId);
  }

  Future<void> downloadBook(Book book, List<Chapter> chapters) async {
    try {
      await init();
      // 1. Save metadata
      await _booksBox.put(book.id, {
        'schemaVersion': _schemaVersion,
        'downloadedAt': DateTime.now().millisecondsSinceEpoch,
        'book': book.toJson(),
      });

      // 2. Save chapters
      final chaptersJson = chapters.map((c) => c.toJson()).toList();
      await _chaptersBox.put(book.id, chaptersJson);

      // 3. Download related files if any (e.g. cover or epub for local storage)
      // For now, we mainly cache the text content in Hive for simplicity
      // but we could also download the physical file.

      debugPrint(
        '[OfflineService] Book ${book.title} downloaded successfully.',
      );
    } catch (e) {
      debugPrint('[OfflineService] Error downloading book: $e');
      rethrow;
    }
  }

  List<Book> getDownloadedBooks() {
    if (!Hive.isBoxOpen(_booksBoxName)) return [];
    return _booksBox.values
        .map((json) {
          final map = asStringMap(json);
          final bookJson = map['book'] is Map ? map['book'] : map;
          return Book.fromJson(asStringMap(bookJson));
        })
        .whereType<Book>()
        .toList();
  }

  // Removed local _ensureStringMap in favor of map_utils.dart

  Future<List<Chapter>> getDownloadedChapters(String bookId) async {
    await init();
    final chaptersJson = _chaptersBox.get(bookId);
    if (chaptersJson == null) return [];

    return (chaptersJson as List).map((json) {
      final map = asStringMap(json);
      map['id'] = map['id']?.toString() ?? '';
      map['title'] = map['title']?.toString() ?? 'Chapter';
      map['content'] = map['content']?.toString() ?? '';
      map['index'] = map['index'] is num
          ? (map['index'] as num).toInt()
          : int.tryParse(map['index']?.toString() ?? '') ?? 0;
      return Chapter.fromJson(map);
    }).toList();
  }

  Future<void> deleteBook(String bookId) async {
    await init();
    await _booksBox.delete(bookId);
    await _chaptersBox.delete(bookId);
    debugPrint('[OfflineService] Book $bookId deleted from offline storage.');
  }
}
