import 'package:hive_ce/hive.dart';

import '../../domain/models/author.dart';
import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../utils/map_utils.dart';

/// The outcome of opening a Writerpad checkpoint. A broken checkpoint must
/// never prevent the editor from opening; callers can surface [recovered] to
/// explain that an older on-device draft was migrated.
class WriterDraftLoadResult {
  const WriterDraftLoadResult({
    this.book,
    this.recovered = false,
    this.quarantined = false,
  });

  final Book? book;
  final bool recovered;
  final bool quarantined;
}

abstract interface class WriterDraftStore {
  Future<void> saveDraft({required String draftKey, required Book book});
  Future<Book?> getDraft(String draftKey);
  Future<WriterDraftLoadResult> loadDraft(String draftKey);
  Future<void> deleteDraft(String draftKey);
}

class WriterDraftService implements WriterDraftStore {
  factory WriterDraftService() => _instance;
  WriterDraftService._();

  static final WriterDraftService _instance = WriterDraftService._();
  static const String _boxName = 'writer_drafts';
  static const int _schemaVersion = 2;
  static const String _quarantinePrefix = 'quarantined:';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.openBox(_boxName);
    _initialized = true;
  }

  Box get _box => Hive.box(_boxName);

  @override
  Future<void> saveDraft({required String draftKey, required Book book}) async {
    await init();
    await _box.put(draftKey, {
      'schemaVersion': _schemaVersion,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
      // Keep the checkpoint wire format independent from generated model
      // serializers. Older versions stored model objects in nested lists,
      // which Hive could restore as strings on some platforms.
      'snapshot': _encodeSnapshot(book),
    });
  }

  @override
  Future<Book?> getDraft(String draftKey) async {
    return (await loadDraft(draftKey)).book;
  }

  @override
  Future<WriterDraftLoadResult> loadDraft(String draftKey) async {
    await init();
    final raw = _box.get(draftKey);
    if (raw == null) return const WriterDraftLoadResult();

    try {
      final data = asStringMap(raw);
      final isCurrent = data['schemaVersion'] == _schemaVersion;
      final bookJson = isCurrent
          ? _decodeCurrentSnapshot(asStringMap(data['snapshot']))
          : _decodeLegacyBook(asStringMap(data['book']));
      if (bookJson.isEmpty) {
        await _quarantine(draftKey, raw, 'empty draft payload');
        return const WriterDraftLoadResult(quarantined: true);
      }
      return WriterDraftLoadResult(
        book: Book.fromJson(bookJson),
        recovered: !isCurrent,
      );
    } catch (error) {
      await _quarantine(draftKey, raw, error.toString());
      return const WriterDraftLoadResult(quarantined: true);
    }
  }

  @override
  Future<void> deleteDraft(String draftKey) async {
    await init();
    await _box.delete(draftKey);
  }

  Map<String, dynamic> _encodeSnapshot(Book book) {
    final bookJson = asStringMap(_hiveSafeValue(book.toJson()));
    final chapters = (book.chapters ?? const <Chapter>[])
        .map((chapter) => _chapterJson(chapter))
        .toList(growable: false);
    bookJson.remove('chapters');
    return <String, dynamic>{'book': bookJson, 'chapters': chapters};
  }

  Map<String, dynamic> _chapterJson(Chapter chapter) {
    return <String, dynamic>{
      'id': chapter.id,
      'title': chapter.title,
      'content': chapter.content,
      'index': chapter.index,
      'status': chapter.status,
      'versions': (chapter.versions ?? const <ChapterVersion>[])
          .map(
            (version) => <String, dynamic>{
              'content': version.content,
              'timestamp': version.timestamp,
              'wordCount': version.wordCount,
            },
          )
          .toList(growable: false),
      'lastSavedAt': chapter.lastSavedAt,
      'isTitleLocked': chapter.isTitleLocked,
      'originalBookId': chapter.originalBookId,
      'isHidden': chapter.isHidden,
      'revision': chapter.revision,
    };
  }

  Map<String, dynamic> _decodeCurrentSnapshot(Map<String, dynamic> snapshot) {
    if (snapshot.isEmpty || snapshot['book'] is! Map) {
      return const <String, dynamic>{};
    }
    final book = asStringMap(snapshot['book']);
    book['chapters'] = _normalizeChapters(snapshot['chapters']);
    return _normalizeBook(book);
  }

  Map<String, dynamic> _decodeLegacyBook(Map<String, dynamic> book) {
    if (book.isEmpty) return const <String, dynamic>{};
    book['chapters'] = _normalizeChapters(book['chapters']);
    return _normalizeBook(book);
  }

  Map<String, dynamic> _normalizeBook(Map<String, dynamic> book) {
    book['id'] = book['id']?.toString() ?? '';
    book['title'] = book['title']?.toString() ?? 'Untitled Story';
    book['authors'] = (book['authors'] is List ? book['authors'] as List : [])
        .map(
          (value) => value is Map
              ? asStringMap(value)
              : <String, dynamic>{'name': value?.toString() ?? 'Author'},
        )
        .toList(growable: false);
    for (final key in const ['subjects', 'languages', 'bookshelves']) {
      book[key] = (book[key] is List ? book[key] as List : const <dynamic>[])
          .map((value) => value.toString())
          .toList(growable: false);
    }
    book['formats'] = book['formats'] is Map
        ? Map<String, String>.from(
            (book['formats'] as Map).map(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
            ),
          )
        : <String, String>{};
    book['download_count'] = _asInt(book['download_count']);
    book['media_type'] = book['media_type']?.toString() ?? 'text';
    return book;
  }

  List<Map<String, dynamic>> _normalizeChapters(dynamic raw) {
    final source = raw is List ? raw : const <dynamic>[];
    final chapters = <Map<String, dynamic>>[];
    for (final value in source) {
      if (value is String && value.trim().isNotEmpty) {
        chapters.add(_legacyTextChapter(value, chapters.length));
      } else if (value is Map) {
        final chapter = asStringMap(value);
        chapter['id'] =
            chapter['id']?.toString() ?? 'recovered_${chapters.length}';
        chapter['title'] =
            chapter['title']?.toString() ?? 'Chapter ${chapters.length + 1}';
        chapter['content'] = chapter['content']?.toString() ?? '';
        chapter['index'] = _asInt(chapter['index'], fallback: chapters.length);
        chapter['versions'] =
            (chapter['versions'] is List
                    ? chapter['versions'] as List
                    : const <dynamic>[])
                .whereType<Map>()
                .map(asStringMap)
                .toList(growable: false);
        chapters.add(chapter);
      }
    }
    return chapters;
  }

  Map<String, dynamic> _legacyTextChapter(String content, int index) =>
      <String, dynamic>{
        'id': 'recovered_$index',
        'title': 'Chapter ${index + 1}',
        'content': content,
        'index': index,
        'versions': const <Map<String, dynamic>>[],
        'isHidden': false,
        'revision': 0,
      };

  int _asInt(dynamic value, {int fallback = 0}) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? fallback;

  Future<void> _quarantine(String draftKey, dynamic raw, String reason) async {
    await _box.put(
      '$_quarantinePrefix${DateTime.now().millisecondsSinceEpoch}:$draftKey',
      {'draftKey': draftKey, 'reason': reason, 'raw': _hiveSafeValue(raw)},
    );
    await _box.delete(draftKey);
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
}
