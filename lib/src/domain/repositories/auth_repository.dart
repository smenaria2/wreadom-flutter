import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

abstract class AuthRepository {
  Stream<firebase.User?> get authStateChanges;
  
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
  });

  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  Future<UserModel> signInWithGoogle();

  Future<void> logout();

  Future<void> resetPassword(String email);

  Future<UserModel?> getUser(String userId);

  Future<UserModel?> getCurrentUser();

  Future<void> updateUserProfile(String userId, {String? displayName, String? photoURL});
  
  Future<void> updateUserSavedBooks(String userId, List<dynamic> savedBooks);
  
  Future<void> updateUserReadingHistory(String userId, List<dynamic> readingHistory);
  
  Future<void> updateFcmToken(String userId, String token);

  Future<List<UserModel>> searchUsers(String searchTerm, {int maxResults = 5});
}
