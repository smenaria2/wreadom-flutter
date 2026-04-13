import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/book.dart';
import 'book_providers.dart';

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
final archiveGenrePreviewProvider =
    FutureProvider.family<List<Book>, String>((ref, genre) async {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getBooksByGenre(genre, limit: 6);
});
