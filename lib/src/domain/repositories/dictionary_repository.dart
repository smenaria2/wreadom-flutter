import '../models/dictionary_entry.dart';

abstract interface class DictionaryRepository {
  Future<DictionaryLookupResult> lookup({
    required String word,
    required String sourceLanguage,
    bool includeTranslations = true,
    bool forceRefresh = false,
  });
}
