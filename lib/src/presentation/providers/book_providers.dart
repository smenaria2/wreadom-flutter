import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../../data/repositories/composite_book_repository.dart';
import 'auth_providers.dart';


final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return CompositeBookRepository();
});

final originalBooksProvider = FutureProvider<List<Book>>((ref) async {
  return ref.watch(bookRepositoryProvider).getOriginalBooks();
});

final popularBooksProvider = FutureProvider<List<Book>>((ref) async {
  return ref.watch(bookRepositoryProvider).getPopularBooks();
});

final recentBooksProvider = FutureProvider<List<Book>>((ref) async {
  return ref.watch(bookRepositoryProvider).getRecentBooks();
});

final bookDetailProvider = FutureProvider.family<Book?, String>((ref, bookId) async {
  return ref.watch(bookRepositoryProvider).getBook(bookId);
});

final booksByBookshelfProvider =
    FutureProvider.family<List<Book>, String>((ref, bookshelf) async {
  return ref.watch(bookRepositoryProvider).getBooksByBookshelf(bookshelf);
});

final userBooksProvider =
    FutureProvider.family<List<Book>, String>((ref, userId) async {
  return ref.watch(bookRepositoryProvider).getUserBooks(userId);
});

final bookSearchProvider =
    FutureProvider.family<List<Book>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return ref.watch(bookRepositoryProvider).searchBooks(query);
});

final readingHistoryBooksProvider = FutureProvider<List<Book>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null || user.readingHistory.isEmpty) return [];

  final ids = user.readingHistory.map((id) => id.toString()).toList();
  return ref.watch(bookRepositoryProvider).getBooksByIds(ids);
});

final savedBooksProvider = FutureProvider<List<Book>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null || user.savedBooks.isEmpty) return [];

  final ids = user.savedBooks.map((id) => id.toString()).toList();
  return ref.watch(bookRepositoryProvider).getBooksByIds(ids);
});

final pinnedBooksProvider = FutureProvider<List<Book>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null || user.pinnedWorks == null || user.pinnedWorks!.isEmpty) {
    return [];
  }
  return ref.watch(bookRepositoryProvider).getBooksByIds(user.pinnedWorks!);
});

final booksByGenreProvider =
    FutureProvider.family<List<Book>, String>((ref, genre) async {
  return ref.watch(bookRepositoryProvider).getBooksByGenre(genre);
});
