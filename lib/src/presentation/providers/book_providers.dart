import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/homepage/compiled_homepage.dart';
import '../../domain/models/leaf_attachment.dart';
import '../../domain/repositories/book_repository.dart';
import '../../data/repositories/composite_book_repository.dart';
import '../../data/utils/firestore_utils.dart';
import '../../data/utils/firestore_cache_first.dart';
import '../../utils/map_utils.dart';
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

const _leafShelfCandidateLimit = 80;
const _leafShelfDisplayLimit = 24;

final rawBooksWithLeavesProvider = FutureProvider<List<Book>>((ref) async {
  return ref
      .watch(bookRepositoryProvider)
      .getBooksWithLeaves(limit: _leafShelfCandidateLimit);
});

final booksWithLeavesProvider = FutureProvider<List<Book>>((ref) async {
  try {
    final result = await FirestoreCacheFirst.document(
      FirebaseFirestore.instance
          .collection('settings')
          .doc('homepage_compiled'),
      operation: 'homepage_books_with_leaves',
    );
    final doc = result.cacheAvailable ? result.cached : await result.refresh;
    if (doc == null) throw StateError('Compiled homepage unavailable');
    final data = doc.data();
    if (doc.exists && data != null) {
      final compiled = CompiledHomepage.fromJson(data);
      final compiledBooks = compiled.shelves.booksWithLeaves
          .where(_hasContentLeaf)
          .take(_leafShelfDisplayLimit)
          .toList();
      if (compiledBooks.isNotEmpty) return compiledBooks;
    }
  } catch (_) {
    // Fall through to the legacy query when the compiled cache is unavailable.
  }

  final allBooks = await ref.watch(rawBooksWithLeavesProvider.future);
  return allBooks.where(_hasContentLeaf).take(_leafShelfDisplayLimit).toList();
});

final contentOnAgaazTopicsProvider = FutureProvider<List<Book>>((ref) async {
  final allBooks = await ref.watch(rawBooksWithLeavesProvider.future);
  return allBooks
      .where(_hasOnlyCertificateLeaves)
      .take(_leafShelfDisplayLimit)
      .toList();
});

bool _hasContentLeaf(Book book) {
  final leaves = book.leaves;
  if (leaves == null || leaves.isEmpty) {
    return book.hasLeaves == true && (book.leafCount ?? 0) > 0;
  }
  return leaves.any((leaf) => leaf.type != LeafType.certificate);
}

bool _hasOnlyCertificateLeaves(Book book) {
  final leaves = book.leaves;
  if (leaves == null || leaves.isEmpty) return false;
  return leaves.every((leaf) => leaf.type == LeafType.certificate);
}

final currentUserAdminClaimProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user =
      authState.asData?.value ??
      firebase_auth.FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  final token = await user.getIdTokenResult();
  return token.claims?['admin'] == true;
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

