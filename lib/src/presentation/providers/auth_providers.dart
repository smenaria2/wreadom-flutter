import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'startup_cache_provider.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepository();
}

@riverpod
Stream<fb_auth.User?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

@riverpod
Stream<UserModel?> currentUser(Ref ref) {
  final authState = ref.watch(authStateProvider);
  final firebaseUser =
      authState.asData?.value ?? fb_auth.FirebaseAuth.instance.currentUser;
  if (authState.isLoading) {
    if (firebaseUser != null) return _cachedThenLiveUser(ref, firebaseUser.uid);
    return Completer<UserModel?>().future.asStream();
  }
  if (firebaseUser == null) return Stream.value(null);
  return _cachedThenLiveUser(ref, firebaseUser.uid);
}

Stream<UserModel?> _cachedThenLiveUser(Ref ref, String userId) async* {
  final cache = ref.read(startupDataCacheProvider);
  cache?.activateUser(userId);
  final cachedRaw = cache?.read<UserModel>(
    scope: 'current_user',
    userId: userId,
    decode: (json) =>
        UserModel.fromJson(Map<String, dynamic>.from(json! as Map)),
  );
  if (cachedRaw != null && cachedRaw.id != userId) {
    unawaited(cache?.remove(scope: 'current_user', userId: userId));
  }
  final cached = cachedRaw?.id == userId
      ? cachedRaw!.copyWith(fcmTokens: null)
      : null;
  if (cached != null) {
    if (cachedRaw!.fcmTokens?.isNotEmpty == true) {
      unawaited(
        cache?.write(
          scope: 'current_user',
          userId: userId,
          value: cached.toJson(),
        ),
      );
    }
    yield cached;
  }

  while (ref.mounted) {
    try {
      await for (final user
          in ref.read(authRepositoryProvider).watchUser(userId)) {
        if (user != null && user.id != userId) continue;
        if (user != null && user.id == userId) {
          final cacheValue = user.copyWith(fcmTokens: null);
          unawaited(
            cache?.write(
              scope: 'current_user',
              userId: userId,
              value: cacheValue.toJson(),
            ),
          );
        }
        yield user;
      }
      return;
    } catch (_) {
      if (cached == null) rethrow;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }
}

@riverpod
class IsSigningOut extends _$IsSigningOut {
  @override
  bool build() => false;

  void setSigningOut(bool value) => state = value;
}
