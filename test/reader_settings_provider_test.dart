import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/providers/reader_settings_provider.dart';
import 'package:librebook_flutter/src/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _containerWithPreferences(
  Map<String, Object> values,
) async {
  SharedPreferences.setMockInitialValues(values);
  final preferences = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reader font defaults to Tiro when no preference is stored', () async {
    final container = await _containerWithPreferences({});
    addTearDown(container.dispose);

    expect(
      container.read(readerSettingsControllerProvider).font,
      ReaderFont.tiroDevanagariHindi,
    );
  });

  test('reader font restores from its stable enum name', () async {
    final container = await _containerWithPreferences({
      readerFontFamilyPreferenceKey: ReaderFont.eczar.name,
    });
    addTearDown(container.dispose);

    expect(
      container.read(readerSettingsControllerProvider).font,
      ReaderFont.eczar,
    );
  });

  test('invalid reader font preference falls back to Tiro', () async {
    final container = await _containerWithPreferences({
      readerFontFamilyPreferenceKey: 'removed-font',
    });
    addTearDown(container.dispose);

    expect(
      container.read(readerSettingsControllerProvider).font,
      ReaderFont.tiroDevanagariHindi,
    );
  });

  test('setting a reader font updates state and persists its name', () async {
    final container = await _containerWithPreferences({});
    addTearDown(container.dispose);

    await container
        .read(readerSettingsControllerProvider.notifier)
        .setFont(ReaderFont.martel);

    expect(
      container.read(readerSettingsControllerProvider).font,
      ReaderFont.martel,
    );
    expect(
      container
          .read(sharedPreferencesProvider)
          .getString(readerFontFamilyPreferenceKey),
      ReaderFont.martel.name,
    );
  });

  test('all reader fonts map to distinct Google Fonts families', () {
    final families = ReaderFont.values
        .map((font) => readerFontTextStyle(font).fontFamily)
        .toSet();

    expect(ReaderFont.values, hasLength(6));
    expect(families, hasLength(6));
    expect(families, isNot(contains(null)));
  });

  test('reader UI uses font previews and styles every reading path', () {
    final readerSource = File(
      'lib/src/presentation/screens/reader_screen.dart',
    ).readAsStringSync();

    expect(readerSource, contains("ValueKey('reader-font-\${font.name}')"));
    expect(
      readerSource,
      contains("'कहानियाँ हमें नई दुनिया में ले जाती हैं।'"),
    );
    expect(readerSource, contains('readerFontTextStyle('));
    expect(
      readerSource,
      contains('textStyle: Theme.of(context).textTheme.headlineSmall'),
    );
    expect(readerSource, contains('HtmlWidget('));
    expect(readerSource, contains('font: _readerFont'));
    expect(readerSource, contains('setState(() => _readerFont = font)'));
    expect(readerSource, contains('.setFont(font)'));
    expect(readerSource, isNot(contains('dictionaryTranslationLanguage')));
    expect(readerSource, isNot(contains('dictionaryTargetLanguageProvider')));
  });

  test('dictionary translation filtering follows the application locale', () {
    final sheetSource = File(
      'lib/src/presentation/components/reader/dictionary_sheet.dart',
    ).readAsStringSync();
    final providersSource = File(
      'lib/src/presentation/providers/dictionary_providers.dart',
    ).readAsStringSync();

    expect(
      sheetSource,
      contains('ref.watch(localeControllerProvider).languageCode'),
    );
    expect(sheetSource, contains('item.languageCode == targetLanguage'));
    expect(
      providersSource,
      isNot(contains('dictionaryTargetLanguageProvider')),
    );
    expect(providersSource, isNot(contains('dictionary_target_language')));
  });
}
