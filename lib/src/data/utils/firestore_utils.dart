import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/map_utils.dart';

int? _intOrNull(dynamic value) {
  if (value is Timestamp) return value.millisecondsSinceEpoch;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _doubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

List<String> _stringList(dynamic value) => value is List
    ? value.map((entry) => entry.toString()).toList(growable: false)
    : <String>[];

Map<String, String>? _stringMapOrNull(dynamic value) {
  if (value is! Map) return null;
  return value.map(
    (key, mapValue) => MapEntry(key.toString(), mapValue.toString()),
  );
}

Map<String, dynamic> _normalizeCommentReplyMap(dynamic raw) {
  final reply = asStringMap(raw);
  reply['id'] = reply['id']?.toString();
  reply['userId'] = reply['userId']?.toString() ?? '';
  reply['username'] = reply['username']?.toString() ?? 'reader';
  reply['text'] = reply['text']?.toString() ?? '';
  reply['timestamp'] = _intOrNull(reply['timestamp']) ?? 0;
  reply['likes'] = _stringList(reply['likes']);
  reply['mentions'] = _stringMapOrNull(reply['mentions']);
  for (final key in const [
    'displayName',
    'penName',
    'userPhotoURL',
    'audioUrl',
    'audioObjectKey',
    'audioMimeType',
  ]) {
    reply[key] = reply[key]?.toString();
  }
  for (final key in const ['audioDurationMs', 'audioSizeBytes']) {
    reply[key] = _intOrNull(reply[key]);
  }
  return reply;
}

Map<String, dynamic> _normalizeCommentMap(dynamic raw) {
  final comment = asStringMap(raw);
  comment['id'] = comment['id']?.toString();
  comment['userId'] = comment['userId']?.toString() ?? '';
  comment['username'] = comment['username']?.toString() ?? 'reader';
  comment['text'] = comment['text']?.toString() ?? '';
  comment['timestamp'] = _intOrNull(comment['timestamp']) ?? 0;
  comment['likes'] = _stringList(comment['likes']);
  comment['replies'] = comment['replies'] is List
      ? (comment['replies'] as List)
            .whereType<Map>()
            .map(_normalizeCommentReplyMap)
            .toList(growable: false)
      : <Map<String, dynamic>>[];
  comment['mentions'] = _stringMapOrNull(comment['mentions']);
  for (final key in const [
    'rating',
    'chapterIndex',
    'likesCount',
    'repliesCount',
    'highlightedAt',
    'audioDurationMs',
    'audioSizeBytes',
  ]) {
    comment[key] = _intOrNull(comment[key]);
  }
  for (final key in const [
    'bookTitle',
    'chapterTitle',
    'chapterId',
    'quote',
    'feedPostId',
    'userPhotoURL',
    'displayName',
    'penName',
    'highlightedByUserId',
    'audioUrl',
    'audioObjectKey',
    'audioMimeType',
  ]) {
    comment[key] = comment[key]?.toString();
  }
  if (comment['isHighlighted'] is! bool) {
    comment['isHighlighted'] = null;
  }
  return comment;
}

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
  'dailyTopics': {'app': true, 'browser': false},
  'recommendedContent': {'app': true, 'browser': false},
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
    m['bookmarks'] = bookmarksRaw.whereType<Map>().map((entry) {
      final bookmark = asStringMap(entry);
      bookmark['id'] = bookmark['id']?.toString();
      bookmark['userId'] = bookmark['userId']?.toString() ?? docId;
      bookmark['position'] = _doubleOrNull(bookmark['position']) ?? 0.0;
      bookmark['label'] = bookmark['label']?.toString() ?? '';
      bookmark['timestamp'] = _intOrNull(bookmark['timestamp']) ?? 0;
      bookmark['chapterIndex'] = _intOrNull(bookmark['chapterIndex']);
      bookmark['chapterTitle'] = bookmark['chapterTitle']?.toString();
      bookmark['highlightedText'] = bookmark['highlightedText']?.toString();
      return bookmark;
    }).toList();
  } else {
    m['bookmarks'] = <dynamic>[];
  }

  m['notificationSettings'] = _mergeNotificationSettingsDefaults(
    m['notificationSettings'],
  );

  m['email'] = m['email']?.toString() ?? '';
  m['username'] = m['username']?.toString().isNotEmpty == true
      ? m['username'].toString()
      : 'reader';
  for (final key in const [
    'displayName',
    'photoURL',
    'coverPhotoURL',
    'bio',
    'penName',
    'privacyLevel',
    'preferredLanguage',
  ]) {
    m[key] = m[key]?.toString();
  }
  for (final key in const [
    'followersCount',
    'followingCount',
    'createdAt',
    'lastLogin',
    'authorPoints',
    'authorRank',
    'readerPoints',
    'readerRank',
    'booksReadCount',
    'commentsPostedCount',
  ]) {
    m[key] = _intOrNull(m[key]);
  }
  m['pinnedWorks'] = m['pinnedWorks'] == null
      ? null
      : _stringList(m['pinnedWorks']);
  m['fcmTokens'] = m['fcmTokens'] == null ? null : _stringList(m['fcmTokens']);
  if (m['readingProgress'] is! Map) m['readingProgress'] = null;
  if (m['profileVisibility'] is! Map) m['profileVisibility'] = null;
  if (m['isDeactivated'] is! bool) m['isDeactivated'] = null;

  return m;
}

