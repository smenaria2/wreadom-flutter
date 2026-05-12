import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/repositories/archive_book_repository.dart';
import 'package:librebook_flutter/src/data/services/archive_book_service.dart';
import 'package:librebook_flutter/src/data/utils/archive_content_safety_filter.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';

void main() {
  group('archive content safety filter', () {
    test('blocks obvious unsafe search queries', () {
      expect(isUnsafeSearchQuery('explicit archive books'), isTrue);
      expect(isUnsafeSearchQuery('xxx stories'), isTrue);
      expect(isUnsafeSearchQuery('erotic fiction'), isTrue);
    });

    test('does not match unsafe terms inside innocent words', () {
      expect(isUnsafeSearchQuery('Sussex history'), isFalse);
      expect(isUnsafeSearchQuery('Essex county archives'), isFalse);
      expect(isUnsafeSearchQuery('love story romance classics'), isFalse);
    });

    test('flags unsafe archive book metadata', () {
      expect(
        isUnsafeArchiveBook(
          _book(
            title: 'Collected Essays',
            description: 'A set of explicit stories',
          ),
        ),
        isTrue,
      );
      expect(
        isUnsafeArchiveBook(
          _book(title: 'Collected Essays', subjects: const ['Erotica']),
        ),
        isTrue,
      );
      expect(
        isUnsafeArchiveBook(
          _book(title: 'Collected Essays', bookshelves: const ['adult']),
        ),
        isTrue,
      );
      expect(
        isUnsafeArchiveBook(
          _book(title: 'Collected Essays', authors: const ['Porn Archive']),
        ),
        isTrue,
      );
      expect(
        isUnsafeArchiveBook(
          _book(title: 'Collected Essays', identifier: 'xxx-collection'),
        ),
        isTrue,
      );
    });

    test('handles empty optional metadata safely', () {
      expect(isUnsafeArchiveBook(_book(title: 'A Safe Classic')), isFalse);
      expect(
        filterSafeArchiveBooks([_book(title: 'A Safe Classic')]),
        hasLength(1),
      );
    });
  });

  group('ArchiveBookRepository safety filtering', () {
    test(
      'unsafe search query returns empty results without calling service',
      () async {
        final service = _FakeArchiveBookService(
          searchResults: [_book(title: 'Should Not Be Requested')],
        );
        final repository = ArchiveBookRepository(service: service);

        final results = await repository.searchBooks('explicit books');

        expect(results, isEmpty);
        expect(service.searchCallCount, 0);
      },
    );

    test('mixed archive search results are filtered', () async {
      final repository = ArchiveBookRepository(
        service: _FakeArchiveBookService(
          searchResults: [
            _book(title: 'A Safe Classic'),
            _book(title: 'Unsafe Metadata', subjects: const ['xxx']),
          ],
        ),
      );

      final results = await repository.searchBooks('classic');

      expect(results.map((book) => book.title), ['A Safe Classic']);
    });

    test('unsafe direct metadata lookup returns null', () async {
      final repository = ArchiveBookRepository(
        service: _FakeArchiveBookService(
          metadataBook: _book(
            title: 'Unsafe Metadata',
            description: 'explicit',
          ),
        ),
      );

      expect(await repository.getBook('unsafe'), isNull);
    });
  });
}

Book _book({
  String id = 'safe-book',
  required String title,
  String? description,
  List<String> authors = const ['Test Author'],
  List<String> subjects = const [],
  List<String> bookshelves = const [],
  String? identifier,
}) {
  return Book(
    id: id,
    identifier: identifier ?? id,
    title: title,
    description: description,
    authors: authors.map((name) => Author(name: name)).toList(),
    subjects: subjects,
    languages: const ['English'],
    formats: const {},
    downloadCount: 0,
    mediaType: 'texts',
    bookshelves: bookshelves,
    source: 'archive',
  );
}

class _FakeArchiveBookService extends ArchiveBookService {
  _FakeArchiveBookService({this.searchResults = const [], Book? metadataBook})
    : metadataBook = metadataBook ?? _book(title: 'A Safe Classic');

  final List<Book> searchResults;
  final Book metadataBook;
  int searchCallCount = 0;

  @override
  Future<Map<String, dynamic>> searchBooks({
    String? query,
    String? title,
    String? creator,
    String? identifier,
    String? language,
    String? subject,
    int page = 1,
    int rows = 20,
    String sort = 'downloads desc',
  }) async {
    searchCallCount += 1;
    return {'count': searchResults.length, 'results': searchResults};
  }

  @override
  Future<Book> getBookMetadata(String identifier) async {
    return metadataBook;
  }
}
