import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_profile_repository.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';
import 'auth_providers.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirebaseProfileRepository();
});

final publicProfileProvider = FutureProvider.family<UserModel?, String>((
  ref,
  userId,
) async {
  final viewer = await ref.watch(currentUserProvider.future);
  return ref
      .watch(profileRepositoryProvider)
      .getPublicProfile(userId, viewerUserId: viewer?.id);
});

final publicProfilesProvider =
    FutureProvider.family<List<UserModel>, List<String>>((ref, userIds) async {
      final normalizedIds = userIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final viewer = await ref.watch(currentUserProvider.future);
      return ref
          .watch(profileRepositoryProvider)
          .getPublicProfilesByIds(normalizedIds, viewerUserId: viewer?.id);
    });

final publicProfilesByStableIdsProvider =
    FutureProvider.family<List<UserModel>, String>((ref, idsKey) async {
      final ids = idsKey
          .split('|')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();
      final viewer = await ref.watch(currentUserProvider.future);
      return ref
          .watch(profileRepositoryProvider)
          .getPublicProfilesByIds(ids, viewerUserId: viewer?.id);
    });

final profileSearchProvider = FutureProvider.family<List<UserModel>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) return [];
  return ref.watch(profileRepositoryProvider).searchProfiles(query);
});
