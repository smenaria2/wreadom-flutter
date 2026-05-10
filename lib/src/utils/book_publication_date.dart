import '../domain/models/book.dart';

int? publicationTimestamp(Book book) {
  return book.publishedAt ?? book.updatedAt;
}
