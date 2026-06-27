import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/repositories/archive_book_repository.dart';
import 'package:librebook_flutter/src/data/services/archive_book_service.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/domain/models/chapter.dart';

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

    test('language parameter maps Hindi and English correctly', () {
      final queryHindi = ArchiveBookService.buildSearchQuery(
        query: 'ramayana',
        language: 'Hindi',
      );
      expect(
        queryHindi,
        contains('(language:hi OR language:hin OR language:hindi)'),
      );

      final queryEnglish = ArchiveBookService.buildSearchQuery(
        query: 'ramayana',
        language: 'en',
      );
      expect(
        queryEnglish,
        contains('(language:en OR language:eng OR language:english)'),
      );
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

    test(
      'archive chapter fetching times out instead of stalling forever',
      () async {
        final service = _FakeArchiveBookService(
          chaptersFuture: Completer<List<Chapter>>().future,
        );
        final repository = ArchiveBookRepository(
          service: service,
          chapterFetchTimeout: const Duration(milliseconds: 1),
        );

        await expectLater(
          repository.getChapters('slow-book'),
          throwsA(isA<TimeoutException>()),
        );
      },
    );

    test('archive book primary action opens Archive reader', () {
      final source = File(
        'lib/src/presentation/screens/book_detail_screen.dart',
      ).readAsStringSync();

      expect(source, contains('onTap: _isArchiveBook(book)'));
      expect(source, contains('() => _openArchivePdf(context, book)'));
      expect(
        source,
        contains('onPressed: () => _openReader(context, ref, userAsync)'),
      );
      expect(source, contains("label: const Text('Text reader')"));
    });
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
    this.chaptersFuture,
  });

  final List<Book> searchResults;
  final List<Book> idResults;
  final Future<List<Chapter>>? chaptersFuture;
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

  @override
  Future<List<Chapter>> fetchBookChapters(String identifier) async {
    final future = chaptersFuture;
    if (future == null) return super.fetchBookChapters(identifier);
    return future;
  }
}
