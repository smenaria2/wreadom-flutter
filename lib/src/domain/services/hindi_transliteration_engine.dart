/// Interface for Hindi transliteration engines.
///
/// Converts Roman text (e.g. "Namaste") into Devanagari Hindi text suggestions (e.g. ["नमस्ते", ...]).
abstract class HindiTransliterationEngine {
  /// Transliterates a single Roman token into a list of Hindi suggestions.
  /// Returns empty list if input cannot be transliterated.
  List<String> transliterateToken(String input);
}
