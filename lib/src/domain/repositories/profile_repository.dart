import '../models/user_model.dart';

abstract class ProfileRepository {
  Future<UserModel?> getPublicProfile(String userId);
  Future<void> updateProfileDetails({
    required String userId,
    String? bio,
    String? penName,
    String? displayName,
  });
  Future<void> updatePrivacyLevel(String userId, String privacyLevel);
  Future<void> deactivateProfile(String userId);
  Future<void> reactivateProfile(String userId);
}
