import '../models/user_model.dart';

abstract class ProfileRepository {
  /// [viewerUserId] is the signed-in user (null if logged out). Used for
  /// deactivated filtering and privacy / follower-only rules.
  Future<UserModel?> getPublicProfile(String userId, {String? viewerUserId});
  Future<List<UserModel>> searchProfiles(String query, {int limit = 10});
  Future<void> updateProfileDetails({
    required String userId,
    String? bio,
    String? penName,
    String? displayName,
  });
  Future<void> updateCoverPhoto(String userId, String? coverPhotoURL);
  Future<void> updatePrivacyLevel(String userId, String privacyLevel);
  Future<void> deactivateProfile(String userId);
  Future<void> reactivateProfile(String userId);
}
