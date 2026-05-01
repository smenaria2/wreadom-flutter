import '../../domain/models/book.dart';
import '../../utils/book_collaboration_utils.dart';

String bookAuthorName(Book book) {
  final collabLine = collaborativeAuthorLine(book);
  if (collabLine.trim().isNotEmpty) return collabLine;
  final authorNames = book.authors
      .map((author) => author.name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  if (authorNames.isEmpty) return '';
  return authorNames.join(', ');
}
