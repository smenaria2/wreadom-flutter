class LeaderboardRank {
  final int rank;
  final String userId;
  final String displayName;
  final String photoUrl;
  final int points;

  /// All-time (lifetime) points used exclusively for tier calculation.
  /// This is always sourced from the user's persistent points field
  /// regardless of which leaderboard period is being displayed.
  final int? allTimePoints;

  const LeaderboardRank({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    required this.points,
    this.allTimePoints,
  });

  LeaderboardRank withAllTimePoints(int points) => LeaderboardRank(
    rank: rank,
    userId: userId,
    displayName: displayName,
    photoUrl: photoUrl,
    points: this.points,
    allTimePoints: points,
  );

  factory LeaderboardRank.fromMap(
    Map<String, dynamic> map, {
    String type = 'author',
  }) {
    // The periodic leaderboard documents may store the user's all-time points
    // under authorPoints or readerPoints alongside the period-specific 'points'.
    final allTimeKey = type == 'reader' ? 'readerPoints' : 'authorPoints';
    final rawAllTime = map[allTimeKey];
    final allTimePoints = rawAllTime is num ? rawAllTime.toInt() : null;
    return LeaderboardRank(
      rank: (map['rank'] as num).toInt(),
      userId: map['userId'] ?? '',
      displayName: resolveLeaderboardDisplayName(map),
      photoUrl: map['photoURL'] ?? '',
      points: (map['points'] as num).toInt(),
      allTimePoints: allTimePoints,
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
    final type = map['type'] as String? ?? 'author';
    return LeaderboardDoc(
      period: map['period'] ?? '',
      type: type,
      lastUpdatedAt: (map['lastUpdatedAt'] as num).toInt(),
      rankings:
          (map['rankings'] as List<dynamic>?)
              ?.map(
                (r) => LeaderboardRank.fromMap(
                  r as Map<String, dynamic>,
                  type: type,
                ),
              )
              .toList() ??
          [],
    );
  }
}
