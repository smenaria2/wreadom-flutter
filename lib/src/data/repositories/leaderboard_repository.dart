import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/leaderboard_model.dart';

class LeaderboardRepository {
  final FirebaseFirestore _firestore;

  LeaderboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<LeaderboardRank>> fetchLeaderboard({
    required String period, // 'daily' | 'weekly' | 'monthly' | 'total'
    required String type, // 'author' | 'reader'
  }) async {
    try {
      if (period == 'total') {
        final pointField = type == 'author' ? 'authorPoints' : 'readerPoints';
        final snap = await _firestore
            .collection('users')
            .where(pointField, isGreaterThan: 0)
            .orderBy(pointField, descending: true)
            .limit(20)
            .get();

        return snap.docs.asMap().entries.map((entry) {
          final idx = entry.key;
          final doc = entry.value;
          final data = doc.data();
          final pts = (data[pointField] as num).toInt();
          return LeaderboardRank(
            rank: idx + 1,
            userId: doc.id,
            displayName: resolveLeaderboardDisplayName(data),
            photoUrl: data['photoURL'] ?? '',
            points: pts,
            // For total period, period points == all-time points
            allTimePoints: pts,
          );
        }).toList();
      }

      // Fetch snapshot from leaderboards collection
      final docRef = _firestore
          .collection('leaderboards')
          .doc('${period}_${type}_latest');
      final docSnap = await docRef.get();
      if (!docSnap.exists) return [];

      final rankings = LeaderboardDoc.fromMap(
        docSnap.data()!,
      ).rankings.take(20).toList();
      return _withCurrentAllTimePoints(rankings, type);
    } catch (e) {
      debugPrint('LeaderboardRepository: failed to fetch: $e');
      rethrow;
    }
  }

  Future<List<LeaderboardRank>> _withCurrentAllTimePoints(
    List<LeaderboardRank> rankings,
    String type,
  ) async {
    try {
      final userIds = rankings
          .map((entry) => entry.userId)
          .where((userId) => userId.isNotEmpty)
          .toSet()
          .toList();
      if (userIds.isEmpty) return rankings;

      final pointField = type == 'reader' ? 'readerPoints' : 'authorPoints';
      final users = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();
      final pointsByUserId = <String, int>{};
      for (final user in users.docs) {
        final value = user.data()[pointField];
        if (value is num) pointsByUserId[user.id] = value.toInt();
      }

      return rankings.map((entry) {
        final allTimePoints = pointsByUserId[entry.userId];
        return allTimePoints == null
            ? entry
            : entry.withAllTimePoints(allTimePoints);
      }).toList();
    } catch (e, s) {
      debugPrint('LeaderboardRepository: failed to enrich rankings: $e\n$s');
      return rankings;
    }
  }
}
