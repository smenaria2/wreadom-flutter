import '../../domain/models/book.dart';
import 'book_author_utils.dart';

bool isBookHindi(Book book) {
  final lang = book.languages.firstOrNull?.toLowerCase().trim();
  if (lang == null) return false;
  return lang == 'hi' || lang == 'hin' || lang.contains('hindi');
}

String formatShareDescription(String? description) {
  if (description == null || description.trim().isEmpty) return '';

  // Collapse whitespace/newlines for sharing message
  var cleaned = description
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // Strip simple HTML tags if any exist (e.g., <p>, <br>, etc.)
  cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');

  if (cleaned.length > 250) {
    cleaned = '${cleaned.substring(0, 247).trim()}...';
  }

  return cleaned;
}

String getShareContentTypeLabel(String? contentType, {required bool isHindi}) {
  if (contentType == null) return isHindi ? 'कहानी' : 'story';
  final lower = contentType.trim().toLowerCase();
  if (lower == 'poem') return isHindi ? 'कविता' : 'poem';
  if (lower == 'article') return isHindi ? 'लेख' : 'article';
  return isHindi ? 'कहानी' : 'story'; // Default if null/empty or unrecognized
}
String _getFormattedAuthor(Book book, {required bool isHindi}) {
  final name = bookAuthorName(book);
  if (isHindi) {
    return name.replaceAll(' with ', ' और ');
  }
  return name;
}

String generateBookShareText({
  required Book book,
  required String link,
}) {
  final isHindi = isBookHindi(book);
  final type = getShareContentTypeLabel(book.contentType, isHindi: isHindi);
  final author = _getFormattedAuthor(book, isHindi: isHindi);
  final desc = formatShareDescription(book.description);
  final descPart = desc.isNotEmpty ? ' $desc' : '';

  if (isHindi) {
    final isArticle = book.contentType?.trim().toLowerCase() == 'article';
    final relation = isArticle ? 'का' : 'की';
    final authorPart = author.isNotEmpty ? '$author $relation ' : '';
    return 'रीडम् पर $authorPart$type "${book.title}" पढ़ें। रीडम् पर सैकड़ों कहानियाँ पढ़ें और सुनें।$descPart\n\n$link';
  }

  final authorPart = author.isNotEmpty ? ' by $author' : '';
  return 'Read $type "${book.title}"$authorPart on Wreadom. Read and listen hundred of stories on Wreadom.$descPart\n\n$link';
}

String generateChapterShareText({
  required Book book,
  required String chapterTitle,
  required String link,
}) {
  final isHindi = isBookHindi(book);
  final type = getShareContentTypeLabel(book.contentType, isHindi: isHindi);
  final author = _getFormattedAuthor(book, isHindi: isHindi);
  final desc = formatShareDescription(book.description);
  final descPart = desc.isNotEmpty ? ' $desc' : '';

  if (isHindi) {
    final isArticle = book.contentType?.trim().toLowerCase() == 'article';
    final relation = isArticle ? 'का' : 'की';
    final authorPart = author.isNotEmpty ? '$author $relation ' : '';
    return 'रीडम् पर $authorPart$type "${book.title}" का अध्याय "$chapterTitle" पढ़ें। रीडम् पर सैकड़ों कहानियाँ पढ़ें और सुनें।$descPart\n\n$link';
  }

  final authorPart = author.isNotEmpty ? ' by $author' : '';
  return 'Read "$chapterTitle" of $type "${book.title}"$authorPart on Wreadom. Read and listen hundred of stories on Wreadom.$descPart\n\n$link';
}
