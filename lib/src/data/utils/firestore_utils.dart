import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/map_utils.dart';

/// Default `notificationSettings` document shape aligned with the web app /
/// [FirebaseAuthRepository] new-user writes. Used when the field is missing
/// on legacy user documents.
Map<String, dynamic> defaultNotificationSettingsMap() => {
  'messages': {'app': true, 'browser': false},
  'groupMessages': {'app': true, 'browser': false},
  'comments': {'app': true, 'browser': false},
  'replies': {'app': true, 'browser': false},
  'followers': {'app': true, 'browser': false},
  'testimonials': {'app': true, 'browser': false},
  'likes': {'app': true, 'browser': false},
  'followedAuthorPosts': {'app': true, 'browser': false},
  'newCreations': {'app': true, 'browser': false},
  'browserNotifications': false,
};

// Removed local ensureStringMap in favor of map_utils.dart

/// Ensures a raw `users/{id}` map can be parsed by [UserModel.fromJson]
/// (lists, notification defaults, id) without throwing on legacy docs.
Map<String, dynamic> normalizeUserMapForModel(dynamic raw, String docId) {
  final m = asStringMap(raw);
  m['id'] = docId;

  m['readingHistory'] = m['readingHistory'] is List
      ? List<dynamic>.from(m['readingHistory'] as List)
      : <dynamic>[];
  m['savedBooks'] = m['savedBooks'] is List
      ? List<dynamic>.from(m['savedBooks'] as List)
      : <dynamic>[];

  final bookmarksRaw = m['bookmarks'];
  if (bookmarksRaw is List) {
    m['bookmarks'] = bookmarksRaw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  } else {
    m['bookmarks'] = <dynamic>[];
  }

  if (m['notificationSettings'] == null || m['notificationSettings'] is! Map) {
    m['notificationSettings'] = defaultNotificationSettingsMap();
  }

  m['email'] = m['email']?.toString() ?? '';
  m['username'] = m['username']?.toString().isNotEmpty == true
      ? m['username'].toString()
      : 'reader';

  return m;
}

Map<String, dynamic> mapFirestoreData(dynamic data, String id) {
  final m = asStringMap(data);
  final result = Map<String, dynamic>.from(m);
  result['id'] = id;

  // Convert Timestamps to milliseconds since epoch for the model
  if (result['timestamp'] is Timestamp) {
    result['timestamp'] =
        (result['timestamp'] as Timestamp).millisecondsSinceEpoch;
  }

  // Ensure likes is at least an empty list if missing
  if (result['likes'] == null) {
    result['likes'] = <String>[];
  } else if (result['likes'] is! List) {
    result['likes'] = <String>[];
  } else {
    result['likes'] = (result['likes'] as List)
        .map((e) => e.toString())
        .toList();
  }

  if (result['replies'] is List) {
    result['replies'] = (result['replies'] as List).whereType<Map>().map((raw) {
      final reply = Map<String, dynamic>.from(raw);
      reply['userId'] = reply['userId']?.toString() ?? '';
      reply['username'] = reply['username']?.toString() ?? 'reader';
      reply['text'] = reply['text']?.toString() ?? '';
      reply['timestamp'] = reply['timestamp'] is int
          ? reply['timestamp']
          : int.tryParse(reply['timestamp']?.toString() ?? '') ?? 0;
      reply['likes'] = reply['likes'] is List
          ? (reply['likes'] as List).map((e) => e.toString()).toList()
          : <String>[];
      return reply;
    }).toList();
  }

  if (result['participantDetails'] is Map) {
    result['participantDetails'] = Map<String, dynamic>.from(
      (result['participantDetails'] as Map).map(
        (key, value) => MapEntry(
          key.toString(),
          value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{},
        ),
      ),
    );
  }

  if (result['memberStatus'] is Map) {
    result['memberStatus'] = Map<String, String>.from(
      (result['memberStatus'] as Map).map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      ),
    );
  }

  // Ensure visibility exists
  if (result['visibility'] == null) {
    result['visibility'] = 'public';
  }

  // Ensure type exists
  if (result['type'] == null) {
    result['type'] = 'post';
  }

  // Ensure text exists
  if (result['text'] == null) {
    result['text'] = '';
  }

  return result;
}

Map<String, dynamic> normalizeBookMapForModel(dynamic raw, String docId) {
  final m = asStringMap(raw);
  m['id'] = docId;

  // Ensure lists exist
  final authorsRaw = m['authors'];
  if (authorsRaw is List) {
    m['authors'] = authorsRaw.map((author) {
      if (author is Map) {
        final map = Map<String, dynamic>.from(author);
        map['name'] = map['name']?.toString() ?? 'Unknown Author';
        return map;
      }
      return {'name': author?.toString() ?? 'Unknown Author'};
    }).toList();
  } else {
    m['authors'] = <Map<String, dynamic>>[];
  }
  m['subjects'] = m['subjects'] is List
      ? (m['subjects'] as List).map((e) => e.toString()).toList()
      : <String>[];
  m['languages'] = m['languages'] is List
      ? (m['languages'] as List).map((e) => e.toString()).toList()
      : <String>['en'];
  m['bookshelves'] = m['bookshelves'] is List
      ? (m['bookshelves'] as List).map((e) => e.toString()).toList()
      : <String>[];
  m['topics'] = m['topics'] is List
      ? (m['topics'] as List).map((e) => e.toString()).toList()
      : null;

  // Ensure formats map exists
  if (m['formats'] is Map) {
    m['formats'] = Map<String, String>.from(
      (m['formats'] as Map).map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      ),
    );
  } else {
    m['formats'] = <String, String>{};
  }

  final chaptersRaw = m['chapters'];
  if (chaptersRaw is List) {
    m['chapters'] = chaptersRaw.whereType<Map>().map((chapter) {
      final map = Map<String, dynamic>.from(chapter);
      map['id'] = map['id']?.toString() ?? '';
      map['title'] = map['title']?.toString() ?? '';
      map['content'] = map['content']?.toString() ?? '';
      map['index'] = map['index'] is int
          ? map['index']
          : int.tryParse(map['index']?.toString() ?? '') ?? 0;
      return map;
    }).toList();
  }

  // Ensure IDs/Counts
  m['download_count'] ??= m['downloadCount'] ?? 0;
  m['viewCount'] ??= m['readCount'] ?? m['reads'] ?? m['views'] ?? 0;
  m['media_type'] ??= 'text';

  // Timestamps
  if (m['createdAt'] == null && m['timestamp'] != null) {
    m['createdAt'] = m['timestamp'];
  }

  if (m['createdAt'] is Timestamp) {
    m['createdAt'] = (m['createdAt'] as Timestamp).millisecondsSinceEpoch;
  }
  if (m['updatedAt'] is Timestamp) {
    m['updatedAt'] = (m['updatedAt'] as Timestamp).millisecondsSinceEpoch;
  }

  return m;
}
