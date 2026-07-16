String? normalizeSelectedDictionaryWord(String selection) {
  var value = selection.trim();
  if (value.isEmpty ||
      value.runes.length > 100 ||
      RegExp(r'\s').hasMatch(value)) {
    return null;
  }
  value = value.replaceFirst(RegExp(r'''^[\s.,!?;:"“”‘’()\[\]{}<>]+'''), '');
  value = value.replaceFirst(RegExp(r'''[\s.,!?;:"“”‘’()\[\]{}<>]+$'''), '');
  if (value.isEmpty || RegExp(r'\s').hasMatch(value)) return null;
  final wordPattern = RegExp(
    r"^[\p{L}\p{M}\p{N}]+(?:['’\-][\p{L}\p{M}\p{N}]+)*$",
    unicode: true,
  );
  return wordPattern.hasMatch(value) ? value : null;
}

String normalizeDictionaryLanguageCode(Iterable<String> languages) {
  final raw = languages.isEmpty ? '' : languages.first.trim().toLowerCase();
  if (raw == 'en' || raw == 'eng' || raw.contains('english')) return 'en';
  if (raw == 'hi' || raw == 'hin' || raw.contains('hindi')) return 'hi';
  if (raw == 'ar' || raw == 'ara' || raw.contains('arabic')) return 'ar';
  if (RegExp(r'^[a-z]{2,3}$').hasMatch(raw)) return raw;
  return 'en';
}
