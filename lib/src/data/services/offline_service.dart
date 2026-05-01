import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/author.dart';
import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../utils/map_utils.dart';

class OfflineBookEntry {
  const OfflineBookEntry({
    required this.book,
    required this.downloadedAt,
    required this.sizeBytes,
  });

  final Book book;
  final DateTime? downloadedAt;
  final int sizeBytes;
}

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
        'book': _hiveSafeValue(book),
      });

      // 2. Save chapters
      final chaptersJson = _hiveSafeValue(chapters);
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
    return getDownloadedBookEntries()
        .map((entry) => entry.book)
        .whereType<Book>()
        .toList();
  }

  List<OfflineBookEntry> getDownloadedBookEntries() {
    if (!Hive.isBoxOpen(_booksBoxName)) return [];
    return _booksBox.keys
        .map((key) {
          try {
            final bookId = key.toString();
            final rawBook = _booksBox.get(key);
            final map = asStringMap(rawBook);
            final bookJson = map['book'] is Map ? map['book'] : map;
            final downloadedAtMs = (map['downloadedAt'] as num?)?.toInt();
            final rawChapters = _chaptersBox.get(bookId);
            return OfflineBookEntry(
              book: Book.fromJson(asStringMap(bookJson)),
              downloadedAt: downloadedAtMs == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(downloadedAtMs),
              sizeBytes: _estimatedSizeBytes(rawBook) + _estimatedSizeBytes(rawChapters),
            );
          } catch (error) {
            debugPrint(
              '[OfflineService] Skipping invalid offline book metadata: $error',
            );
            return null;
          }
        })
        .whereType<OfflineBookEntry>()
        .toList();
  }

  Future<List<Chapter>> getDownloadedChapters(String bookId) async {
    await init();
    final chaptersJson = _chaptersBox.get(bookId);
    if (chaptersJson is! List) return [];

    return chaptersJson
        .map((json) {
          try {
            final map = asStringMap(json);
            map['id'] = map['id']?.toString() ?? '';
            map['title'] = map['title']?.toString() ?? 'Chapter';
            map['content'] = map['content']?.toString() ?? '';
            map['index'] = map['index'] is num
                ? (map['index'] as num).toInt()
                : int.tryParse(map['index']?.toString() ?? '') ?? 0;
            return Chapter.fromJson(map);
          } catch (error) {
            debugPrint(
              '[OfflineService] Skipping invalid offline chapter: $error',
            );
            return null;
          }
        })
        .whereType<Chapter>()
        .toList();
  }

  Future<void> deleteBook(String bookId) async {
    await init();
    await _booksBox.delete(bookId);
    await _chaptersBox.delete(bookId);
    debugPrint('[OfflineService] Book $bookId deleted from offline storage.');
  }

  dynamic _hiveSafeValue(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is Book) return _hiveSafeValue(value.toJson());
    if (value is Author) return _hiveSafeValue(value.toJson());
    if (value is Chapter) return _hiveSafeValue(value.toJson());
    if (value is ChapterVersion) return _hiveSafeValue(value.toJson());
    if (value is List) {
      return value.map(_hiveSafeValue).toList(growable: false);
    }
    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), _hiveSafeValue(mapValue)),
      );
    }
    return value.toString();
  }

  int _estimatedSizeBytes(dynamic value) {
    if (value == null) return 0;
    try {
      return utf8.encode(jsonEncode(_hiveSafeValue(value))).length;
    } catch (_) {
      return utf8.encode(value.toString()).length;
    }
  }
}
