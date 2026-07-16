import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_collection_repository.dart';
import '../../domain/models/author.dart';
import '../../domain/models/book.dart';
import '../../domain/models/book_collection.dart';
import '../../domain/models/collection_book.dart';
import '../../domain/repositories/collection_repository.dart';
import 'auth_providers.dart';
import 'book_providers.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return FirebaseCollectionRepository(
    bookRepository: ref.watch(bookRepositoryProvider),
  );
});

final userCollectionsProvider =
    FutureProvider.family<List<BookCollection>, String>((ref, userId) {
      return ref.watch(collectionRepositoryProvider).getUserCollections(userId);
    });

final currentUserCollectionsProvider = FutureProvider<List<BookCollection>>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return ref.watch(collectionRepositoryProvider).getUserCollections(user.id);
});
final collectionDetailProvider = StreamProvider.family<BookCollection?, String>(
  (ref, collectionId) {
    return ref
        .watch(collectionRepositoryProvider)
        .watchCollection(collectionId);
  },
);

final collectionEntriesProvider =
    StreamProvider.family<List<CollectionBook>, String>((ref, collectionId) {
      return ref
          .watch(collectionRepositoryProvider)
          .watchCollectionEntries(collectionId);
    });

final resolvedCollectionBooksProvider =
    FutureProvider.family<List<Book>, String>((ref, collectionId) async {
      final entries = await ref.watch(
        collectionEntriesProvider(collectionId).future,
      );
      if (entries.isEmpty) return const [];
      final ids = entries.map((entry) => entry.bookId).toList();
      final resolved = await ref
          .watch(bookRepositoryProvider)
          .getBooksByIds(ids);
      final byId = {for (final book in resolved) book.id: book};
      return ids.map((id) => byId[id] ?? _missingBook(id)).toList();
    });

final bookCollectionMembershipsProvider =
    FutureProvider.family<Set<String>, String>((ref, bookId) async {
      final user = await ref.watch(currentUserProvider.future);
      if (user == null) return const {};
      return ref
          .watch(collectionRepositoryProvider)
          .collectionIdsContainingBook(user.id, bookId);
    });

class CollectionMutationState {
  const CollectionMutationState({this.isLoading = false, this.error});
  final bool isLoading;
  final Object? error;
}

final collectionMutationProvider =
    NotifierProvider.family<
      CollectionMutationController,
      CollectionMutationState,
      String
    >(CollectionMutationController.new);

class CollectionMutationController extends Notifier<CollectionMutationState> {
  CollectionMutationController(this.collectionId);
  final String collectionId;

  @override
  CollectionMutationState build() => const CollectionMutationState();

  Future<T?> run<T>(
    Future<T> Function(CollectionRepository repository) action,
  ) async {
    if (state.isLoading) return null;
    state = const CollectionMutationState(isLoading: true);
    try {
      final value = await action(ref.read(collectionRepositoryProvider));
      if (ref.mounted) {
        ref.invalidate(userCollectionsProvider);
        ref.invalidate(currentUserCollectionsProvider);
        state = const CollectionMutationState();
      }
      return value;
    } catch (error) {
      if (ref.mounted) state = CollectionMutationState(error: error);
      rethrow;
    }
  }

  void clearError() => state = const CollectionMutationState();
}

Book _missingBook(String id) => Book(
  id: id,
  title: 'Deleted or inaccessible book',
  authors: const [Author(name: 'Unknown author')],
  subjects: const [],
  bookshelves: const [],
  languages: const [],
  formats: const {},
  downloadCount: 0,
  mediaType: 'texts',
);
