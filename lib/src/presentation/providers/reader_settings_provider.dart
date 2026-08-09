import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_provider.dart';

enum ReaderTheme { light, sepia, dark, system }

enum ReaderFont {
  notoSansDevanagari,
  tiroDevanagariHindi,
  notoSerifDevanagari,
  eczar,
  martel,
  laila,
}

TextStyle readerFontTextStyle(ReaderFont font, {TextStyle? textStyle}) {
  return switch (font) {
    ReaderFont.notoSansDevanagari => GoogleFonts.notoSansDevanagari(
      textStyle: textStyle,
    ),
    ReaderFont.tiroDevanagariHindi => GoogleFonts.tiroDevanagariHindi(
      textStyle: textStyle,
    ),
    ReaderFont.notoSerifDevanagari => GoogleFonts.notoSerifDevanagari(
      textStyle: textStyle,
    ),
    ReaderFont.eczar => GoogleFonts.eczar(textStyle: textStyle),
    ReaderFont.martel => GoogleFonts.martel(textStyle: textStyle),
    ReaderFont.laila => GoogleFonts.laila(textStyle: textStyle),
  };
}

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
const readerFontFamilyPreferenceKey = 'reader_font_family';

final readerSettingsControllerProvider =
    NotifierProvider<ReaderSettingsController, ReaderSettings>(
      ReaderSettingsController.new,
    );

class ReaderSettingsController extends Notifier<ReaderSettings> {
  @override
  ReaderSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeIndex = prefs.getInt(_readerThemeIndexKey);
    final savedFont = prefs.getString(readerFontFamilyPreferenceKey);

    return ReaderSettings(
      fontSize: prefs.getDouble(_readerFontSizeKey) ?? 18.0,
      theme: _enumAt(ReaderTheme.values, themeIndex) ?? ReaderTheme.system,
      font: _readerFontFromName(savedFont),
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
        .setString(readerFontFamilyPreferenceKey, value.name);
  }

  T? _enumAt<T>(List<T> values, int? index) {
    if (index == null || index < 0 || index >= values.length) return null;
    return values[index];
  }
}

ReaderFont _readerFontFromName(String? name) {
  for (final font in ReaderFont.values) {
    if (font.name == name) return font;
  }
  return ReaderFont.tiroDevanagariHindi;
}
