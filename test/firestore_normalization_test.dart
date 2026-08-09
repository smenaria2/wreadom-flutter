import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/utils/firestore_utils.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/domain/models/comment.dart';
import 'package:librebook_flutter/src/domain/models/feed_post.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';

void main() {
  test('legacy user values are normalized before model parsing', () {
    final normalized = normalizeUserMapForModel({
      'email': 123,
      'username': null,
      'followersCount': '7',
      'readingHistory': null,
      'savedBooks': 'invalid',
      'bookmarks': [
        {'bookId': 'book-1', 'position': '0.45', 'timestamp': '42'},
      ],
      'notificationSettings': {
        'messages': {'app': 'yes', 'browser': null},
      },
    }, 'user-1');

    final user = UserModel.fromJson(normalized);
    expect(user.id, 'user-1');
    expect(user.email, '123');
    expect(user.followersCount, 7);
    expect(user.bookmarks.single.position, 0.45);
    expect(user.notificationSettings!.messages.app, isTrue);
  });

  test('legacy book number and string values remain readable', () {
    final normalized = normalizeBookMapForModel({
      'title': null,
      'authors': ['Writer'],
      'subjects': [1, 'Poetry'],
      'languages': ['hi'],
      'formats': {'application/pdf': 123},
      'download_count': '12',
      'media_type': 7,
      'bookshelves': null,
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(99),
      'averageRating': '4.5',
      'viewCount': '8',
    }, 'book-1');

    final book = Book.fromJson(normalized);
    expect(book.title, 'Untitled');
    expect(book.downloadCount, 12);
    expect(book.mediaType, '7');
    expect(book.averageRating, 4.5);
    expect(book.viewCount, 8);
  });

  test('malformed nested feed values are isolated and coerced', () {
    final normalized = mapFirestoreData({
      'userId': 99,
      'username': null,
      'type': null,
      'text': 42,
      'timestamp': '100',
      'likes': [1, 'user-2'],
      'visibility': null,
      'comments': [
        {
          'userId': 4,
          'username': null,
          'text': 5,
          'timestamp': '7',
          'replies': [
            {'userId': 8, 'text': 9, 'timestamp': '10'},
          ],
        },
      ],
      'images': [
        {'id': 1, 'url': null, 'likes': 'invalid'},
        {
          'id': 2,
          'url': 'https://example.com/image.jpg',
          'likes': [3],
        },
      ],
    }, 'post-1');

    final post = FeedPost.fromJson(normalized);
    expect(post.userId, '99');
    expect(post.username, 'reader');
    expect(post.type, 'post');
    expect(post.text, '42');
    expect(post.timestamp, 100);
    expect(post.images, hasLength(1));
    expect(post.comments, hasLength(1));

    final comment = Comment.fromJson(normalized['comments'].first);
    expect(comment.userId, '4');
    expect(comment.replies!.single.userId, '8');
  });
}
