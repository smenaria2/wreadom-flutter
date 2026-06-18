List<String> buildProfileSearchTerms({
  required String username,
  required String email,
  String? displayName,
  String? penName,
}) {
  final terms = <String>{};
  for (final value in [username, displayName, penName, email]) {
    final normalized = normalizeProfileSearchText(value);
    if (normalized.isEmpty) continue;
    _addPrefixes(terms, normalized);
    for (final word in normalized.split(' ')) {
      _addPrefixes(terms, word);
    }
    if (normalized.contains('@')) {
      final parts = normalized.split('@');
      _addPrefixes(terms, parts.first);
      if (parts.length > 1) _addPrefixes(terms, parts.last);
    }
  }
  final sorted = terms.toList()..sort();
  return sorted.take(200).toList(growable: false);
}

String normalizeProfileSearchText(String? value) {
  return (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}@\s._-]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}

List<String> profileSearchPrefixVariants(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return const [];
  final lower = trimmed.toLowerCase();
  final title = lower
      .split(RegExp(r'\s+'))
      .map(
        (word) => word.isEmpty
            ? word
            : '${word.substring(0, 1).toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
  return <String>{trimmed, lower, title}.toList(growable: false);
}

void _addPrefixes(Set<String> terms, String value) {
  final normalized = value.trim();
  for (var length = 1; length <= normalized.length; length++) {
    terms.add(normalized.substring(0, length));
  }
}
