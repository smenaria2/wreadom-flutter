class ChapterEditLock {
  const ChapterEditLock({
    required this.chapterId,
    required this.holderId,
    required this.holderName,
    required this.acquiredAt,
    required this.heartbeatAt,
    required this.expiresAt,
  });

  factory ChapterEditLock.fromJson(Map<String, dynamic> json) {
    return ChapterEditLock(
      chapterId: json['chapterId']?.toString() ?? '',
      holderId: json['holderId']?.toString() ?? '',
      holderName: json['holderName']?.toString() ?? 'Co-author',
      acquiredAt: _readMillis(json['acquiredAt']),
      heartbeatAt: _readMillis(json['heartbeatAt']),
      expiresAt: _readMillis(json['expiresAt']),
    );
  }

  final String chapterId;
  final String holderId;
  final String holderName;
  final int acquiredAt;
  final int heartbeatAt;
  final int expiresAt;

  bool isExpiredAt(int now) => expiresAt <= now;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'chapterId': chapterId,
      'holderId': holderId,
      'holderName': holderName,
      'acquiredAt': acquiredAt,
      'heartbeatAt': heartbeatAt,
      'expiresAt': expiresAt,
    };
  }

  static int _readMillis(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

class ChapterLockHolder {
  const ChapterLockHolder({required this.id, required this.name});

  final String id;
  final String name;
}
