import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_provider.dart';

enum ReaderTheme { light, sepia, dark, system }

enum ReaderFont { sans, serif }

class ReaderSettings {
  const ReaderSettings({
    required this.fontSize,
    required this.theme,
    required this.font,
  });

  final double fontSize;
  final ReaderTheme theme;
  final ReaderFont font;

  ReaderSettings copyWith({
    double? fontSize,
    ReaderTheme? theme,
    ReaderFont? font,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      font: font ?? this.font,
    );
  }
}

const _readerFontSizeKey = 'reader_font_size';
const _readerThemeIndexKey = 'reader_theme_index';
const _readerFontIndexKey = 'reader_font_index';

final readerSettingsControllerProvider =
    NotifierProvider<ReaderSettingsController, ReaderSettings>(
      ReaderSettingsController.new,
    );

class ReaderSettingsController extends Notifier<ReaderSettings> {
  @override
  ReaderSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeIndex = prefs.getInt(_readerThemeIndexKey);
    final fontIndex = prefs.getInt(_readerFontIndexKey);

    return ReaderSettings(
      fontSize: prefs.getDouble(_readerFontSizeKey) ?? 18.0,
      theme: _enumAt(ReaderTheme.values, themeIndex) ?? ReaderTheme.system,
      font: _enumAt(ReaderFont.values, fontIndex) ?? ReaderFont.serif,
    );
  }

  Future<void> setFontSize(double value) async {
    state = state.copyWith(fontSize: value);
    await ref
        .read(sharedPreferencesProvider)
        .setDouble(_readerFontSizeKey, value);
  }

  Future<void> setTheme(ReaderTheme value) async {
    state = state.copyWith(theme: value);
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_readerThemeIndexKey, value.index);
  }

  Future<void> setFont(ReaderFont value) async {
    state = state.copyWith(font: value);
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_readerFontIndexKey, value.index);
  }

  T? _enumAt<T>(List<T> values, int? index) {
    if (index == null || index < 0 || index >= values.length) return null;
    return values[index];
  }
}
