import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/book.dart';
import '../../domain/models/user_model.dart';
import 'profile_providers.dart';
import 'homepage_providers.dart';
import 'book_providers.dart';

class DiscoverySearchResults {
  const DiscoverySearchResults({
    required this.originals,
    required this.authors,
    required this.archiveBooks,
  });

  final List<Book> originals;
  final List<UserModel> authors;
  final List<Book> archiveBooks;

  bool get isEmpty =>
      originals.isEmpty && authors.isEmpty && archiveBooks.isEmpty;
}

final discoverySearchProvider =
    FutureProvider.family<DiscoverySearchResults, String>((ref, query) async {
      final term = query.trim();
      if (term.isEmpty) {
        return const DiscoverySearchResults(
          originals: [],
          authors: [],
          archiveBooks: [],
        );
      }
      final repo = ref.watch(bookRepositoryProvider);
      final originals = await repo
          .searchOriginalBooks(term, limit: 20)
          .catchError((_) => <Book>[]);
      final authors = await ref
          .watch(profileSearchProvider(term).future)
          .catchError((_) => <UserModel>[]);
      final archiveBooks = await repo
          .searchArchiveBooks(term, limit: 20)
          .catchError((_) => <Book>[]);

      return DiscoverySearchResults(
        originals: originals,
        authors: authors,
        archiveBooks: archiveBooks,
      );
    });

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
