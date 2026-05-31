import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

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
  if (authState.isLoading) {
    return Completer<UserModel?>().future.asStream();
  }
  final user = authState.value;
  if (user == null) return Stream.value(null);
  return ref.read(authRepositoryProvider).watchUser(user.uid);
}

