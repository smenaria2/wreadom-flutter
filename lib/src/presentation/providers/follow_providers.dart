import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_follow_repository.dart';
import '../../domain/repositories/follow_repository.dart';
import 'auth_providers.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FirebaseFollowRepository();
});

final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, targetUserId) async {
  final followingList = await ref.watch(followingListProvider.future);
  return followingList.contains(targetUserId);
});

final followingListProvider = FutureProvider<List<String>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.read(followRepositoryProvider).getFollowingList(user.id);
});
