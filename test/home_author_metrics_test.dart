import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/presentation/providers/homepage_providers.dart';

void main() {
  Book book({
    required String id,
    required String authorId,
    required int views,
    String status = 'published',
    String? collaborationStatus,
    String? collaboratorId,
    List<String>? authorIds,
    bool isOriginal = true,
  }) {
    return Book(
      id: id,
      title: id,
      authors: const [Author(name: 'Author')],
      subjects: const [],
      languages: const ['en'],
      formats: const {},
      downloadCount: 0,
      mediaType: 'text',
      bookshelves: const [],
      authorId: authorId,
      isOriginal: isOriginal,
      status: status,
      viewCount: views,
      collaborationStatus: collaborationStatus,
      collaboratorId: collaboratorId,
      authorIds: authorIds,
    );
  }

  test('author metrics credit only published primary and accepted authors', () {
    final primary = book(id: 'primary', authorId: 'author-a', views: 5);
    final accepted = book(
      id: 'accepted',
      authorId: 'author-a',
      views: 7,
      collaborationStatus: 'accepted',
      collaboratorId: 'author-b',
      authorIds: const ['author-a', 'author-b'],
    );
    final pending = book(
      id: 'pending',
      authorId: 'author-a',
      views: 11,
      collaborationStatus: 'pending',
      collaboratorId: 'author-b',
      authorIds: const ['author-a', 'author-b'],
    );
    final unpublished = book(
      id: 'draft',
      authorId: 'author-a',
      views: 13,
      status: 'draft',
      collaborationStatus: 'accepted',
      collaboratorId: 'author-b',
      authorIds: const ['author-a', 'author-b'],
    );
    final archiveLike = book(
      id: 'not-original',
      authorId: 'author-a',
      views: 17,
      isOriginal: false,
    );
    final books = [
      primary,
      accepted,
      accepted,
      pending,
      unpublished,
      archiveLike,
    ];

    final primaryMetrics = homeAuthorMetricsFor('author-a', books);
    final collaboratorMetrics = homeAuthorMetricsFor('author-b', books);

    expect(primaryMetrics.works, 3);
    expect(primaryMetrics.reads, 23);
    expect(collaboratorMetrics.works, 1);
    expect(collaboratorMetrics.reads, 7);
  });
}
