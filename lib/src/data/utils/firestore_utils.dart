import 'package:cloud_firestore/cloud_firestore.dart';

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

/// Ensures a raw `users/{id}` map can be parsed by [UserModel.fromJson]
/// (lists, notification defaults, id) without throwing on legacy docs.
Map<String, dynamic> normalizeUserMapForModel(Map<String, dynamic> raw, String docId) {
  final m = Map<String, dynamic>.from(raw);
  m['id'] = docId;

  m['readingHistory'] =
      m['readingHistory'] is List ? List<dynamic>.from(m['readingHistory'] as List) : <dynamic>[];
  m['savedBooks'] =
      m['savedBooks'] is List ? List<dynamic>.from(m['savedBooks'] as List) : <dynamic>[];

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

Map<String, dynamic> mapFirestoreData(Map<String, dynamic> data, String id) {
  final Map<String, dynamic> result = Map<String, dynamic>.from(data);
  result['id'] = id;

  // Convert Timestamps to milliseconds since epoch for the model
  if (result['timestamp'] is Timestamp) {
    result['timestamp'] = (result['timestamp'] as Timestamp).millisecondsSinceEpoch;
  }

  // Ensure likes is at least an empty list if missing
  if (result['likes'] == null) {
    result['likes'] = <String>[];
  } else if (result['likes'] is! List) {
     result['likes'] = <String>[];
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

Map<String, dynamic> normalizeBookMapForModel(Map<String, dynamic> raw, String docId) {
  final m = Map<String, dynamic>.from(raw);
  m['id'] = docId;

  // Ensure lists exist
  m['authors'] = m['authors'] is List ? m['authors'] : <dynamic>[];
  m['subjects'] = m['subjects'] is List ? m['subjects'] : <String>[];
  m['languages'] = m['languages'] is List ? m['languages'] : <String>['en'];
  m['bookshelves'] = m['bookshelves'] is List ? m['bookshelves'] : <String>[];

  // Ensure formats map exists
  if (m['formats'] == null || m['formats'] is! Map) {
    m['formats'] = <String, String>{};
  }

  // Ensure IDs/Counts
  m['download_count'] ??= 0;
  m['viewCount'] ??= 0;
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
