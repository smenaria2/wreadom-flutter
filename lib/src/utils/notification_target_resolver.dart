import '../domain/models/app_notification.dart';
import '../presentation/routing/app_routes.dart';
import 'app_link_helper.dart';

class NotificationTarget {
  const NotificationTarget(this.route, this.payload);

  final String route;
  final String payload;
}

class NotificationTargetResolver {
  static NotificationTarget? resolve(AppNotification notification) {
    final metadata = notification.metadata ?? const <String, dynamic>{};
    final linkTarget = AppLinkHelper.resolve(notification.link);

    final bookId = _firstValid([
      metadata['bookId'],
      metadata['book'],
      _idFromLink(notification.link, ['book', 'b']),
      linkTarget?.route == AppRoutes.bookDetail ? linkTarget?.payload : null,
    ]);

    final postId = _firstValid([
      metadata['postId'],
      metadata['feedPostId'],
      metadata['feedId'],
      _idFromLink(notification.link, ['post', 'posts', 'feed', 'p']),
      linkTarget?.route == AppRoutes.postDetail ? linkTarget?.payload : null,
    ]);

    final userId = _firstValid([
      metadata['userId'],
      notification.actorId,
      _idFromLink(notification.link, ['user', 'u']),
      linkTarget?.route == AppRoutes.publicProfile ? linkTarget?.payload : null,
    ]);

    final type = notification.type.toLowerCase();
    final targetId = _clean(notification.targetId);

    final isBookActivity =
        type.contains('book') ||
        type.contains('chapter') ||
        type.contains('quote') ||
        type.contains('review') ||
        (type.contains('comment') && bookId != null);

    if (isBookActivity && bookId != null) {
      return NotificationTarget(AppRoutes.bookDetail, bookId);
    }

    if ((type == 'follow' || type == 'following' || type.contains('follow')) &&
        userId != null) {
      return NotificationTarget(AppRoutes.publicProfile, userId);
    }

    final isPostActivity =
        type == 'post' ||
        type == 'feedpost' ||
        type == 'feed_comment' ||
        type == 'feed_reply' ||
        type.contains('post') ||
        type == 'like' ||
        type == 'comment' ||
        type == 'reply';

    if (isPostActivity && postId != null) {
      return NotificationTarget(AppRoutes.postDetail, postId);
    }

    if (!isBookActivity && !isPostActivity && linkTarget?.payload != null) {
      return NotificationTarget(linkTarget!.route, linkTarget.payload!);
    }

    if (isBookActivity && targetId != null) {
      return NotificationTarget(AppRoutes.bookDetail, targetId);
    }
    if (isPostActivity && targetId != null) {
      return NotificationTarget(AppRoutes.postDetail, targetId);
    }

    return null;
  }

  static String? _idFromLink(String link, List<String> pathNames) {
    final uri = Uri.tryParse(link);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    for (var i = 0; i < segments.length - 1; i++) {
      if (pathNames.contains(segments[i].toLowerCase())) {
        return _clean(Uri.decodeComponent(segments[i + 1]));
      }
    }
    return null;
  }

  static String? _firstValid(List<dynamic> values) {
    for (final value in values) {
      final cleaned = _clean(value);
      if (cleaned != null) return cleaned;
    }
    return null;
  }

  static String? _clean(dynamic value) {
    final text = value?.toString().trim();
    if (text == null ||
        text.isEmpty ||
        text == 'null' ||
        text == 'undefined' ||
        text.contains('/')) {
      return null;
    }
    return text;
  }
}