Map<String, dynamic> _mergeNotificationSettingsDefaults(dynamic raw) {
  final defaults = defaultNotificationSettingsMap();
  if (raw is! Map) return defaults;

  final normalized = asStringMap(raw);
  for (final entry in defaults.entries) {
    if (entry.value is Map<String, dynamic>) {
      final current = normalized[entry.key];
      final fallback = Map<String, dynamic>.from(
        entry.value as Map<String, dynamic>,
      );
      final candidate = current is Map ? asStringMap(current) : fallback;
      normalized[entry.key] = {
        'app': candidate['app'] is bool ? candidate['app'] : fallback['app'],
        'browser': candidate['browser'] is bool
            ? candidate['browser']
            : fallback['browser'],
      };
    } else {
      if (normalized[entry.key] is! bool) {
        normalized[entry.key] = entry.value;
      }
    }
  }
  return normalized;
}

Map<String, dynamic> mapFirestoreData(dynamic data, String id) {
  final m = asStringMap(data);
  final result = Map<String, dynamic>.from(m);
  result['id'] = id;

  // Convert Timestamps to milliseconds since epoch for the model
  result['timestamp'] = _intOrNull(result['timestamp']) ?? 0;

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
    result['replies'] = (result['replies'] as List)
        .whereType<Map>()
        .map(_normalizeCommentReplyMap)
        .toList();
  }

  result['userId'] = result['userId']?.toString() ?? '';
  result['username'] = result['username']?.toString() ?? 'reader';
  result['mentions'] = _stringMapOrNull(result['mentions']);
  if (result['comments'] is List) {
    result['comments'] = (result['comments'] as List)
        .whereType<Map>()
        .map(_normalizeCommentMap)
        .toList(growable: false);
  } else if (result.containsKey('comments')) {
    result['comments'] = <Map<String, dynamic>>[];
  }
  if (result['images'] is List) {
    result['images'] = (result['images'] as List)
        .whereType<Map>()
        .map((raw) {
          final image = asStringMap(raw);
          image['id'] = image['id']?.toString() ?? '';
          image['url'] = image['url']?.toString() ?? '';
          image['caption'] = image['caption']?.toString();
          image['likes'] = _stringList(image['likes']);
          return image;
        })
        .where((image) => (image['url'] as String).isNotEmpty)
        .toList(growable: false);
  } else if (result.containsKey('images')) {
    result['images'] = <Map<String, dynamic>>[];
  }
  for (final key in const [
    'rating',
    'likesCount',
    'commentCount',
    'audioDurationMs',
    'audioSizeBytes',
  ]) {
    result[key] = _intOrNull(result[key]);
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
  } else {
    result['text'] = result['text'].toString();
  }

  return result;
}

