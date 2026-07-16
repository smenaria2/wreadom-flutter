import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/free_dictionary_repository.dart';
import '../../data/services/dictionary_cache_service.dart';
import '../../data/services/free_dictionary_api_client.dart';
import '../../domain/repositories/dictionary_repository.dart';
import 'locale_provider.dart';
import 'theme_provider.dart';

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

const dictionaryLanguages = <String, String>{
  'en': 'English',
  'hi': 'हिन्दी',
  'ar': 'العربية',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'pt': 'Português',
  'ru': 'Русский',
  'zh': '中文',
  'ja': '日本語',
};

const _dictionaryTargetLanguageKey = 'dictionary_target_language';

final dictionaryTargetLanguageProvider =
    NotifierProvider<DictionaryTargetLanguageController, String>(
      DictionaryTargetLanguageController.new,
    );

class DictionaryTargetLanguageController extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_dictionaryTargetLanguageKey) ??
        ref.read(localeControllerProvider).languageCode;
  }

  Future<void> setLanguage(String languageCode) async {
    state = languageCode;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_dictionaryTargetLanguageKey, languageCode);
  }
}
