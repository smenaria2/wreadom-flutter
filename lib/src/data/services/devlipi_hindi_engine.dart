import 'package:devlipi/devlipi.dart';
import '../../domain/services/hindi_transliteration_engine.dart';

/// Offline Hindi transliteration engine backed by [devlipi].
///
/// devlipi's scheme does not always map "aa" → आ-matra; this engine
/// post-processes the primary Devanagari result to synthesise long-vowel
/// variants (ा / ी / ू) for inputs that contain "aa" / "ee" / "oo".
class DevlipiHindiEngine implements HindiTransliterationEngine {
  const DevlipiHindiEngine();

  static final RegExp _romanTokenRegExp = RegExp(r"^[a-zA-Z]+[a-zA-Z'\-]*$");
  static final RegExp _devanagariRegExp = RegExp(r'[\u0900-\u097F]');
  static final RegExp _urlEmailRegExp =
      RegExp(r'(https?://|www\.|@|\.com|\.org|\.net|\.in)');

  static const String _halant = '्';      // U+094D virama
  static const String _aaMatra = 'ा';    // U+093E
  static const String _iiMatra = 'ी';    // U+0940
  static const String _uuMatra = 'ू';    // U+0942

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

    try {
      // ── 1. Primary transliteration ─────────────────────────────────────────
      final primary = Devlipi.transliterate(trimmed).trim();
      addIfNew(primary);

      // ── 2. आ-matra variant for "aa" in input ──────────────────────────────
      // devlipi often appends a halant to the last consonant (e.g. "कल्" for
      // "kaal"). We insert ā matra then strip any trailing halant so we get
      // "काल" instead of "काल्".
      if (lower.contains('aa')) {
        final aaVar = _insertLongVowelMatra(lower, primary, 'aa', _aaMatra);
        if (aaVar != null) addIfNew(_stripTrailingHalant(aaVar));
      }
      // Also add de-halanted primary so "कल्" → "कल" appears early
      addIfNew(_stripTrailingHalant(primary));

      // ── 3. ी-matra variant for "ee" in input ─────────────────────────────
      if (lower.contains('ee')) {
        final eeVar = _insertLongVowelMatra(lower, primary, 'ee', _iiMatra);
        if (eeVar != null) addIfNew(_stripTrailingHalant(eeVar));
        final eeCollapsed = Devlipi.transliterate(
            lower.replaceAll('ee', 'i')).trim();
        addIfNew(_stripTrailingHalant(eeCollapsed));
      }

      // ── 4. ू-matra variant for "oo" in input ─────────────────────────────
      if (lower.contains('oo')) {
        final ooVar = _insertLongVowelMatra(lower, primary, 'oo', _uuMatra);
        if (ooVar != null) addIfNew(_stripTrailingHalant(ooVar));
        final ooCollapsed = Devlipi.transliterate(
            lower.replaceAll('oo', 'u')).trim();
        addIfNew(_stripTrailingHalant(ooCollapsed));
      }

      // ── 5. Trailing-vowel flip (drop/add trailing 'a') ────────────────────
      final noTrailA = lower.endsWith('a')
          ? lower.substring(0, lower.length - 1)
          : '${lower}a';
      addIfNew(_stripTrailingHalant(Devlipi.transliterate(noTrailA).trim()));

      // ── 6. Nukta variants on primary ──────────────────────────────────────
      if (primary.isNotEmpty) {
        final nukta = primary
            .replaceAll('ज', 'ज़')
            .replaceAll('ख', 'ख़')
            .replaceAll('फ', 'फ़')
            .replaceAll('क', 'क़')
            .replaceAll('ग', 'ग़');
        addIfNew(nukta);
      }

      // ── 7. Matra flip on primary ending (short ↔ long) ───────────────────
      if (primary.isNotEmpty) {
        if (primary.endsWith('ी')) {
          addIfNew('${primary.substring(0, primary.length - 1)}ि');
        } else if (primary.endsWith('ि')) {
          addIfNew('${primary.substring(0, primary.length - 1)}ी');
        } else if (primary.endsWith('ू')) {
          addIfNew('${primary.substring(0, primary.length - 1)}ु');
        } else if (primary.endsWith('ु')) {
          addIfNew('${primary.substring(0, primary.length - 1)}ू');
        }
      }
    } catch (_) {}

