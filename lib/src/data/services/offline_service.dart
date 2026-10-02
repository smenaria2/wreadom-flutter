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
  static const int _schemaVersion = 2;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized &&
        Hive.isBoxOpen(_booksBoxName) &&
        Hive.isBoxOpen(_chaptersBoxName)) {
      return;
    }
    await Hive.openBox(_booksBoxName);
    await Hive.openBox(_chaptersBoxName);
    // Convert old packages once, promoting the complete package with one Hive write.
    for (final key in _booksBox.keys.toList()) {
      final raw = asStringMap(_booksBox.get(key));
      if (raw['schemaVersion'] == _schemaVersion) continue;
      final chapters = _chaptersBox.get(key);
      if (chapters is! List) {
        continue; // Preserve broken originals for recovery.
      }
      final publicChapters = chapters
          .map((value) => asStringMap(value)..remove('versions'))
          .where(
            (value) =>
                value['content'] is String &&
                value['isHidden'] != true &&
                value['status'] != 'draft',
          )
          .toList();
      // Old packages could include hidden or draft chapters; keep the public
      // ones. A package with none left cannot be read offline.
      if (publicChapters.isEmpty) {
        await _booksBox.delete(key);
        await _chaptersBox.delete(key);
        continue;
      }
      final metadata = asStringMap(raw['book'] ?? raw)..remove('chapters');
      await _booksBox.put(key, {
        ...raw,
        'book': metadata,
        'schemaVersion': _schemaVersion,
        'chapters': publicChapters,
        'complete': true,
      });
      await _chaptersBox.delete(key);
    }
    _initialized = true;
  }

  Box get _booksBox => Hive.box(_booksBoxName);
  Box get _chaptersBox => Hive.box(_chaptersBoxName);

  Future<bool> isBookDownloaded(String bookId) async {
    await init();
    final record = asStringMap(_booksBox.get(bookId));
    return record['schemaVersion'] == _schemaVersion &&
        record['complete'] == true;
  }

  Future<void> downloadBook(Book book, List<Chapter> chapters) async {
    try {
      await init();
      if (chapters.isEmpty ||
          chapters.any((ch) => ch.isHidden || ch.status == 'draft')) {
        throw StateError(
          'A complete public book is required for offline download.',
        );
      }
      final metadata = asStringMap(_hiveSafeValue(book))..remove('chapters');
      final publicChapters = chapters
          .map(
            (chapter) =>
                asStringMap(_hiveSafeValue(chapter))..remove('versions'),
          )
          .toList();
      await _booksBox.put(book.id, {
        'schemaVersion': _schemaVersion,
        'complete': true,
        'downloadedAt': DateTime.now().millisecondsSinceEpoch,
        'book': metadata,
        'chapters': publicChapters,
      });

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
            final rawBook = _booksBox.get(key);
            final map = asStringMap(rawBook);
            if (map['schemaVersion'] != _schemaVersion ||
                map['complete'] != true) {
              return null;
            }
            final bookJson = map['book'];
            final downloadedAtMs = (map['downloadedAt'] as num?)?.toInt();
            final rawChapters = map['chapters'];
            return OfflineBookEntry(
              book: Book.fromJson(asStringMap(bookJson)),
              downloadedAt: downloadedAtMs == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(downloadedAtMs),
              sizeBytes:
                  _estimatedSizeBytes(rawBook) +
                  _estimatedSizeBytes(rawChapters),
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
    final record = asStringMap(_booksBox.get(bookId));
    if (record['schemaVersion'] != _schemaVersion ||
        record['complete'] != true) {
      return [];
    }
    final chaptersJson = record['chapters'];
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
        .where((chapter) => !chapter.isHidden && chapter.status != 'draft')
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
