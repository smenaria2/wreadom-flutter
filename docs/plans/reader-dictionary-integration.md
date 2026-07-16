# Reader Dictionary Integration Plan

## Outcome

Add a **Define** action to the existing reader text-selection toolbar. Selecting a word opens a reader-themed bottom sheet backed by FreeDictionaryAPI.com, showing definitions, parts of speech, examples, pronunciation text, synonyms/antonyms, and sense-specific translations when available. Previously fetched entries remain usable offline through a bounded local cache.

API documentation: <https://freedictionaryapi.com/>  
Endpoint: `GET https://freedictionaryapi.com/api/v1/entries/{language}/{word}?translations=true`

## Scope decisions

- MVP supports a single selected word (including Unicode letters, apostrophes, and hyphens). Multi-word selections keep the existing reader actions but disable or omit **Define**.
- The source language comes from `Book.languages`, normalized to an ISO 639-1/639-3 code. If the value is missing or unusable, fall back to `en` and visibly label that assumption.
- The target translation language is a separate reader preference, initially defaulting to the app locale. It must not be coupled permanently to the UI locale.
- The API's `translations` values are dictionary translations associated with a specific sense. Definitions may still be English because the data is extracted from English Wiktionary.
- No API key or backend proxy is required for MVP. Calls go directly from Flutter with a short timeout and a descriptive User-Agent where supported.
- Integrate first into the text reader in `reader_screen.dart`. `archive_reader_screen.dart` is deferred until it exposes reliable selected text.
- Do not persist lookup history or analytics in MVP. Cache only successful dictionary responses.

## Architecture

### Domain layer

Create `lib/src/domain/models/dictionary_entry.dart` with immutable, hand-written models:

- `DictionaryLookupResult`
  - `word`
  - `entries`
  - `sourceUrl`
  - `licenseName`
  - `licenseUrl`
  - `fetchedAt`
  - `fromCache`
- `DictionaryEntry`
  - `languageCode`
  - `languageName`
  - `partOfSpeech`
  - `pronunciations`
  - `forms`
  - `senses`
  - entry-level synonyms/antonyms
- `DictionarySense`
  - definition, tags, examples, synonyms, antonyms, translations, subsenses
- `DictionaryTranslation`
  - language code/name and translated word
- typed failures: `wordNotFound`, `rateLimited`, `offline`, `timeout`, `invalidResponse`, `serviceUnavailable`

Parsing must tolerate missing optional arrays, unknown pronunciation types, unknown fields, and malformed individual entries without losing the entire response.

Create `lib/src/domain/repositories/dictionary_repository.dart`:

```dart
abstract interface class DictionaryRepository {
  Future<DictionaryLookupResult> lookup({
    required String word,
    required String sourceLanguage,
    bool includeTranslations = true,
    bool forceRefresh = false,
  });
}
```

### Data layer

Create `lib/src/data/services/free_dictionary_api_client.dart`:

- Inject `http.Client` for tests.
- Build URLs with `Uri.https` and percent-encode the selected word.
- Apply an 8-second timeout.
- Map `404`, `429`, 5xx, timeout, socket/network, and invalid JSON into typed failures.
- Never log full response bodies or selected reading text.
- Parse `source.url` and license metadata for attribution.

Create `lib/src/data/services/dictionary_cache_service.dart` using a dedicated Hive box such as `dictionary_cache_v1`:

- Key: normalized `sourceLanguage|word|translations`.
- Value: schema version, fetched timestamp, last-access timestamp, and raw validated JSON.
- Cache successful `200` responses only.
- Fresh TTL: 30 days; stale results may be shown when a network refresh fails.
- Bound cache to 500 entries and evict least-recently-used records after writes.
- Expose `clear()` for a future settings control; no UI is required in MVP.

Create `lib/src/data/repositories/free_dictionary_repository.dart`:

1. Normalize the lookup key.
2. Return a fresh cache hit immediately.
3. Otherwise request the API and update the cache.
4. On a network/service failure, return a stale cache hit with `fromCache: true`.
5. Preserve `not found` and `rate limited` as distinct user-facing states.

### Presentation layer

Create `lib/src/presentation/providers/dictionary_providers.dart`:

- `dictionaryApiClientProvider`
- `dictionaryCacheServiceProvider`
- `dictionaryRepositoryProvider`
- a parameterized async lookup provider/controller keyed by normalized word and language
- `dictionaryTargetLanguageProvider`, persisted in `SharedPreferences`

Create `lib/src/presentation/components/reader/dictionary_sheet.dart`:

- Draggable, scrollable bottom sheet that follows the current reader theme.
- Header: selected word, source language, and optional pronunciation text.
- Group results by part of speech.
- Render definitions and a limited number of examples initially; allow expansion for long entries.
- Show translations matching the preferred target language first, grouped under the correct sense.
- Render synonyms and antonyms as wrapping chips only when present.
- Provide loading skeleton, retry, not-found, offline-without-cache, rate-limit, and generic service-error states.
- Show a small **Cached** indicator for stale/offline results.
- Always show clickable attribution: original Wiktionary source, FreeDictionaryAPI.com, and CC BY-SA 4.0 license.
- Do not add audio playback in MVP because this API documents pronunciation text, not guaranteed audio URLs.

Add localized strings to `lib/l10n/app_en.arb` and `lib/l10n/app_hi.arb`, then regenerate localization files. Include Define, Dictionary, target language, retry, no definition, offline, rate limited, cached, attribution, examples, synonyms, antonyms, and translations.

## Reader integration

Modify the existing `SelectionArea.contextMenuBuilder` in `lib/src/presentation/screens/reader_screen.dart`:

