class AppNotification {
  const AppNotification({
    this.id,
    required this.userId,
    required this.actorId,
    required this.actorName,
    this.actorPhotoURL,
    required this.type,
    required this.text,
    required this.link,
    this.targetId,
    required this.timestamp,
    required this.isRead,
    this.metadata,
  });

  final String? id;
  final String userId;
  final String actorId;
  final String actorName;
  final String? actorPhotoURL;
  final String type;
  final String text;
  final String link;
  final String? targetId;
  final int timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String?,
      userId: (json['userId'] ?? '') as String,
      actorId: (json['actorId'] ?? '') as String,
      actorName: (json['actorName'] ?? '') as String,
      actorPhotoURL: json['actorPhotoURL'] as String?,
      type: (json['type'] ?? 'message') as String,
      text: (json['text'] ?? '') as String,
      link: (json['link'] ?? '') as String,
      targetId: json['targetId'] as String?,
      timestamp: (json['timestamp'] ?? 0) as int,
      isRead: (json['isRead'] ?? false) as bool,
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'actorId': actorId,
      'actorName': actorName,
      'actorPhotoURL': actorPhotoURL,
      'type': type,
      'text': text,
      'link': link,
      'targetId': targetId,
      'timestamp': timestamp,
      'isRead': isRead,
      'metadata': metadata,
    };
  }
}
