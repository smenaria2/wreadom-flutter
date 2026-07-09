import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/leaderboard_model.dart';

class LeaderboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<LeaderboardRank>> fetchLeaderboard({
    required String period, // 'daily' | 'weekly' | 'monthly' | 'total'
    required String type,   // 'author' | 'reader'
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
          return LeaderboardRank(
            rank: idx + 1,
            userId: doc.id,
            displayName: data['penName'] ??
                data['displayName'] ??
                data['username'] ??
                'Anonymous',
            photoUrl: data['photoURL'] ?? '',
            points: (data[pointField] as num).toInt(),
          );
        }).toList();
      }

      // Fetch snapshot from leaderboards collection
      final docRef = _firestore
          .collection('leaderboards')
          .doc('${period}_${type}_latest');
      final docSnap = await docRef.get();
      if (!docSnap.exists) return [];

      return LeaderboardDoc.fromMap(docSnap.data()!).rankings;
    } catch (e) {
      debugPrint('LeaderboardRepository: failed to fetch: $e');
      return [];
    }
  }
}