1. Normalize `_selectedText` by trimming surrounding whitespace and punctuation while retaining internal apostrophes/hyphens.
2. Validate that it is one dictionary token and impose a conservative maximum length (for example 100 Unicode scalar values, matching the API's word-oriented contract).
3. Insert **Define** as the first custom toolbar action when valid.
4. On tap, hide the selection toolbar before opening the sheet.
5. Pass the normalized selected word, the normalized book language, and the preferred target translation language.
6. Keep Share Quote, Quote & Comment, and Read aloud unchanged.
7. Guard `setState`/navigation interactions with `mounted` after asynchronous work.

Extract reusable helpers into `lib/src/presentation/utils/dictionary_lookup_utils.dart`:

- `normalizeSelectedDictionaryWord`
- `normalizeDictionaryLanguageCode`
- `isDictionaryLookupSelection`
- translation filtering by target language

Book-language normalization should cover at least current known forms:

- `en`, `eng`, `english` -> `en`
- `hi`, `hin`, `hindi` -> `hi`
- `ar`, `ara`, `arabic` -> `ar`
- valid two- or three-letter codes pass through in lowercase
- unknown/missing values -> `en`

## Settings

Extend the reader settings UI (or add a dictionary subsection adjacent to language settings) with:

- **Dictionary translation language**
- Default: current app locale on first use
- Initial selectable languages: languages returned by the API's `/languages` endpoint, cached locally; provide a static safe fallback list when that request fails
- Option: **Same as app language**

Do not change the application locale when this preference changes.

## Legal and product requirements

The API documents a limit of 1,000 requests per hour per IP and returns `429` when exceeded. Local caching and disabling duplicate in-flight requests are required.

The data is CC BY-SA 4.0. Before release:

- Show a link to `source.url` in every result sheet.
- Show visible attribution to FreeDictionaryAPI.com in the result sheet.
- Add attribution and the CC BY-SA license link to the app's legal/open-source notices.
- Add the required attribution to the app-store/distribution landing page.
- Preserve attribution if cached dictionary content is displayed offline.

## Delivery sequence

### Milestone 1 — API contract and domain parsing

Files:

- `lib/src/domain/models/dictionary_entry.dart`
- `lib/src/domain/repositories/dictionary_repository.dart`
- `lib/src/data/services/free_dictionary_api_client.dart`
- `test/free_dictionary_api_client_test.dart`
- `test/dictionary_entry_test.dart`

Verification:

- Parse representative noun/verb entries, nested subsenses, absent translations, Unicode words, and attribution.
- Assert typed handling for 404, 429, 500, timeout, invalid JSON, and partially malformed data.

### Milestone 2 — Cache and repository behavior

Files:

- `lib/src/data/services/dictionary_cache_service.dart`
- `lib/src/data/repositories/free_dictionary_repository.dart`
- `test/dictionary_cache_service_test.dart`
- `test/free_dictionary_repository_test.dart`

Verification:

- Fresh hit avoids HTTP.
- Expired entry refreshes.
- Network failure returns stale cached data.
- Failed/not-found results are not cached.
- Cache never exceeds 500 entries and eviction is deterministic.
- Concurrent identical lookups share one in-flight request.

### Milestone 3 — Providers, preferences, and dictionary sheet

Files:

- `lib/src/presentation/providers/dictionary_providers.dart`
- `lib/src/presentation/components/reader/dictionary_sheet.dart`
- reader/dictionary settings UI
- localization ARB files
- widget/provider tests

Verification:

- Loading, success, empty, retry, offline cache, 404, and 429 states render correctly.
- Translation ordering follows the target language.
- Long definitions scroll without overflow at large text scale.
- Light, sepia, dark, and system reader themes remain legible.
- Attribution is visible and links are actionable.

### Milestone 4 — Reader selection integration

Files:

- `lib/src/presentation/screens/reader_screen.dart`
- `lib/src/presentation/utils/dictionary_lookup_utils.dart`
- reader integration/widget tests

Verification:

- A selected single English, Hindi, or Arabic word exposes **Define**.
- Surrounding punctuation is removed correctly.
- Apostrophized and hyphenated words remain intact.
- Multi-word quotes do not expose **Define**.
- Existing Share Quote, Quote & Comment, and Read aloud actions still work.
- TTS mode continues to disable selection exactly as before.
- Rapid repeated taps open one sheet and issue one lookup.

### Milestone 5 — Release hardening

- Add legal and distribution attribution.
- Run `dart format` outside the sandbox.
- Run targeted tests, then the full `flutter test` suite outside the sandbox.
- Run `flutter analyze` outside the sandbox.
- Manually test Android, iOS, and Flutter Web with online, airplane-mode cached, airplane-mode uncached, 404, and forced 429 cases.
- Confirm CORS behavior on the deployed web origin.
- Confirm cache size and startup time on a low-memory device.

## Acceptance criteria

- Selecting a supported single word in the text reader presents a localized **Define** action.
- The sheet displays structured definitions without leaving the reader.
- Sense-specific translations for the chosen target language are shown when returned by the API.
- Cached results open without network access; an uncached offline lookup gives a clear recoverable state.
- API failures never crash or block the reader.
- Duplicate requests and cache growth are bounded.
- Required Wiktionary, FreeDictionaryAPI.com, and CC BY-SA attribution is visible and retained offline.
- Existing selection actions, chapter navigation, TTS, reader themes, and progress saving do not regress.

## Deferred follow-ups

- Context-aware selection of the correct sense using the surrounding sentence.
- Sentence translation through a separate translation provider.
- Pronunciation audio through another provider or platform TTS.
- Saved vocabulary, lookup history, flashcards, and cross-device sync.
- Dictionary actions in `archive_reader_screen.dart` after selected-text extraction is available.
- Optional backend proxy if abuse, service reliability, observability, or provider switching requires it.

