import 'package:hive_ce/hive.dart';

import '../../domain/models/author.dart';
import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../utils/map_utils.dart';

class WriterDraftService {
  factory WriterDraftService() => _instance;
  WriterDraftService._();

  static final WriterDraftService _instance = WriterDraftService._();
  static const String _boxName = 'writer_drafts';
  static const int _schemaVersion = 1;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.openBox(_boxName);
    _initialized = true;
  }

  Box get _box => Hive.box(_boxName);

  Future<void> saveDraft({required String draftKey, required Book book}) async {
    await init();
    await _box.put(draftKey, {
      'schemaVersion': _schemaVersion,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
      'book': _hiveSafeValue(book),
    });
  }

  Future<Book?> getDraft(String draftKey) async {
    await init();
    final raw = _box.get(draftKey);
    if (raw == null) return null;

    final data = asStringMap(raw);
    final bookJson = asStringMap(data['book']);
    if (bookJson.isEmpty) return null;
    return Book.fromJson(bookJson);
  }

  Future<void> deleteDraft(String draftKey) async {
    await init();
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
