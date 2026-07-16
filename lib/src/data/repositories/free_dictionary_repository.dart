import '../../domain/models/dictionary_entry.dart';
import '../../domain/repositories/dictionary_repository.dart';
import '../services/dictionary_cache_service.dart';
import '../services/free_dictionary_api_client.dart';

class FreeDictionaryRepository implements DictionaryRepository {
  FreeDictionaryRepository({
    required FreeDictionaryApiClient apiClient,
    required DictionaryCacheService cache,
  }) : _apiClient = apiClient,
       _cache = cache;

  final FreeDictionaryApiClient _apiClient;
  final DictionaryCacheService _cache;
  final Map<String, Future<DictionaryLookupResult>> _inFlight = {};

  @override
  Future<DictionaryLookupResult> lookup({
    required String word,
    required String sourceLanguage,
    bool includeTranslations = true,
    bool forceRefresh = false,
  }) {
    final normalizedWord = word.trim().toLowerCase();
    final normalizedLanguage = sourceLanguage.trim().toLowerCase();
    final key = '$normalizedLanguage|$normalizedWord|$includeTranslations';
    return _inFlight.putIfAbsent(key, () async {
      try {
        final cached = await _cache.get(key);
        if (!forceRefresh && cached?.isFresh == true) {
          return DictionaryLookupResult.fromJson(
            cached!.json,
            fetchedAt: cached.fetchedAt,
            fromCache: true,
          );
        }
        try {
          final json = await _apiClient.lookup(
            word: normalizedWord,
            language: normalizedLanguage,
            includeTranslations: includeTranslations,
          );
          final result = DictionaryLookupResult.fromJson(json);
          await _cache.put(key, json);
          return result;
        } on DictionaryFailure catch (failure) {
          if (cached != null &&
              failure.type != DictionaryFailureType.wordNotFound &&
              failure.type != DictionaryFailureType.rateLimited) {
            return DictionaryLookupResult.fromJson(
              cached.json,
              fetchedAt: cached.fetchedAt,
              fromCache: true,
            );
          }
          rethrow;
        }
      } finally {
        _inFlight.remove(key);
      }
    });
  }
}
