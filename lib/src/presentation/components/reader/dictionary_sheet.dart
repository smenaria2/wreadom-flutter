import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/dictionary_entry.dart';
import '../../providers/dictionary_providers.dart';

class DictionarySheet extends ConsumerStatefulWidget {
  const DictionarySheet({
    super.key,
    required this.word,
    required this.sourceLanguage,
  });

  final String word;
  final String sourceLanguage;

  @override
  ConsumerState<DictionarySheet> createState() => _DictionarySheetState();
}

class _DictionarySheetState extends ConsumerState<DictionarySheet> {
  late Future<DictionaryLookupResult> _lookup;

  @override
  void initState() {
    super.initState();
    _lookup = _load();
  }

  Future<DictionaryLookupResult> _load({bool forceRefresh = false}) {
    return ref
        .read(dictionaryRepositoryProvider)
        .lookup(
          word: widget.word,
          sourceLanguage: widget.sourceLanguage,
          includeTranslations: true,
          forceRefresh: forceRefresh,
        );
  }

  void _retry() => setState(() => _lookup = _load(forceRefresh: true));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.35,
      maxChildSize: 0.94,
      builder: (context, scrollController) => FutureBuilder(
        future: _lookup,
        builder: (context, snapshot) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.word,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(widget.sourceLanguage.toUpperCase()),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                _DictionaryError(error: snapshot.error, onRetry: _retry)
              else if (snapshot.data case final result?)
                _DictionaryResult(result: result),
              const SizedBox(height: 20),
              Text(
                l10n.dictionaryAttribution,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (snapshot.data case final result?)
                Wrap(
                  spacing: 12,
                  children: [
                    if (result.sourceUrl.isNotEmpty)
                      TextButton(
                        onPressed: () => launchUrl(Uri.parse(result.sourceUrl)),
                        child: const Text('Wiktionary'),
                      ),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse('https://freedictionaryapi.com/'),
                      ),
                      child: const Text('FreeDictionaryAPI.com'),
                    ),
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse(result.licenseUrl)),
                      child: Text(result.licenseName),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DictionaryResult extends ConsumerWidget {
  const _DictionaryResult({required this.result});

  final DictionaryLookupResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final target = ref.watch(dictionaryTargetLanguageProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.fromCache)
          Chip(
            avatar: const Icon(Icons.offline_pin_rounded, size: 18),
            label: Text(l10n.dictionaryCached),
          ),
        for (final entry in result.entries) ...[
          if (entry.pronunciations.isNotEmpty) Text(entry.pronunciations.first),
          const SizedBox(height: 12),
          Text(
            entry.partOfSpeech.isEmpty
                ? l10n.dictionaryMeaning
                : entry.partOfSpeech,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < entry.senses.length; index++)
            _SenseView(
              index: index + 1,
              sense: entry.senses[index],
              targetLanguage: target,
            ),
          const Divider(height: 28),
        ],
      ],
    );
  }
}

class _SenseView extends StatelessWidget {
  const _SenseView({
    required this.index,
    required this.sense,
    required this.targetLanguage,
  });

  final int index;
  final DictionarySense sense;
  final String targetLanguage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final translations = sense.translations
        .where((item) => item.languageCode == targetLanguage)
        .map((item) => item.word)
        .toSet()
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$index. ${sense.definition}'),
          if (translations.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${l10n.dictionaryTranslation}: ${translations.join(', ')}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
          if (sense.examples.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '“${sense.examples.first}”',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          if (sense.synonyms.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${l10n.dictionarySynonyms}: ${sense.synonyms.take(8).join(', ')}',
            ),
          ],
          if (sense.antonyms.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${l10n.dictionaryAntonyms}: ${sense.antonyms.take(8).join(', ')}',
            ),
          ],
        ],
      ),
    );
  }
}

class _DictionaryError extends StatelessWidget {
  const _DictionaryError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = error is DictionaryFailure
        ? (error! as DictionaryFailure).type
        : DictionaryFailureType.serviceUnavailable;
    final message = switch (type) {
      DictionaryFailureType.wordNotFound => l10n.dictionaryNotFound,
      DictionaryFailureType.rateLimited => l10n.dictionaryRateLimited,
      DictionaryFailureType.offline => l10n.dictionaryOffline,
      DictionaryFailureType.timeout => l10n.dictionaryTimeout,
      _ => l10n.dictionaryUnavailable,
    };
    return Column(
      children: [
        const Icon(Icons.menu_book_rounded, size: 44),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.tonal(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}
