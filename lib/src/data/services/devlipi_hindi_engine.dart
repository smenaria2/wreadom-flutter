import 'package:devlipi/devlipi.dart';
import '../../domain/services/hindi_transliteration_engine.dart';
import 'generated_hindi_dictionary.dart';

/// Offline Hindi transliteration engine backed by Dakshina dictionary lookup
/// with [devlipi] fallback.
class DevlipiHindiEngine implements HindiTransliterationEngine {
  const DevlipiHindiEngine();

  static final RegExp _romanTokenRegExp = RegExp(r"^[a-zA-Z]+[a-zA-Z'\-]*$");
  static final RegExp _devanagariRegExp = RegExp(r'[\u0900-\u097F]');
  static final RegExp _urlEmailRegExp =
      RegExp(r'(https?://|www\.|@|\.com|\.org|\.net|\.in)');

  static const String _aaMatra = 'ा'; // U+093E
  static const String _iiMatra = 'ी'; // U+0940
  static const String _uuMatra = 'ू'; // U+0942

  @override
  List<String> transliterateToken(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const [];
    if (_urlEmailRegExp.hasMatch(trimmed)) return const [];
    if (_devanagariRegExp.hasMatch(trimmed)) return const [];
    if (!_romanTokenRegExp.hasMatch(trimmed)) return const [];

    final lower = trimmed.toLowerCase();
    final seen = <String>{};
    final suggestions = <String>[];

    void addIfNew(String s) {
      final t = s.trim();
      if (t.isNotEmpty && seen.add(t)) suggestions.add(t);
    }

    // ── 1. Query checked-in Dakshina dictionary first ───────────────────────
    final dictMatches = kHindiDictionary[lower];
    if (dictMatches != null) {
      for (final candidate in dictMatches) {
        addIfNew(candidate);
      }
    }

    // ── 2. Fall back to devlipi when < 4 dictionary candidates exist ─────────
    if (suggestions.length < 4) {
      try {
        final primary = Devlipi.transliterate(trimmed).trim();
        addIfNew(primary);

        if (lower.contains('aa')) {
          final aaVar = _insertLongVowelMatra(lower, primary, 'aa', _aaMatra);
          if (aaVar != null) addIfNew(_stripTrailingHalant(aaVar));
        }
        addIfNew(_stripTrailingHalant(primary));

        if (lower.contains('ee')) {
          final eeVar = _insertLongVowelMatra(lower, primary, 'ee', _iiMatra);
          if (eeVar != null) addIfNew(_stripTrailingHalant(eeVar));
          final eeCollapsed =
              Devlipi.transliterate(lower.replaceAll('ee', 'i')).trim();
          addIfNew(_stripTrailingHalant(eeCollapsed));
        }

        if (lower.contains('oo')) {
          final ooVar = _insertLongVowelMatra(lower, primary, 'oo', _uuMatra);
          if (ooVar != null) addIfNew(_stripTrailingHalant(ooVar));
          final ooCollapsed =
              Devlipi.transliterate(lower.replaceAll('oo', 'u')).trim();
          addIfNew(_stripTrailingHalant(ooCollapsed));
        }
      } catch (_) {}
    }

    return suggestions.take(4).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Removes a trailing halant (् U+094D) from a Devanagari string.
  /// e.g. "काल्" → "काल", "कल्" → "कल".
  String _stripTrailingHalant(String s) {
    const halantChar = '्'; // U+094D
    return s.endsWith(halantChar)
        ? s.substring(0, s.length - halantChar.length)
        : s;
  }

  /// Locates which consonant in [primary] (Devanagari) corresponds to the
  /// Roman consonant immediately before the [doubleVowel] ("aa"/"ee"/"oo")
  /// in [lowerInput], then returns a new string with [matra] inserted after
  /// that consonant (replacing any existing vowel mark there).
  String? _insertLongVowelMatra(
    String lowerInput,
    String primary,
    String doubleVowel,
    String matra,
  ) {
    if (primary.isEmpty) return null;

    final aaPos = lowerInput.indexOf(doubleVowel);
    if (aaPos < 0) return null;

    const romanVowels = 'aeiou';
    int consonantsBefore = 0;
    for (int i = 0; i < aaPos; i++) {
      if (!romanVowels.contains(lowerInput[i])) consonantsBefore++;
    }

    int found = 0;
    final runes = primary.runes.toList();

    for (int i = 0; i < runes.length; i++) {
      final code = runes[i];
      final isConsonant = (code >= 0x0915 && code <= 0x0939) ||
          (code >= 0x0958 && code <= 0x095F);
      if (!isConsonant) continue;

      final nextCode = (i + 1 < runes.length) ? runes[i + 1] : 0;
      if (nextCode == 0x094D) continue; // halant → part of cluster

      found++;
      if (found < consonantsBefore + 1) continue;

      final afterCode = nextCode;
      if (String.fromCharCode(afterCode) == matra) return null;

      final afterCharPos = _runeIndexToStringIndex(primary, i + 1);

      final isOtherMatra =
          afterCode >= 0x093E && afterCode <= 0x094F && afterCode != 0x094D;

      if (isOtherMatra) {
        final nextCharPos = _runeIndexToStringIndex(primary, i + 2);
        return primary.substring(0, afterCharPos) +
            matra +
            primary.substring(nextCharPos);
      } else {
        return primary.substring(0, afterCharPos) +
            matra +
            primary.substring(afterCharPos);
      }
    }

    return _insertMatraAfterFirstConsonant(primary, matra);
  }

  int _runeIndexToStringIndex(String s, int runeIndex) {
    int idx = 0;
    int ri = 0;
    for (final _ in s.runes) {
      if (ri >= runeIndex) break;
      idx += String.fromCharCode(s.runes.elementAt(ri)).length;
      ri++;
    }
    return idx;
  }

  String? _insertMatraAfterFirstConsonant(String devanagari, String matra) {
    for (int i = 0; i < devanagari.length; i++) {
      final code = devanagari.codeUnitAt(i);
      final isConsonant = (code >= 0x0915 && code <= 0x0939) ||
          (code >= 0x0958 && code <= 0x095F);
      if (!isConsonant) continue;

      final nextCode =
          (i + 1 < devanagari.length) ? devanagari.codeUnitAt(i + 1) : 0;

      if (nextCode == 0x094D) continue;

      if (String.fromCharCode(nextCode) == matra) return null;

      final isOtherMatra =
          nextCode >= 0x093E && nextCode <= 0x094F && nextCode != 0x094D;
      if (isOtherMatra) {
        return devanagari.substring(0, i + 1) +
            matra +
            devanagari.substring(i + 2);
      }

      return devanagari.substring(0, i + 1) +
          matra +
          devanagari.substring(i + 1);
    }
    return null;
  }
}
