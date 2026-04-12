import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_follow_repository.dart';
import '../../domain/repositories/follow_repository.dart';
import 'auth_providers.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FirebaseFollowRepository();
});

final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, targetUserId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return false;
  return ref.watch(followRepositoryProvider).isFollowing(user.id, targetUserId);
});
