import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../domain/repositories/book_repository.dart';
import '../../data/repositories/composite_book_repository.dart';
import 'auth_providers.dart';
import '../../data/services/offline_service.dart';

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return CompositeBookRepository();
});

final offlineServiceProvider = Provider<OfflineService>((ref) {
  final service = OfflineService();
  return service;
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

final bookDetailProvider = FutureProvider.family<Book?, String>((
  ref,
  bookId,
) async {
  return ref.watch(bookRepositoryProvider).getBook(bookId);
});

final booksByBookshelfProvider = FutureProvider.family<List<Book>, String>((
  ref,
  bookshelf,
) async {
  return ref.watch(bookRepositoryProvider).getBooksByBookshelf(bookshelf);
});

final userBooksProvider = FutureProvider.family<List<Book>, String>((
  ref,
  userId,
) async {
  return ref.watch(bookRepositoryProvider).getUserBooks(userId);
});

final bookSearchProvider = FutureProvider.family<List<Book>, String>((
  ref,
  query,
) async {
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
  final books = await ref.watch(bookRepositoryProvider).getBooksByIds(ids);
  final byId = <String, Book>{for (final book in books) book.id: book};
  return ids.map((id) => byId[id]).whereType<Book>().toList();
});

final downloadedBooksProvider = FutureProvider<List<Book>>((ref) async {
  return ref.watch(offlineServiceProvider).getDownloadedBooks();
});

final downloadedBookEntriesProvider = FutureProvider<List<OfflineBookEntry>>((
  ref,
) async {
  return ref.watch(offlineServiceProvider).getDownloadedBookEntries();
});

final pinnedBooksProvider = FutureProvider<List<Book>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null || user.pinnedWorks == null || user.pinnedWorks!.isEmpty) {
    return [];
  }
  return ref.watch(bookRepositoryProvider).getBooksByIds(user.pinnedWorks!);
});

final booksByGenreProvider = FutureProvider.family<List<Book>, String>((
  ref,
  genre,
) async {
  return ref.watch(bookRepositoryProvider).getBooksByGenre(genre);
});
final bookChaptersProvider = FutureProvider.family<List<Chapter>, String>((
  ref,
  bookId,
) async {
  return ref.watch(bookRepositoryProvider).getChapters(bookId);
});

final offlineChaptersProvider = FutureProvider.family<List<Chapter>, String>((
  ref,
  bookId,
) async {
  return ref.watch(offlineServiceProvider).getDownloadedChapters(bookId);
});

class BookVoteStats {
  const BookVoteStats({
    required this.upvotes,
    required this.downvotes,
    required this.recommendationCount,
  });

  final int upvotes;
  final int downvotes;
  final int recommendationCount;
}

final bookVoteStatsProvider = FutureProvider.family<BookVoteStats, String>((
  ref,
  bookId,
) async {
  final doc = await FirebaseFirestore.instance
      .collection('book_stats')
      .doc(bookId)
      .get();
  final data = doc.data() ?? const <String, dynamic>{};
  final upvotes = (data['upvotes'] as num?)?.toInt() ?? 0;
  final downvotes = (data['downvotes'] as num?)?.toInt() ?? 0;
  return BookVoteStats(
    upvotes: upvotes,
    downvotes: downvotes,
    recommendationCount:
        (data['recommendationCount'] as num?)?.toInt() ?? upvotes - downvotes,
  );
});

final userBookVoteProvider = FutureProvider.family<String?, String>((
  ref,
  bookId,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  final doc = await FirebaseFirestore.instance
      .collection('recommendations')
      .doc('${user.id}_$bookId')
      .get();
  return doc.data()?['type']?.toString();
});

final bookVoteControllerProvider = Provider<BookVoteController>((ref) {
  return BookVoteController(ref);
});

class BookVoteController {
  const BookVoteController(this._ref);

  final Ref _ref;

  Future<void> vote(String bookId, String? type) async {
    final user = await _ref.read(currentUserProvider.future);
    if (user == null) return;
    final voteRef = FirebaseFirestore.instance
        .collection('recommendations')
        .doc('${user.id}_$bookId');

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final existing = await transaction.get(voteRef);
      final currentType = existing.data()?['type']?.toString();
      if (currentType == type) return;
      if (type == null) {
        transaction.delete(voteRef);
      } else {
        transaction.set(voteRef, {
          'userId': user.id,
          'bookId': bookId,
          'type': type,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });

    _ref.invalidate(userBookVoteProvider(bookId));
    _ref.invalidate(bookVoteStatsProvider(bookId));
  }
}
