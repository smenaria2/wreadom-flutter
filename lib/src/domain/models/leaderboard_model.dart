class LeaderboardRank {
  final int rank;
  final String userId;
  final String displayName;
  final String photoUrl;
  final int points;

  const LeaderboardRank({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    required this.points,
  });

  factory LeaderboardRank.fromMap(Map<String, dynamic> map) {
    return LeaderboardRank(
      rank: (map['rank'] as num).toInt(),
      userId: map['userId'] ?? '',
      displayName: resolveLeaderboardDisplayName(map),
      photoUrl: map['photoURL'] ?? '',
      points: (map['points'] as num).toInt(),
    );
  }
}

String resolveLeaderboardDisplayName(Map<String, dynamic> data) {
  for (final key in const ['penName', 'displayName', 'username']) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return 'Anonymous';
}

class LeaderboardDoc {
  final String period;
  final String type;
  final int lastUpdatedAt;
  final List<LeaderboardRank> rankings;

  const LeaderboardDoc({
    required this.period,
    required this.type,
    required this.lastUpdatedAt,
    required this.rankings,
  });

  factory LeaderboardDoc.fromMap(Map<String, dynamic> map) {
    return LeaderboardDoc(
      period: map['period'] ?? '',
      type: map['type'] ?? '',
      lastUpdatedAt: (map['lastUpdatedAt'] as num).toInt(),
      rankings:
          (map['rankings'] as List<dynamic>?)
              ?.map((r) => LeaderboardRank.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
