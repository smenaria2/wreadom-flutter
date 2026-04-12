import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../../data/repositories/firebase_book_repository.dart';

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return FirebaseBookRepository();
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
