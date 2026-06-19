import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/services/notification_service.dart';
import 'package:librebook_flutter/src/domain/models/app_notification.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';
import 'package:librebook_flutter/src/utils/notification_target_resolver.dart';

void main() {
  AppNotification notification({
    required String type,
    String link = '',
    String? targetId,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: 'n1',
      userId: 'u1',
      actorId: 'actor1',
      actorName: 'Actor',
      type: type,
      text: 'text',
      link: link,
      targetId: targetId,
      timestamp: 1,
      isRead: false,
      metadata: metadata,
    );
  }

  test('book comment notification prefers bookId over targetId', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'comment',
        targetId: 'post1',
        metadata: {'bookId': 'book1'},
      ),
    );

    expect(target?.route, AppRoutes.bookDetail);
    expect(target?.payload, 'book1');
  });

  test('post notification opens post detail', () {
    final target = NotificationTargetResolver.resolve(
      notification(type: 'post', link: 'https://wreadom.in/posts/post1'),
    );

    expect(target?.route, AppRoutes.postDetail);
    expect(target?.payload, 'post1');
  });

  test('published notification with book link opens book detail', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'published',
        link: 'https://wreadom.in/book/book1',
        targetId: 'book1',
      ),
    );

    expect(target?.route, AppRoutes.bookDetail);
    expect(target?.payload, 'book1');
  });

  test('book notification preserves chapter index from shared link', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'chapter_update',
        link: 'https://wreadom.in/?book=book1&mode=read&chapter=4',
        targetId: 'book1',
      ),
    );

    expect(target?.route, AppRoutes.bookDetail);
    expect(target?.payload, 'book1');
    expect(target?.chapterIndex, 3);
  });

  test('leaf update notification opens book detail and preserves leaf id', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'leaf_update',
        link: '/book?id=book1&leaf=leaf1',
        targetId: 'book1',
        metadata: {
          'bookId': 'book1',
          'leafId': 'leaf1',
          'leafType': 'link',
          'linkType': 'youtube',
        },
      ),
    );

    expect(target?.route, AppRoutes.bookDetail);
    expect(target?.payload, 'book1');
    expect(target?.leafId, 'leaf1');
  });

  test(
    'new creation notification with backend book link opens book detail',
    () {
      final target = NotificationTargetResolver.resolve(
        notification(
          type: 'new_creation',
          link: '/book?id=book1',
          targetId: 'book1',
        ),
      );

      expect(target?.route, AppRoutes.bookDetail);
      expect(target?.payload, 'book1');
    },
  );

  test(
    'custom external notification exposes browser URL, not an app route',
    () {
      final item = notification(
        type: 'new_creation',
        link: 'https://example.com/articles/story',
        metadata: {'targetType': 'custom'},
      );

      expect(NotificationTargetResolver.resolve(item), isNull);
      expect(
        NotificationTargetResolver.externalUri(item),
        Uri.parse('https://example.com/articles/story'),
      );
    },
  );

  test('custom Wreadom app link still resolves inside the app', () {
    final item = notification(
      type: 'new_creation',
      link: 'https://wreadom.in/category/poetry',
      metadata: {'targetType': 'custom'},
    );

    expect(NotificationTargetResolver.externalUri(item), isNull);
    expect(NotificationTargetResolver.resolve(item)?.route, AppRoutes.category);
    expect(NotificationTargetResolver.resolve(item)?.payload, 'poetry');
  });

  test('custom link ignores stale book routing metadata', () {
    final item = notification(
      type: 'new_creation',
      link: 'https://example.com/custom',
      targetId: 'oldBook',
      metadata: {
        'targetType': 'custom',
        'bookId': 'oldBook',
        'contentId': 'oldBook',
      },
    );

    expect(NotificationTargetResolver.resolve(item), isNull);
    expect(
      NotificationTargetResolver.externalUri(item),
      Uri.parse('https://example.com/custom'),
    );
  });

  test('daily topic new creation notification opens daily topic', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'new_creation',
        link:
            'https://wreadom.in/daily-topic?id=topic123&topic=%E0%A4%86%E0%A4%9C',
        targetId: 'topic123',
        metadata: {
          'targetType': 'daily_topic',
          'topicId': 'topic123',
          'topicName': 'आज',
        },
      ),
    );

    expect(target?.route, AppRoutes.dailyTopic);
    expect(target?.payload, 'topic123');
  });

  test(
    'daily topic notification with malformed percent-encoding does not throw',
    () {
      final target = NotificationTargetResolver.resolve(
        notification(
          type: 'new_creation',
          link: 'https://wreadom.in/daily-topic?id=topic123&topic=Today%Topic',
          targetId: 'topic123',
          metadata: {'targetType': 'daily_topic', 'topicId': 'topic123'},
        ),
      );

      expect(target?.route, AppRoutes.dailyTopic);
      expect(target?.payload, 'topic123');
    },
  );

  test('daily topic link notification opens daily topic without metadata', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'announcement',
        link: 'https://wreadom.in/daily-topic?id=topic456',
      ),
    );

    expect(target?.route, AppRoutes.dailyTopic);
    expect(target?.payload, 'topic456');
  });

  test('published notification without link falls back to book targetId', () {
    final target = NotificationTargetResolver.resolve(
      notification(type: 'published', targetId: 'book1'),
    );

    expect(target?.route, AppRoutes.bookDetail);
    expect(target?.payload, 'book1');
  });

  test('chapter update without link falls back to book targetId', () {
    final target = NotificationTargetResolver.resolve(
      notification(type: 'chapter_update', targetId: 'book2'),
    );

    expect(target?.route, AppRoutes.bookDetail);
    expect(target?.payload, 'book2');
  });

  test('book like notification uses book link before comment targetId', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'like',
        link: 'https://wreadom.in/book/book1?comment=comment1',
        targetId: 'comment1',
      ),
    );

    expect(target?.route, AppRoutes.bookDetail);
    expect(target?.payload, 'book1');
  });

  test('book reply notification uses book link before comment targetId', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'reply',
        link: 'https://wreadom.in/book/book1?comment=comment1',
        targetId: 'comment1',
      ),
    );

    expect(target?.route, AppRoutes.bookDetail);
    expect(target?.payload, 'book1');
  });

  test('feed comment notification opens post detail from metadata', () {
    final target = NotificationTargetResolver.resolve(
      notification(type: 'feed_comment', metadata: {'postId': 'post42'}),
    );

    expect(target?.route, AppRoutes.postDetail);
    expect(target?.payload, 'post42');
  });

  test('feed comment notification uses feed query post id', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'comment',
        link: 'https://wreadom.in/feed?post=post1&comment=comment1',
        targetId: 'post1',
      ),
    );

    expect(target?.route, AppRoutes.postDetail);
    expect(target?.payload, 'post1');
  });

  test('feed like notification uses feed query post id', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'like',
        link: 'https://wreadom.in/feed?post=post1',
        targetId: 'post1',
      ),
    );

    expect(target?.route, AppRoutes.postDetail);
    expect(target?.payload, 'post1');
  });

  test('feed reply notification opens post detail from targetId', () {
    final target = NotificationTargetResolver.resolve(
      notification(type: 'feed_reply', targetId: 'post77'),
    );

    expect(target?.route, AppRoutes.postDetail);
    expect(target?.payload, 'post77');
  });

  test('feed post notification without link falls back to post targetId', () {
    final target = NotificationTargetResolver.resolve(
      notification(type: 'feedPost', targetId: 'post88'),
    );

    expect(target?.route, AppRoutes.postDetail);
    expect(target?.payload, 'post88');
  });

  test('message notification opens conversation from message link', () {
    final target = NotificationTargetResolver.resolve(
      notification(type: 'message', link: 'https://wreadom.in/messages/conv1'),
    );

    expect(target?.route, AppRoutes.conversation);
    expect(target?.payload, 'conv1');
  });

  test('follow notification opens actor profile', () {
    final target = NotificationTargetResolver.resolve(
      notification(type: 'follow'),
    );

    expect(target?.route, AppRoutes.publicProfile);
    expect(target?.payload, 'actor1');
  });

  test('testimonial notification opens profile from link before targetId', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'testimonial',
        link: 'https://wreadom.in/u/author1?tab=testimony',
        targetId: 'testimonial1',
      ),
    );

    expect(target?.route, AppRoutes.publicProfile);
    expect(target?.payload, 'author1');
  });

  test('mention with book link opens book detail', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'mention',
        link: 'https://wreadom.in/book/book1?comment=comment1',
        targetId: 'comment1',
      ),
    );

    expect(target?.route, AppRoutes.bookDetail);
    expect(target?.payload, 'book1');
  });

  test('mention with feed link opens post detail', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'mention',
        link: 'https://wreadom.in/feed?post=post1&comment=comment1',
        targetId: 'comment1',
      ),
    );

    expect(target?.route, AppRoutes.postDetail);
    expect(target?.payload, 'post1');
  });

  test('feed comment notification preserves target comment and reply ids', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'feed_comment',
        metadata: {
          'postId': 'post42',
          'commentId': 'comment7',
          'replyId': 'reply3',
        },
      ),
    );

    expect(target?.route, AppRoutes.postDetail);
    expect(target?.payload, 'post42');
    expect(target?.commentId, 'comment7');
    expect(target?.replyId, 'reply3');
  });

  test('book review notification preserves target comment and reply ids', () {
    final target = NotificationTargetResolver.resolve(
      notification(
        type: 'book_review',
        metadata: {
          'bookId': 'book9',
          'targetCommentId': 'comment9',
          'targetReplyId': 'reply9',
        },
      ),
    );

    expect(target?.route, AppRoutes.bookDetail);
    expect(target?.payload, 'book9');
    expect(target?.commentId, 'comment9');
    expect(target?.replyId, 'reply9');
  });

  test('same post notification navigation is deduped', () {
    final service = NotificationService.instance;
    service.resetNavigationDedupeForTest();
    final target = const NotificationTarget(
      AppRoutes.postDetail,
      'post42',
      commentId: 'comment7',
      replyId: 'reply3',
    );
    final data = {
      'notificationId': 'notification42',
      'type': 'feed_comment',
      'postId': 'post42',
      'commentId': 'comment7',
      'replyId': 'reply3',
    };

    expect(service.isDuplicateNavigationForTest(target, data), isFalse);
    expect(service.isDuplicateNavigationForTest(target, data), isTrue);
    service.resetNavigationDedupeForTest();
  });
}
