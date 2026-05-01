import '../../domain/models/book.dart';

String bookAuthorName(Book book) {
  final authorNames = book.authors
      .map((author) => author.name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  if (authorNames.isEmpty) return '';
  return authorNames.join(', ');
}
