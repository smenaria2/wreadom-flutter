import '../models/paged_result.dart';

abstract class FollowRepository {
  Future<bool> isFollowing(String followerId, String followingId);
  Future<List<String>> getFollowingList(String followerId);
  Future<List<String>> getFollowersList(String followingId);
  Future<PagedResult<String>> getFollowingPage(
    String followerId, {
    int limit = 20,
    Object? cursor,
  });
  Future<PagedResult<String>> getFollowersPage(
    String followingId, {
    int limit = 20,
    Object? cursor,
  });
  Future<void> followUser({
    required String followerId,
    required String followingId,
  });
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  });
}
