import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/gamification_constants.dart';
import '../../domain/models/points_history.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/gamification_repository.dart';

class FirebaseGamificationRepository implements GamificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String historyCollection = 'points_history';
  static const String usersCollection = 'users';

  @override
  Future<void> updateUserPoints(
    String userId, 
    String actionType, {
    String? targetId,
    String? customDescription,
  }) async {
    try {
      final points = GamificationConstants.pointValues[actionType] ?? 0;
      if (points == 0) return;

      final userRef = _firestore.collection(usersCollection).doc(userId);

      // 1. Update User Document (Atomic Increment)
      await userRef.update({
        'totalPoints': FieldValue.increment(points),
        'pointsLastUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // 2. Log to History
      final historyItem = {
        'userId': userId,
        'type': points > 0 ? 'earn' : 'deduct',
        'points': points.abs(),
        'actionType': actionType.toLowerCase(),
        'description': customDescription ?? 'Points for ${actionType.replaceAll('_', ' ').toLowerCase()}',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'targetId': targetId,
      };

      await _firestore.collection(historyCollection).add(historyItem);

      // 3. Check for Tier Update (Background check)
      _checkAndHandleTierUpdate(userId).catchError((err) => print('Tier update check failed: $err'));
    } catch (e) {
      print('Error updating points: $e');
    }
  }

  Future<void> _checkAndHandleTierUpdate(String userId) async {
    try {
      final userDoc = await _firestore.collection(usersCollection).doc(userId).get();
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final currentPoints = (data['totalPoints'] as num?)?.toInt() ?? 0;
      final currentTier = (data['tier'] as num?)?.toInt() ?? 1;

      final calculatedTier = GamificationConstants.getTier(currentPoints);
      final newTierLevel = calculatedTier['level'] as int;

      if (newTierLevel != currentTier) {
        await _firestore.collection(usersCollection).doc(userId).update({
          'tier': newTierLevel,
        });

        // Log level up to history
        await _firestore.collection(historyCollection).add({
          'userId': userId,
          'type': 'earn',
          'points': 0,
          'actionType': 'milestone',
          'description': 'Reached Level $newTierLevel: ${calculatedTier['name']}!',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('Error checking tier update: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getPointsHistory(
    String userId, {
    dynamic lastDoc,
    int limitCount = 20,
  }) async {
    try {
      var query = _firestore
          .collection(historyCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limitCount);

      if (lastDoc != null && lastDoc is DocumentSnapshot) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return PointsHistoryItem.fromJson(data);
      }).toList();

      return {
        'items': items,
        'lastDoc': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      };
    } catch (e) {
      print('Error fetching points history: $e');
      rethrow;
    }
  }

  @override
  Future<int> getUserRank(String userId, {int? currentPoints}) async {
    try {
      int userPoints = 0;
      if (currentPoints != null) {
        userPoints = currentPoints;
      } else {
        final userDoc = await _firestore.collection(usersCollection).doc(userId).get();
        if (!userDoc.exists) return 0;
        userPoints = (userDoc.data()?['totalPoints'] as num?)?.toInt() ?? 0;
      }

      final countSnapshot = await _firestore
          .collection(usersCollection)
          .where('totalPoints', isGreaterThan: userPoints)
          .count()
          .get();

      return countSnapshot.count! + 1;
    } catch (e) {
      print('Error getting user rank: $e');
      return 0;
    }
  }

  @override
  Future<List<UserModel>> getLeaderboard({int limitCount = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(usersCollection)
          .orderBy('totalPoints', descending: true)
          .limit(limitCount * 3) // Fetch more to filter private
          .get();

      final allUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromJson(data);
      }).toList();

      return allUsers.where((u) => u.privacyLevel != 'private').take(limitCount).toList();
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }
}
