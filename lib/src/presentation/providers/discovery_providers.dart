import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/book.dart';
import '../../domain/models/user_model.dart';
import 'profile_providers.dart';
import 'homepage_providers.dart';
import 'book_providers.dart';
import '../utils/error_message_utils.dart';

class SearchSourceResult<T> {
  const SearchSourceResult({this.items = const [], this.error});

  final List<T> items;
  final Object? error;

  bool get failed => error != null;
}

class DiscoverySearchResults {
  const DiscoverySearchResults({
    required this.originalSource,
    required this.authorSource,
    required this.archiveSource,
  });

  final SearchSourceResult<Book> originalSource;
  final SearchSourceResult<UserModel> authorSource;
  final SearchSourceResult<Book> archiveSource;

  List<Book> get originals => originalSource.items;
  List<UserModel> get authors => authorSource.items;
  List<Book> get archiveBooks => archiveSource.items;

  bool get isEmpty =>
      originals.isEmpty && authors.isEmpty && archiveBooks.isEmpty;
  bool get allFailed =>
      originalSource.failed && authorSource.failed && archiveSource.failed;
  bool get hasPartialFailure =>
      !allFailed &&
      (originalSource.failed || authorSource.failed || archiveSource.failed);
}

final discoverySearchProvider =
    FutureProvider.family<DiscoverySearchResults, String>((ref, query) async {
      final term = query.trim();
      if (term.isEmpty) {
        return const DiscoverySearchResults(
          originalSource: SearchSourceResult(),
          authorSource: SearchSourceResult(),
          archiveSource: SearchSourceResult(),
        );
      }

      String cleanQuery = term;
      String? searchLanguage;
      if (term.contains('|lang:')) {
        final parts = term.split('|lang:');
        cleanQuery = parts[0].trim();
        if (parts.length > 1) {
          searchLanguage = parts[1].trim();
        }
      }

      final repo = ref.watch(bookRepositoryProvider);
      return collectDiscoverySearchResults(
        originals: repo.searchOriginalBooks(cleanQuery, limit: 20),
        authors: ref.watch(profileSearchProvider(cleanQuery).future),
        archiveBooks: repo.searchArchiveBooks(
          cleanQuery,
          language: searchLanguage,
          limit: 20,
        ),
      );
    });

Future<DiscoverySearchResults> collectDiscoverySearchResults({
  required Future<List<Book>> originals,
  required Future<List<UserModel>> authors,
  required Future<List<Book>> archiveBooks,
}) async {
  final originalsFuture = _captureSearchSource(
    'Original book search',
    originals,
  );
  final authorsFuture = _captureSearchSource('Author search', authors);
  final archiveFuture = _captureSearchSource(
    'Archive book search',
    archiveBooks,
  );

  return DiscoverySearchResults(
    originalSource: await originalsFuture,
    authorSource: await authorsFuture,
    archiveSource: await archiveFuture,
  );
}

Future<SearchSourceResult<T>> _captureSearchSource<T>(
  String context,
  Future<List<T>> search,
) async {
  try {
    return SearchSourceResult(items: await search);
  } catch (error, stackTrace) {
    logUiError(context, error, stackTrace);
    return SearchSourceResult(error: error);
  }
}

final discoveryDefaultBooksProvider = FutureProvider<List<Book>>((ref) async {
  final books = await ref.watch(homepageBooksProvider.future);
  return books.take(40).toList();
});

/// Provider for Internet Archive trending books shown on the Discovery screen
/// when the user hasn't searched anything yet.
final archiveTrendingProvider = FutureProvider<List<Book>>((ref) async {
  final repo = ref.watch(bookRepositoryProvider);
  // Fetch popular books from the composite repo — this includes IA books
  // when Firebase results are insufficient.
  final books = await repo.getPopularBooks(limit: 10);
  return books;
});

/// Provider for curated genre collections from the composite repository
final archiveGenrePreviewProvider = FutureProvider.family<List<Book>, String>((
  ref,
  genre,
) async {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getBooksByGenre(genre, limit: 6);
});
