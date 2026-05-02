import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'auth_providers.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
    });
    if (ref.mounted) state = result;
  }

  Future<void> signUp(String email, String password, String username) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password, username: username);
    });
    if (ref.mounted) state = result;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!ref.mounted) return;
      final user = await ref.read(currentUserProvider.future);
      if (!ref.mounted) return;
      if (user == null) {
        throw Exception(
          'Google sign-in could not complete. Please sign in to Google in your browser, then try again.',
        );
      }
      state = const AsyncValue.data(null);
    } on GoogleSignInException catch (e, st) {
      if (!ref.mounted) return;
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        state = const AsyncValue.data(null);
        return;
      }
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).logout();
    });
    if (ref.mounted) state = result;
  }
}
