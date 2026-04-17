import 'package:flutter_test/flutter_test.dart';
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

  test('follow notification opens actor profile', () {
    final target = NotificationTargetResolver.resolve(
      notification(type: 'follow'),
    );

    expect(target?.route, AppRoutes.publicProfile);
    expect(target?.payload, 'actor1');
  });
}
