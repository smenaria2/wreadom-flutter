import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/repositories/archive_book_repository.dart';
import 'package:librebook_flutter/src/data/services/archive_book_service.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';

void main() {
  group('ArchiveBookService search scope', () {
    test('search query is restricted to the approved collections', () {
      final query = ArchiveBookService.buildSearchQuery(query: 'ramayana');

      expect(query, contains('collection:JaiGyan'));
      expect(query, contains('collection:digitallibraryindia'));
      expect(query, contains('collection:booksbylanguage_hindi'));
      expect(query, contains('mediatype:texts'));
      expect(query, contains('title:("ramayana")'));
      expect(query, contains('creator:("ramayana")'));
      expect(query, contains('subject:("ramayana")'));
    });

    test('tag and genre searches keep the collection restriction', () {
      final query = ArchiveBookService.buildSearchQuery(subject: 'history');

      expect(query, startsWith('(collection:JaiGyan OR '));
      expect(query, contains('collection:digitallibraryindia'));
      expect(query, contains('collection:booksbylanguage_hindi'));
      expect(query, contains('mediatype:texts'));
      expect(query, contains('subject:history'));
    });

    test(
      'adult terms are not locally blocked by the archive repository',
      () async {
        final service = _FakeArchiveBookService(
          searchResults: [_book(title: 'Curated Collection Result')],
        );
        final repository = ArchiveBookRepository(service: service);

        final results = await repository.searchBooks('explicit books');

        expect(results.map((book) => book.title), [
          'Curated Collection Result',
        ]);
        expect(service.searchCallCount, 1);
        expect(service.lastQuery, 'explicit books');
      },
    );

    test(
      'curated identifier lookups return requested books directly',
      () async {
        final lookupQuery = ArchiveBookService.buildIdentifierLookupQuery([
          'outside-collection',
        ]);

        expect(lookupQuery, 'identifier:("outside-collection")');
        expect(lookupQuery, isNot(contains('collection:')));

        final service = _FakeArchiveBookService(
          idResults: [_book(id: 'outside-collection', title: 'Curated ID')],
        );
        final repository = ArchiveBookRepository(service: service);

        final results = await repository.getBooksByIds(['outside-collection']);

        expect(results.map((book) => book.id), ['outside-collection']);
      },
    );
  });
}

Book _book({String id = 'safe-book', required String title}) {
  return Book(
    id: id,
    identifier: id,
    title: title,
    authors: const [Author(name: 'Test Author')],
    subjects: const [],
    languages: const ['English'],
    formats: const {},
    downloadCount: 0,
    mediaType: 'texts',
    bookshelves: const [],
    source: 'archive',
  );
}

class _FakeArchiveBookService extends ArchiveBookService {
  _FakeArchiveBookService({
    this.searchResults = const [],
    this.idResults = const [],
  });

  final List<Book> searchResults;
  final List<Book> idResults;
  int searchCallCount = 0;
  String? lastQuery;

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
    lastQuery = query;
    return {'count': searchResults.length, 'results': searchResults};
  }

  @override
  Future<List<Book>> getBooksByIds(List<String> ids) async {
    return idResults;
  }
}
