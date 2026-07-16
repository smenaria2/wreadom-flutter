enum DictionaryFailureType {
  wordNotFound,
  rateLimited,
  offline,
  timeout,
  invalidResponse,
  serviceUnavailable,
}

class DictionaryFailure implements Exception {
  const DictionaryFailure(this.type, [this.message]);

  final DictionaryFailureType type;
  final String? message;

  @override
  String toString() => message ?? type.name;
}

class DictionaryLookupResult {
  const DictionaryLookupResult({
    required this.word,
    required this.entries,
    required this.sourceUrl,
    required this.licenseName,
    required this.licenseUrl,
    required this.fetchedAt,
    this.fromCache = false,
  });

  final String word;
  final List<DictionaryEntry> entries;
  final String sourceUrl;
  final String licenseName;
  final String licenseUrl;
  final DateTime fetchedAt;
  final bool fromCache;

  DictionaryLookupResult copyWith({bool? fromCache}) => DictionaryLookupResult(
    word: word,
    entries: entries,
    sourceUrl: sourceUrl,
    licenseName: licenseName,
    licenseUrl: licenseUrl,
    fetchedAt: fetchedAt,
    fromCache: fromCache ?? this.fromCache,
  );

  factory DictionaryLookupResult.fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
    bool fromCache = false,
  }) {
    final source = _map(json['source']);
    final license = _map(source['license']);
    final entries = _list(json['entries'])
        .map(_map)
        .map(DictionaryEntry.fromJson)
        .where((entry) => entry.senses.isNotEmpty)
        .toList(growable: false);
    if ((json['word']?.toString() ?? '').isEmpty) {
      throw const DictionaryFailure(DictionaryFailureType.invalidResponse);
    }
    if (entries.isEmpty) {
      throw const DictionaryFailure(DictionaryFailureType.wordNotFound);
    }
    return DictionaryLookupResult(
      word: json['word'].toString(),
      entries: entries,
      sourceUrl: source['url']?.toString() ?? '',
      licenseName: license['name']?.toString() ?? 'CC BY-SA 4.0',
      licenseUrl:
          license['url']?.toString() ??
          'https://creativecommons.org/licenses/by-sa/4.0/',
      fetchedAt: fetchedAt ?? DateTime.now(),
      fromCache: fromCache,
    );
  }
}

class DictionaryEntry {
  const DictionaryEntry({
    required this.languageCode,
    required this.languageName,
    required this.partOfSpeech,
    required this.pronunciations,
    required this.senses,
    required this.synonyms,
    required this.antonyms,
  });

  final String languageCode;
  final String languageName;
  final String partOfSpeech;
  final List<String> pronunciations;
  final List<DictionarySense> senses;
  final List<String> synonyms;
  final List<String> antonyms;

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    final language = _map(json['language']);
    return DictionaryEntry(
      languageCode: language['code']?.toString() ?? '',
      languageName: language['name']?.toString() ?? '',
      partOfSpeech: json['partOfSpeech']?.toString() ?? '',
      pronunciations: _list(json['pronunciations'])
          .map(_map)
          .map((value) => value['text']?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      senses: _list(json['senses'])
          .map(_map)
          .map(DictionarySense.fromJson)
          .where((sense) => sense.definition.isNotEmpty)
          .toList(growable: false),
      synonyms: _strings(json['synonyms']),
      antonyms: _strings(json['antonyms']),
    );
  }
}

class DictionarySense {
  const DictionarySense({
    required this.definition,
    required this.tags,
    required this.examples,
    required this.synonyms,
    required this.antonyms,
    required this.translations,
    required this.subsenses,
  });

  final String definition;
  final List<String> tags;
  final List<String> examples;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<DictionaryTranslation> translations;
  final List<DictionarySense> subsenses;

  factory DictionarySense.fromJson(Map<String, dynamic> json) =>
      DictionarySense(
        definition: json['definition']?.toString() ?? '',
        tags: _strings(json['tags']),
        examples: _strings(json['examples']),
        synonyms: _strings(json['synonyms']),
        antonyms: _strings(json['antonyms']),
        translations: _list(json['translations'])
            .map(_map)
            .map(DictionaryTranslation.fromJson)
            .where((translation) => translation.word.isNotEmpty)
            .toList(growable: false),
        subsenses: _list(json['subsenses'])
            .map(_map)
            .map(DictionarySense.fromJson)
            .where((sense) => sense.definition.isNotEmpty)
            .toList(growable: false),
      );
}

class DictionaryTranslation {
  const DictionaryTranslation({
    required this.languageCode,
    required this.languageName,
    required this.word,
  });

  final String languageCode;
  final String languageName;
  final String word;

  factory DictionaryTranslation.fromJson(Map<String, dynamic> json) {
    final language = _map(json['language']);
    return DictionaryTranslation(
      languageCode: language['code']?.toString() ?? '',
      languageName: language['name']?.toString() ?? '',
      word: json['word']?.toString() ?? '',
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return const {};
}

List<dynamic> _list(Object? value) => value is List ? value : const [];

List<String> _strings(Object? value) => _list(value)
    .map((item) => item.toString())
    .where((item) => item.isNotEmpty)
    .toList(growable: false);
