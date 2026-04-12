import '../models/points_history.dart';
import '../models/user_model.dart';

abstract class GamificationRepository {
  Future<void> updateUserPoints(
    String userId, 
    String actionType, {
    String? targetId,
    String? customDescription,
  });

  Future<Map<String, dynamic>> getPointsHistory(
    String userId, {
    dynamic lastDoc,
    int limitCount = 20,
  });

  Future<int> getUserRank(String userId, {int? currentPoints});

  Future<List<UserModel>> getLeaderboard({int limitCount = 20});
}
