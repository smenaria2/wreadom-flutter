import 'dart:convert';

const chapterStorageVersion = 2;
const chapterDocumentBudget = 700 * 1024;

class ChapterStorageException implements Exception {
  const ChapterStorageException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => message;
}

void requireChapterSchema(Object? value) {
  if (value != chapterStorageVersion) {
    throw const ChapterStorageException(
      'unsupported-schema',
      'This book is not ready for this app version. Please retry after the update.',
    );
  }
}

String chapterOrderKey(int index) {
  if (index < 0 || index > 999999999999) {
    throw ArgumentError('Invalid chapter position.');
  }
  return index.toString().padLeft(12, '0');
}

void assertChapterBudget(Object value) {
  if (utf8.encode(jsonEncode(value)).length + 8192 > chapterDocumentBudget) {
    throw const ChapterStorageException(
      'too-large',
      'This chapter is too large. Split it into smaller chapters. Your local draft is preserved.',
    );
  }
}

class ChapterDirectoryEntry {
  const ChapterDirectoryEntry({
    required this.id,
    required this.title,
    required this.orderKey,
    required this.publishedRevision,
    this.wordCount,
  });
  final String id;
  final String title;
  final String orderKey;
  final int publishedRevision;
  final int? wordCount;

  factory ChapterDirectoryEntry.fromMap(String id, Map<String, dynamic> data) {
    if (id.isEmpty ||
        data['title'] is! String ||
        data['orderKey'] is! String ||
        data['publishedRevision'] is! int ||
        (data['publishedRevision'] as int) < 1) {
      throw const ChapterStorageException(
        'invalid-data',
        'The chapter directory is incomplete.',
      );
    }
    return ChapterDirectoryEntry(
      id: id,
      title: data['title'] as String,
      orderKey: data['orderKey'] as String,
      publishedRevision: data['publishedRevision'] as int,
      wordCount: data['wordCount'] is int ? data['wordCount'] as int : null,
    );
  }

  String readBody(Map<String, dynamic>? data) {
    if (data == null) {
      throw const ChapterStorageException(
        'missing',
        'This chapter is no longer available.',
      );
    }
    if (data['content'] is! String) {
      throw const ChapterStorageException(
        'invalid-data',
        'Chapter content is missing.',
      );
    }
    if (data['publishedRevision'] != publishedRevision) {
      throw const ChapterStorageException(
        'revision-mismatch',
        'This chapter changed. Refresh the chapter list and retry.',
      );
    }
    return data['content'] as String;
  }
}