Map<String, dynamic> normalizeBookMapForModel(dynamic raw, String docId) {
  final m = asStringMap(raw);
  m['id'] = docId;
  m['title'] = m['title']?.toString().trim().isNotEmpty == true
      ? m['title'].toString()
      : 'Untitled';

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
  m['authorIds'] = m['authorIds'] is List
      ? (m['authorIds'] as List).map((e) => e.toString()).toList()
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

  final leavesRaw = m['leaves'];
  if (leavesRaw is List) {
    m['leaves'] = leavesRaw.whereType<Map>().map((leaf) {
      final map = Map<String, dynamic>.from(leaf);
      map['id'] = map['id']?.toString() ?? '';
      map['type'] = map['type']?.toString() ?? 'text';
      map['createdBy'] = map['createdBy']?.toString() ?? '';
      map['createdByRole'] = map['createdByRole']?.toString();
      if (map['createdAt'] is Timestamp) {
        map['createdAt'] =
            (map['createdAt'] as Timestamp).millisecondsSinceEpoch;
      } else {
        map['createdAt'] = map['createdAt'] is int
            ? map['createdAt']
            : int.tryParse(map['createdAt']?.toString() ?? '') ?? 0;
      }
      for (final key in const [
        'textHtml',
        'textPlain',
        'imageUrl',
        'imageAlt',
        'url',
        'linkType',
        'title',
        'question',
        'audioUrl',
        'audioObjectKey',
        'audioMimeType',
      ]) {
        map[key] = map[key]?.toString();
      }
      for (final key in const [
        'wordCount',
        'audioDurationMs',
        'audioSizeBytes',
        'certificateIssuedAt',
      ]) {
        map[key] = map[key] is int
            ? map[key]
            : int.tryParse(map[key]?.toString() ?? '');
      }
      return map;
    }).toList();
  } else {
    m['leaves'] = <Map<String, dynamic>>[];
  }

  // Ensure IDs/Counts
  m['download_count'] =
      _intOrNull(m['download_count'] ?? m['downloadCount']) ?? 0;
  m['viewCount'] =
      _intOrNull(
        m['viewCount'] ?? m['readCount'] ?? m['reads'] ?? m['views'],
      ) ??
      0;
  m['media_type'] = m['media_type']?.toString() ?? 'text';

  for (final key in const [
    'createdAt',
    'updatedAt',
    'publishedAt',
    'recommendationCount',
    'ratingsCount',
    'chapterCount',
    'collaborationRequestedAt',
    'collaborationRespondedAt',
    'leafCount',
    'leafUpdatedAt',
  ]) {
    m[key] = _intOrNull(m[key]);
  }
  for (final key in const ['weightedScore', 'averageRating']) {
    m[key] = _doubleOrNull(m[key]);
  }
  for (final key in const [
    'description',
    'coverUrl',
    'source',
    'contentType',
    'authorId',
    'status',
    'identifier',
    'collaborationStatus',
    'collaboratorId',
    'collaboratorName',
    'collaboratorPhotoURL',
    'collaborationRequestedBy',
  ]) {
    m[key] = m[key]?.toString();
  }
  for (final key in const ['isOriginal', 'hasLeaves', 'optOutComplementary']) {
    if (m[key] is! bool) m[key] = null;
  }

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
  if (m['publishedAt'] is Timestamp) {
    m['publishedAt'] = (m['publishedAt'] as Timestamp).millisecondsSinceEpoch;
  }
  if (m['leafUpdatedAt'] is Timestamp) {
    m['leafUpdatedAt'] =
        (m['leafUpdatedAt'] as Timestamp).millisecondsSinceEpoch;
  }
  if (m['collaborationRequestedAt'] is Timestamp) {
    m['collaborationRequestedAt'] =
        (m['collaborationRequestedAt'] as Timestamp).millisecondsSinceEpoch;
  }
  if (m['collaborationRespondedAt'] is Timestamp) {
    m['collaborationRespondedAt'] =
        (m['collaborationRespondedAt'] as Timestamp).millisecondsSinceEpoch;
  }

  return m;
}
