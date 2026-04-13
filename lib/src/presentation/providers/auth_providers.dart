import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firebase_gamification_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
GamificationRepository gamificationRepository(Ref ref) {
  return FirebaseGamificationRepository();
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final gamificationRepo = ref.watch(gamificationRepositoryProvider);
  return FirebaseAuthRepository(gamificationRepo);
}

@riverpod
Stream<fb_auth.User?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

@riverpod
Future<UserModel?> currentUser(Ref ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Future.value(null);
      return ref.read(authRepositoryProvider).getUser(user.uid);
    },
    loading: () => Future.value(null),
    error: (_, _) => Future.value(null),
  );
}
