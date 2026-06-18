import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/repositories/firebase_book_repository.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';
import 'package:librebook_flutter/src/presentation/providers/discovery_providers.dart';

void main() {
  test('discovery reports complete empty success as no results', () async {
    final results = await collectDiscoverySearchResults(
      originals: Future.value(const []),
      authors: Future.value(const []),
      archiveBooks: Future.value(const []),
    );

    expect(results.isEmpty, isTrue);
    expect(results.allFailed, isFalse);
    expect(results.hasPartialFailure, isFalse);
  });

  test(
    'discovery preserves successful results when one source fails',
    () async {
      final results = await collectDiscoverySearchResults(
        originals: Future.value([_book('original')]),
        authors: Future<List<UserModel>>.error(StateError('profiles offline')),
        archiveBooks: Future.value([_book('archive')]),
      );

      expect(results.originals.map((book) => book.id), ['original']);
      expect(results.archiveBooks.map((book) => book.id), ['archive']);
      expect(results.authors, isEmpty);
      expect(results.hasPartialFailure, isTrue);
      expect(results.allFailed, isFalse);
    },
  );

  test(
    'discovery reports a full failure only when every source fails',
    () async {
      final results = await collectDiscoverySearchResults(
        originals: Future<List<Book>>.error(StateError('originals offline')),
        authors: Future<List<UserModel>>.error(StateError('profiles offline')),
        archiveBooks: Future<List<Book>>.error(StateError('archive offline')),
      );

      expect(results.isEmpty, isTrue);
      expect(results.allFailed, isTrue);
      expect(results.hasPartialFailure, isFalse);
    },
  );

  test(
    'Firebase title search creates raw, lowercase and title-case variants',
    () {
      expect(firebaseTitlePrefixVariants('  the GREAT tale  '), [
        'the GREAT tale',
        'the great tale',
        'The Great Tale',
      ]);
      expect(firebaseTitlePrefixVariants('Poetry'), ['Poetry', 'poetry']);
    },
  );
}

Book _book(String id) {
  return Book(
    id: id,
    title: id,
    authors: const [],
    subjects: const [],
    languages: const [],
    formats: const {},
    downloadCount: 0,
    mediaType: 'texts',
    bookshelves: const [],
  );
}
