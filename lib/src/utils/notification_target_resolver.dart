import '../domain/models/app_notification.dart';
import '../presentation/routing/app_routes.dart';
import 'app_link_helper.dart';

class NotificationTarget {
  const NotificationTarget(
    this.route,
    this.payload, {
    this.commentId,
    this.replyId,
  });

  final String route;
  final String payload;
  final String? commentId;
  final String? replyId;
}

class NotificationTargetResolver {
  static NotificationTarget? resolve(AppNotification notification) {
    final metadata = notification.metadata ?? const <String, dynamic>{};
    final linkTarget = AppLinkHelper.resolve(notification.link);
    final type = notification.type.toLowerCase();

    final bookId = _firstValid([
      metadata['bookId'],
      metadata['book'],
      metadata['contentId'],
      _queryValue(notification.link, 'book'),
      _idFromLink(notification.link, ['book', 'b']),
      linkTarget?.route == AppRoutes.bookDetail ? linkTarget?.payload : null,
    ]);

    final postId = _firstValid([
      metadata['postId'],
      metadata['feedPostId'],
      metadata['feedId'],
      _queryValue(notification.link, 'post'),
      _idFromLink(notification.link, ['post', 'posts', 'feed', 'p']),
      linkTarget?.route == AppRoutes.postDetail ? linkTarget?.payload : null,
    ]);

    final conversationId = _firstValid([
      metadata['conversationId'],
      metadata['id'],
      linkTarget?.route == AppRoutes.conversation ? linkTarget?.payload : null,
    ]);
    final commentId = _firstValid([
      metadata['commentId'],
      metadata['parentCommentId'],
      metadata['targetCommentId'],
      _queryValue(notification.link, 'comment'),
      _queryValue(notification.link, 'commentId'),
    ]);
    final replyId = _firstValid([
      metadata['replyId'],
      metadata['targetReplyId'],
      _queryValue(notification.link, 'reply'),
      _queryValue(notification.link, 'replyId'),
    ]);

    final userId = _firstValid([
      metadata['userId'],
      metadata['authorId'],
      metadata['profileId'],
      notification.actorId,
      _idFromLink(notification.link, ['user', 'u', 'profile']),
      linkTarget?.route == AppRoutes.publicProfile ? linkTarget?.payload : null,
    ]);

    if (linkTarget?.route == AppRoutes.bookDetail &&
        linkTarget?.payload != null) {
      return NotificationTarget(
        AppRoutes.bookDetail,
        linkTarget!.payload!,
        commentId: commentId,
        replyId: replyId,
      );
    }
    if (linkTarget?.route == AppRoutes.postDetail &&
        linkTarget?.payload != null) {
      return NotificationTarget(
        AppRoutes.postDetail,
        linkTarget!.payload!,
        commentId: commentId,
        replyId: replyId,
      );
    }
    if (linkTarget?.route == AppRoutes.conversation &&
        linkTarget?.payload != null) {
      return NotificationTarget(AppRoutes.conversation, linkTarget!.payload!);
    }
    if (linkTarget?.route == AppRoutes.publicProfile &&
        linkTarget?.payload != null) {
      return NotificationTarget(AppRoutes.publicProfile, linkTarget!.payload!);
    }

    if (type == 'collaboration_request' && bookId != null) {
      return NotificationTarget(AppRoutes.collaborationRequest, bookId);
    }

    final targetType = _clean(metadata['targetType'])?.toLowerCase();
    final isBookType = _isBookType(type, targetType);
    final isPostType = _isPostType(type, targetType);
    final isMessageType = type == 'message' || type == 'groupmessage';
    final isProfileType =
        type == 'follow' ||
        type == 'follower' ||
        type == 'following' ||
        type == 'testimonial' ||
        type.contains('follow');
    final hasAmbiguousContentType =
        type == 'comment' ||
        type == 'reply' ||
        type == 'like' ||
        type == 'mention';

    if ((isBookType || (hasAmbiguousContentType && bookId != null)) &&
        bookId != null) {
      return NotificationTarget(
        AppRoutes.bookDetail,
        bookId,
        commentId: commentId,
        replyId: replyId,
      );
    }

    if ((isPostType || (hasAmbiguousContentType && postId != null)) &&
        postId != null) {
      return NotificationTarget(
        AppRoutes.postDetail,
        postId,
        commentId: commentId,
        replyId: replyId,
      );
    }

    if (isMessageType && conversationId != null) {
      return NotificationTarget(AppRoutes.conversation, conversationId);
    }

    if (isProfileType && userId != null) {
      return NotificationTarget(AppRoutes.publicProfile, userId);
    }

    final targetId = _clean(notification.targetId);

    if (linkTarget?.payload != null) {
      return NotificationTarget(linkTarget!.route, linkTarget.payload!);
    }

    if (isBookType && targetId != null) {
      return NotificationTarget(
        AppRoutes.bookDetail,
        targetId,
        commentId: commentId,
        replyId: replyId,
      );
    }
    if (isPostType && targetId != null) {
      return NotificationTarget(
        AppRoutes.postDetail,
        targetId,
        commentId: commentId,
        replyId: replyId,
      );
    }
    if (isMessageType && targetId != null) {
      return NotificationTarget(AppRoutes.conversation, targetId);
    }
    if (isProfileType && targetId != null) {
      return NotificationTarget(AppRoutes.publicProfile, targetId);
    }

    return null;
  }

  static bool _isBookType(String type, String? targetType) {
    return targetType == 'book' ||
        targetType == 'content' ||
        type == 'published' ||
        type == 'chapter_update' ||
        type == 'review' ||
        type == 'book' ||
        type == 'chapter' ||
        type == 'quote' ||
        type.contains('book') ||
        type.contains('chapter') ||
        type.contains('quote') ||
        type.contains('review');
  }

  static bool _isPostType(String type, String? targetType) {
    return targetType == 'post' ||
        targetType == 'feed' ||
        targetType == 'feedpost' ||
        type == 'post' ||
        type == 'feedpost' ||
        type == 'feed_comment' ||
        type == 'feed_reply' ||
        type.contains('post');
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

  static String? _queryValue(String link, String key) {
    final uri = Uri.tryParse(link);
    if (uri == null) return null;
    return _clean(uri.queryParameters[key]);
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