    // ── Sort: words WITHOUT halant come first ─────────────────────────────
    suggestions.sort((a, b) {
      final aH = a.endsWith(_halant) ? 1 : 0;
      final bH = b.endsWith(_halant) ? 1 : 0;
      return aH.compareTo(bH);
    });

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
  ///
  /// Returns null if no suitable insertion point is found or if the matra
  /// is already present.
  String? _insertLongVowelMatra(
    String lowerInput,
    String primary,
    String doubleVowel,
    String matra,
  ) {
    if (primary.isEmpty) return null;

    // Find position of the first "aa/ee/oo" in input
    final aaPos = lowerInput.indexOf(doubleVowel);
    if (aaPos < 0) return null;

    // Count how many Roman consonant clusters precede the double-vowel.
    // We use a simple heuristic: count non-vowel characters before aaPos.
    const romanVowels = 'aeiou';
    int consonantsBefore = 0;
    for (int i = 0; i < aaPos; i++) {
      if (!romanVowels.contains(lowerInput[i])) consonantsBefore++;
    }

    // Now walk the Devanagari string and find the (consonantsBefore)-th
    // non-halant consonant, inserting matra right after it.
    int found = 0;
    final runes = primary.runes.toList();

    for (int i = 0; i < runes.length; i++) {
      final code = runes[i];
      final isConsonant = (code >= 0x0915 && code <= 0x0939) ||
          (code >= 0x0958 && code <= 0x095F);
      if (!isConsonant) continue;

      // Skip consonants that are part of a cluster (followed by halant)
      final nextCode = (i + 1 < runes.length) ? runes[i + 1] : 0;
      if (nextCode == 0x094D) continue; // halant → part of cluster

      found++;
      if (found < consonantsBefore + 1) continue;

      // This is our insertion consonant. Check what follows it.
      final afterCode = nextCode;

      // Already has the exact same matra → already correct, skip
      if (String.fromCharCode(afterCode) == matra) return null;

      // Build the new string

      final afterCharPos = _runeIndexToStringIndex(primary, i + 1);

      // If the character after is a different vowel sign, replace it;
      // otherwise insert.
      final isOtherMatra =
          afterCode >= 0x093E && afterCode <= 0x094F && afterCode != 0x094D;

      if (isOtherMatra) {
        // Replace existing matra with the long-vowel matra
        final nextCharPos = _runeIndexToStringIndex(primary, i + 2);
        return primary.substring(0, afterCharPos) +
            matra +
            primary.substring(nextCharPos);
      } else {
        // Insert matra after this consonant
        return primary.substring(0, afterCharPos) +
            matra +
            primary.substring(afterCharPos);
      }
    }

    // Fallback: if we couldn't map precisely, insert ā after the
    // very first non-cluster consonant in the primary string.
    return _insertMatraAfterFirstConsonant(primary, matra);
  }

  /// Converts a rune index (codepoint index) to a UTF-16 string index.
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

  /// Fallback: inserts [matra] after the first standalone consonant
  /// (not part of a halant cluster) in [devanagari].
  String? _insertMatraAfterFirstConsonant(String devanagari, String matra) {
    for (int i = 0; i < devanagari.length; i++) {
      final code = devanagari.codeUnitAt(i);
      final isConsonant = (code >= 0x0915 && code <= 0x0939) ||
          (code >= 0x0958 && code <= 0x095F);
      if (!isConsonant) continue;

      final nextCode =
          (i + 1 < devanagari.length) ? devanagari.codeUnitAt(i + 1) : 0;

      // Skip halant clusters
      if (nextCode == 0x094D) continue;

      // Already has this matra
      if (String.fromCharCode(nextCode) == matra) return null;

      // Has a different matra — replace it
      final isOtherMatra =
          nextCode >= 0x093E && nextCode <= 0x094F && nextCode != 0x094D;
      if (isOtherMatra) {
        return devanagari.substring(0, i + 1) +
            matra +
            devanagari.substring(i + 2);
      }

      // Insert
      return devanagari.substring(0, i + 1) +
          matra +
          devanagari.substring(i + 1);
    }
    return null;
  }
}
