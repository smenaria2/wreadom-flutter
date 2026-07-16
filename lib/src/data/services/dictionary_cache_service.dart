import 'package:hive_ce/hive.dart';

class DictionaryCachedResponse {
  const DictionaryCachedResponse({
    required this.json,
    required this.fetchedAt,
    required this.isFresh,
  });

  final Map<String, dynamic> json;
  final DateTime fetchedAt;
  final bool isFresh;
}

class DictionaryCacheService {
  static const _boxName = 'dictionary_cache_v1';
  static const _maxEntries = 500;
  static const _freshFor = Duration(days: 30);

  Future<Box<dynamic>> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  Future<DictionaryCachedResponse?> get(String key) async {
    final box = await _box();
    final raw = box.get(key);
    if (raw is! Map) return null;
    final map = raw.map((key, value) => MapEntry('$key', value));
    final jsonRaw = map['json'];
    final fetchedAtMs = map['fetchedAt'] as int?;
    if (jsonRaw is! Map || fetchedAtMs == null) return null;
    final fetchedAt = DateTime.fromMillisecondsSinceEpoch(fetchedAtMs);
    await box.put(key, {
      ...map,
      'lastAccessedAt': DateTime.now().millisecondsSinceEpoch,
    });
    return DictionaryCachedResponse(
      json: jsonRaw.map((key, value) => MapEntry('$key', value)),
      fetchedAt: fetchedAt,
      isFresh: DateTime.now().difference(fetchedAt) <= _freshFor,
    );
  }

  Future<void> put(String key, Map<String, dynamic> json) async {
    final box = await _box();
    final now = DateTime.now().millisecondsSinceEpoch;
    await box.put(key, {
      'schemaVersion': 1,
      'fetchedAt': now,
      'lastAccessedAt': now,
      'json': json,
    });
    if (box.length <= _maxEntries) return;
    final records = box.keys.map((key) {
      final value = box.get(key);
      final accessed = value is Map ? value['lastAccessedAt'] as int? ?? 0 : 0;
      return (key: key, accessed: accessed);
    }).toList()..sort((a, b) => a.accessed.compareTo(b.accessed));
    await box.deleteAll(
      records.take(box.length - _maxEntries).map((e) => e.key),
    );
  }

  Future<void> clear() async => (await _box()).clear();
}
