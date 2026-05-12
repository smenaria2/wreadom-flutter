import '../../domain/models/book.dart';

final List<RegExp> _unsafePatterns = [
  _term('adult'),
  _term('explicit'),
  _term('erotic'),
  _term('erotica'),
  _term('fetish'),
  _term('hardcore'),
  _term('incest'),
  _term('nude'),
  _term('nudity'),
  _term('playboy'),
  _term('porn'),
  _term('pornography'),
  _term('sex'),
  _term('sexual'),
  _term('xxx'),
];

final List<RegExp> _unsafePhrasePatterns = [
  _phrase('adult content'),
  _phrase('adult entertainment'),
  _phrase('erotic fiction'),
  _phrase('sexual content'),
  _phrase('sex stories'),
];

RegExp _term(String term) {
  final escaped = RegExp.escape(term);
  return RegExp('(^|[^a-z0-9])$escaped([^a-z0-9]|\$)');
}

RegExp _phrase(String phrase) {
  final escaped = phrase.split(RegExp(r'\s+')).map(RegExp.escape).join(r'\s+');
  return RegExp('(^|[^a-z0-9])$escaped([^a-z0-9]|\$)');
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-./\\]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _containsUnsafeTerm(String text) {
  final normalized = _normalize(text);
  if (normalized.isEmpty) return false;
  return _unsafePatterns.any((pattern) => pattern.hasMatch(normalized)) ||
      _unsafePhrasePatterns.any((pattern) => pattern.hasMatch(normalized));
}

bool isUnsafeSearchQuery(String query) {
  return _containsUnsafeTerm(query);
}

bool isUnsafeArchiveBook(Book book) {
  final searchableText = <String>[
    book.title,
    book.description ?? '',
    book.identifier ?? '',
    book.mediaType,
    book.source ?? '',
    book.contentType ?? '',
    ...book.authors.map((author) => author.name),
    ...book.subjects,
    ...book.bookshelves,
    ...?book.topics,
  ].join(' ');

  return _containsUnsafeTerm(searchableText);
}

List<Book> filterSafeArchiveBooks(List<Book> books) {
  return books.where((book) => !isUnsafeArchiveBook(book)).toList();
}
