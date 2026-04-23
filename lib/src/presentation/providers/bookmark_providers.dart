import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_bookmark_repository.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/bookmark_repository.dart';
import 'auth_providers.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return FirebaseBookmarkRepository();
});

final userBookmarksProvider = FutureProvider<List<Bookmark>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.watch(bookmarkRepositoryProvider).getUserBookmarks(user.id);
});

final bookBookmarksProvider = FutureProvider.family<List<Bookmark>, String>((
  ref,
  bookId,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref
      .watch(bookmarkRepositoryProvider)
      .getBookBookmarks(user.id, bookId);
});
