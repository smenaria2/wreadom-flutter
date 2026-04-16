
abstract class FollowRepository {
  Future<bool> isFollowing(String followerId, String followingId);
  Future<List<String>> getFollowingList(String followerId);
  Future<void> followUser({
    required String followerId,
    required String followingId,
  });
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  });
}
