import '../../domain/models/book.dart';
import '../../domain/models/user_model.dart';
import '../../utils/book_collaboration_utils.dart';
import '../../utils/user_name_formatter.dart';

String bookAuthorName(Book book, {UserModel? primaryAuthor}) {
  final collabLine = collaborativeAuthorLine(book);
  if (collabLine.trim().isNotEmpty) return collabLine;
  if (primaryAuthor != null) {
    return UserNameFormatter.formatUserDisplayName(primaryAuthor, fallback: 'Author');
  }
  final authorNames = book.authors
      .map((author) => author.name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  if (authorNames.isEmpty) return '';
  return authorNames.join(', ');
}

