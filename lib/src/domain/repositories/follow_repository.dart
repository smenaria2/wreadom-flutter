import '../models/user_model.dart';

abstract class FollowRepository {
  Future<bool> isFollowing(String followerId, String followingId);
  Future<void> followUser({
    required UserModel follower,
    required UserModel following,
  });
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  });
}
