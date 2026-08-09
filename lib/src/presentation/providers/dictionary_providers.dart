import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/free_dictionary_repository.dart';
import '../../data/services/dictionary_cache_service.dart';
import '../../data/services/free_dictionary_api_client.dart';
import '../../domain/repositories/dictionary_repository.dart';

final dictionaryApiClientProvider = Provider<FreeDictionaryApiClient>((ref) {
  final client = FreeDictionaryApiClient();
  ref.onDispose(client.close);
  return client;
});

final dictionaryCacheServiceProvider = Provider<DictionaryCacheService>((ref) {
  return DictionaryCacheService();
});

final dictionaryRepositoryProvider = Provider<DictionaryRepository>((ref) {
  return FreeDictionaryRepository(
    apiClient: ref.watch(dictionaryApiClientProvider),
    cache: ref.watch(dictionaryCacheServiceProvider),
  );
});
