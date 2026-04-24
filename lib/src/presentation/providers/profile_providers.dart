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

final publicProfilesProvider = FutureProvider.family<List<UserModel>, List<String>>((
  ref,
  userIds,
) async {
  final viewer = await ref.watch(currentUserProvider.future);
  return ref
      .watch(profileRepositoryProvider)
      .getPublicProfilesByIds(userIds, viewerUserId: viewer?.id);
});

final profileSearchProvider = FutureProvider.family<List<UserModel>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) return [];
  return ref.watch(profileRepositoryProvider).searchProfiles(query);
});