final liveBookDetailProvider = StreamProvider.family<Book?, String>((
  ref,
  bookId,
) async* {
  Book? initial;
  if (_isFirebaseBookId(bookId)) {
    final reference = FirebaseFirestore.instance
        .collection('books')
        .doc(bookId);
    final cached = await FirestoreCacheFirst.cachedDocument(
      reference,
      operation: 'live_book_cache',
    );
    initial = _bookFromSnapshot(cached);
    if (initial == null) {
      final refreshed = await FirestoreCacheFirst.refreshDocument(
        reference,
        operation: 'live_book_initial_refresh',
      );
      initial = _bookFromSnapshot(refreshed);
    }
  } else {
    initial = await ref.watch(bookRepositoryProvider).getBook(bookId);
  }
  if (initial != null) yield initial;

  if (!_shouldWatchFirebaseBook(bookId, initial)) {
    if (initial == null) yield null;
    return;
  }

  var previous = initial;
  await for (final next
      in FirebaseFirestore.instance
          .collection('books')
          .doc(bookId)
          .snapshots()
          .map(_bookFromSnapshot)) {
    if (!_sameBookSnapshot(previous, next)) {
      previous = next;
      yield next;
    }
  }
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

final readingHistoryBooksProvider = FutureProvider.family<List<Book>, int>((
  ref,
  limit,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null || user.readingHistory.isEmpty) return [];

  final ids = user.readingHistory
      .take(limit)
      .map((id) => id.toString())
      .toList();
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
List<Chapter> _publicChapters(Iterable<Chapter> chapters) {
  return chapters
      .where((chapter) => !chapter.isHidden && chapter.status != 'draft')
      .toList(growable: false);
}

final bookChaptersProvider = FutureProvider.family<List<Chapter>, String>((
  ref,
  bookId,
) async {
  final chapters = await ref.watch(bookRepositoryProvider).getChapters(bookId);
  return _publicChapters(chapters);
});

final liveBookChaptersProvider = StreamProvider.family<List<Chapter>, String>((
  ref,
  bookId,
) async* {
  final query = FirebaseFirestore.instance
      .collection('books')
      .doc(bookId)
      .collection('chapters')
      .orderBy('order');
  List<Chapter> initial;
  if (!_isFirebaseBookId(bookId)) {
    initial = await ref.watch(bookRepositoryProvider).getChapters(bookId);
    yield _publicChapters(initial);
    final book = await ref.read(bookRepositoryProvider).getBook(bookId);
    if (!_shouldWatchFirebaseBook(bookId, book)) return;
  } else {
    final initialStopwatch = Stopwatch()..start();
    var snapshot = await FirestoreCacheFirst.cachedQuery(
      query,
      operation: 'live_chapters_cache',
    );
    var remaining =
        FirestoreCacheFirst.defaultServerTimeout - initialStopwatch.elapsed;
    if (snapshot == null && remaining > Duration.zero) {
      snapshot = await FirestoreCacheFirst.refreshQuery(
        query,
        operation: 'live_chapters_initial_refresh',
        serverTimeout: remaining,
      );
    }
    initial = snapshot == null
        ? const <Chapter>[]
        : _chaptersFromSnapshot(snapshot);
    if (snapshot != null && snapshot.docs.isNotEmpty && initial.isEmpty) {
      remaining =
          FirestoreCacheFirst.defaultServerTimeout - initialStopwatch.elapsed;
      final refreshed = remaining <= Duration.zero
          ? null
          : await FirestoreCacheFirst.refreshQuery(
              query,
              operation: 'live_chapters_repair_refresh',
              serverTimeout: remaining,
            );
      if (refreshed != null) initial = _chaptersFromSnapshot(refreshed);
    }
    if (initial.isEmpty) {
      remaining =
          FirestoreCacheFirst.defaultServerTimeout - initialStopwatch.elapsed;
      initial = await _initialEmbeddedChapters(bookId, remaining);
    }
    yield _publicChapters(initial);
  }

  var previous = _publicChapters(initial);
  await for (final next in query.snapshots().asyncMap((snapshot) async {
    if (snapshot.docs.isEmpty) {
      return _publicChapters(await _cachedEmbeddedChapters(bookId));
    }
    return _publicChapters(_chaptersFromSnapshot(snapshot));
  })) {
    if (!_sameChapterSnapshots(previous, next)) {
      previous = next;
      yield next;
    }
  }
});

Book? _bookFromSnapshot(DocumentSnapshot<Map<String, dynamic>>? doc) {
  if (doc == null || !doc.exists || doc.data() == null) return null;
  try {
    final data = normalizeBookMapForModel(asStringMap(doc.data()), doc.id);
    return Book.fromJson(data);
  } catch (_) {
    return null;
  }
}

List<Chapter> _chaptersFromSnapshot(
  QuerySnapshot<Map<String, dynamic>> snapshot,
) {
  final chapters = <Chapter>[];
  for (final doc in snapshot.docs) {
    try {
      final data = asStringMap(doc.data());
      data['id'] = doc.id;
      data['title'] = data['title']?.toString() ?? 'Chapter';
      data['content'] = data['content']?.toString() ?? '';
      data['index'] = data['index'] is num
          ? (data['index'] as num).toInt()
          : data['order'] is num
          ? (data['order'] as num).toInt()
          : int.tryParse(data['index']?.toString() ?? '') ??
                int.tryParse(data['order']?.toString() ?? '') ??
                0;
      if (data['lastSavedAt'] is Timestamp) {
        data['lastSavedAt'] =
            (data['lastSavedAt'] as Timestamp).millisecondsSinceEpoch;
      }
      chapters.add(Chapter.fromJson(data));
    } catch (_) {
      // Keep other cached/live chapters usable if one document is malformed.
    }
  }
  return chapters;
}

Future<List<Chapter>> _cachedEmbeddedChapters(String bookId) async {
  final cached = await FirestoreCacheFirst.cachedDocument(
    FirebaseFirestore.instance.collection('books').doc(bookId),
    operation: 'live_embedded_chapters_cache',
  );
  return _bookFromSnapshot(cached)?.chapters ?? const <Chapter>[];
}

Future<List<Chapter>> _initialEmbeddedChapters(
  String bookId,
  Duration serverBudget,
) async {
  final reference = FirebaseFirestore.instance.collection('books').doc(bookId);
  final cached = await FirestoreCacheFirst.cachedDocument(
    reference,
    operation: 'live_embedded_chapters_initial_cache',
  );
  final snapshot =
      cached ??
      (serverBudget <= Duration.zero
          ? null
          : await FirestoreCacheFirst.refreshDocument(
              reference,
              operation: 'live_embedded_chapters_initial_refresh',
              serverTimeout: serverBudget,
            ));
  return _bookFromSnapshot(snapshot)?.chapters ?? const <Chapter>[];
}

bool _sameBookSnapshot(Book? first, Book? second) {
  if (identical(first, second)) return true;
  if (first == null || second == null) return false;
  return first.id == second.id &&
      first.updatedAt == second.updatedAt &&
      first.chapterCount == second.chapterCount &&
      first.viewCount == second.viewCount;
}

bool _sameChapterSnapshots(List<Chapter> first, List<Chapter> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    final a = first[index];
    final b = second[index];
    if (a.id != b.id ||
        a.title != b.title ||
        a.index != b.index ||
        a.status != b.status ||
        a.isHidden != b.isHidden ||
        a.lastSavedAt != b.lastSavedAt ||
        a.revision != b.revision ||
        a.content != b.content) {
      return false;
    }
  }
  return true;
}

bool _isFirebaseBookId(String bookId) {
  return bookId.length == 20 && RegExp(r'^[a-zA-Z0-9]{20}$').hasMatch(bookId);
}

bool _shouldWatchFirebaseBook(String bookId, Book? book) {
  if (bookId.startsWith('local-')) return false;
  if (book?.source == 'archive') return false;
  return book != null || _isFirebaseBookId(bookId);
}

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

final leafControllerProvider = Provider<LeafController>((ref) {
  return LeafController(ref);
});

class LeafController {
  const LeafController(this._ref);

  final Ref _ref;

  Future<LeafMutationResult> createLeaf({
    required String bookId,
    required Map<String, dynamic> leaf,
  }) async {
    final result = await _ref
        .read(bookRepositoryProvider)
        .createBookLeaf(bookId: bookId, leaf: leaf);
    _invalidateLeafReads(bookId);
    return result;
  }

  Future<LeafMutationResult> deleteLeaf({
    required String bookId,
    required String leafId,
  }) async {
    final result = await _ref
        .read(bookRepositoryProvider)
        .deleteBookLeaf(bookId: bookId, leafId: leafId);
    _invalidateLeafReads(bookId);
    return result;
  }

  void _invalidateLeafReads(String bookId) {
    _ref.invalidate(liveBookDetailProvider(bookId));
    _ref.invalidate(bookDetailProvider(bookId));
    _ref.invalidate(booksWithLeavesProvider);
  }
}

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
