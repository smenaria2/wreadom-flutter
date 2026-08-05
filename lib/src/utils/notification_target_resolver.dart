import '../domain/models/app_notification.dart';
import '../presentation/routing/app_routes.dart';
import 'app_link_helper.dart';

class NotificationTarget {
  const NotificationTarget(
    this.route,
    this.payload, {
    this.commentId,
    this.replyId,
    this.chapterIndex,
    this.leafId,
    this.question,
  });

  final String route;
  final String payload;
  final String? commentId;
  final String? replyId;
  final int? chapterIndex;
  final String? leafId;
  final String? question;
}

class NotificationTargetResolver {
  static Uri? externalUri(AppNotification notification) {
    final metadata = notification.metadata ?? const <String, dynamic>{};
    final targetType = _clean(metadata['targetType'])?.toLowerCase();
    if (targetType != 'custom') return null;

    final rawLink = notification.link.trim();
    final uri = Uri.tryParse(rawLink);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        AppLinkHelper.resolve(rawLink) != null) {
      return null;
    }
    return uri;
  }

  static NotificationTarget? resolve(AppNotification notification) {
    final metadata = notification.metadata ?? const <String, dynamic>{};
    final linkTarget = AppLinkHelper.resolve(notification.link);
    final type = notification.type.toLowerCase();
    final targetType = _clean(metadata['targetType'])?.toLowerCase();

    if (targetType == 'custom' && linkTarget == null) return null;

    if (targetType == 'daily_topic' ||
        linkTarget?.route == AppRoutes.dailyTopic) {
      final topicId = _firstValid([
        metadata['topicId'],
        linkTarget?.payload,
        _queryValue(notification.link, 'id'),
        notification.targetId,
      ]);
      return NotificationTarget(AppRoutes.dailyTopic, topicId ?? '');
    }

    final isBookLink =
        linkTarget?.route == AppRoutes.bookDetail ||
        _idFromLink(notification.link, ['book', 'b']) != null;

    final bookId = _firstValid([
      metadata['bookId'],
      metadata['book'],
      metadata['contentId'],
      _queryValue(notification.link, 'book'),
      if (isBookLink) _queryValue(notification.link, 'id'),
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
    final leafId = _firstValid([
      metadata['leafId'],
      _queryValue(notification.link, 'leaf'),
      linkTarget?.route == AppRoutes.bookDetail ? linkTarget?.leafId : null,
    ]);

    final userId = _firstValid([
      metadata['userId'],
      metadata['authorId'],
      metadata['profileId'],
      _idFromLink(notification.link, ['user', 'u', 'profile']),
      linkTarget?.route == AppRoutes.publicProfile ? linkTarget?.payload : null,
      notification.actorId,
    ]);

    if (linkTarget?.route == AppRoutes.bookDetail &&
        linkTarget?.payload != null) {
      return NotificationTarget(
        AppRoutes.bookDetail,
        linkTarget!.payload!,
        commentId: commentId,
        replyId: replyId,
        chapterIndex: linkTarget.chapterIndex,
        leafId: leafId,
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
    if (linkTarget?.route == AppRoutes.questionAnswers) {
      return NotificationTarget(
        AppRoutes.questionAnswers,
        linkTarget?.payload ?? bookId ?? '',
        leafId: leafId ?? linkTarget?.leafId,
        question: linkTarget?.question ??
            _firstValid([
              metadata['question'],
              metadata['questionText'],
              _queryValue(notification.link, 'question'),
            ]),
      );
    }
    if (targetType == 'question' ||
        targetType == 'questions' ||
        type == 'question' ||
        type == 'questions') {
      final questionText = _firstValid([
        metadata['question'],
        metadata['questionText'],
        metadata['query'],
        _queryValue(notification.link, 'question'),
        linkTarget?.question,
      ]);
      return NotificationTarget(
        AppRoutes.questionAnswers,
        bookId ?? linkTarget?.payload ?? '',
        leafId: leafId ?? linkTarget?.leafId,
        question: questionText,
      );
    }
    if (linkTarget?.route == AppRoutes.archiveReader &&
        linkTarget?.payload != null) {
      return NotificationTarget(AppRoutes.archiveReader, linkTarget!.payload!);
    }
    if (targetType == 'archive' ||
        targetType == 'archive_book' ||
        targetType == 'internet_archive' ||
        notification.link.contains('archive.org/')) {
      final archiveId = _firstValid([
        metadata['archiveId'],
        metadata['bookId'],
        metadata['id'],
        linkTarget?.payload,
        _queryValue(notification.link, 'id'),
        _idFromLink(notification.link, ['details', 'embed']),
        notification.targetId,
      ]);
      if (archiveId != null) {
        return NotificationTarget(AppRoutes.archiveReader, archiveId);
      }
    }

    if (type == 'collaboration_request' && bookId != null) {
      return NotificationTarget(AppRoutes.collaborationRequest, bookId);
    }

    final isBookType = _isBookType(type, targetType);
    final isPostType = _isPostType(type, targetType);
    final isMessageType = type == 'message' || type == 'groupmessage';
    final isFollowType =
        type == 'follow' ||
        type == 'follower' ||
        type == 'following' ||
        type.contains('follow');
    final isProfileType =
        targetType == 'profile' ||
        targetType == 'user' ||
        type == 'testimonial' ||
        isFollowType;
    final hasAmbiguousContentType =
        type == 'comment' ||
        type == 'reply' ||
        type == 'like' ||
        type == 'mention';

    if (hasAmbiguousContentType) {
      if (postId != null &&
          (metadata['postId'] != null ||
              isPostType ||
              linkTarget?.route == AppRoutes.postDetail ||
              metadata['bookId'] == null)) {
        return NotificationTarget(
          AppRoutes.postDetail,
          postId,
          commentId: commentId,
          replyId: replyId,
        );
      }
      if (bookId != null) {
        return NotificationTarget(
          AppRoutes.bookDetail,
          bookId,
          commentId: commentId,
          replyId: replyId,
          chapterIndex: linkTarget?.route == AppRoutes.bookDetail
              ? linkTarget?.chapterIndex
              : null,
          leafId: leafId,
        );
      }
    }

    if (isBookType && bookId != null) {
      return NotificationTarget(
        AppRoutes.bookDetail,
        bookId,
        commentId: commentId,
        replyId: replyId,
        chapterIndex: linkTarget?.route == AppRoutes.bookDetail
            ? linkTarget?.chapterIndex
            : null,
        leafId: leafId,
      );
    }

    if (isPostType && postId != null) {
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

    if (isFollowType && notification.actorId.isNotEmpty) {
      return NotificationTarget(AppRoutes.publicProfile, notification.actorId);
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
        chapterIndex: linkTarget?.route == AppRoutes.bookDetail
            ? linkTarget?.chapterIndex
            : null,
        leafId: leafId,
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
    if (isFollowType && notification.actorId.isNotEmpty) {
      return NotificationTarget(AppRoutes.publicProfile, notification.actorId);
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
        type == 'new_creation' ||
        type == 'newcreation' ||
        type == 'chapter_update' ||
        type == 'leaf_update' ||
        type == 'review' ||
        type == 'book' ||
        type == 'chapter' ||
        type == 'quote' ||
        type == 'collaboration_removed' ||
        type.contains('book') ||
        type.contains('creation') ||
        type.contains('chapter') ||
        type.contains('quote') ||
        type.contains('review') ||
        type.contains('collaboration');
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
    try {
      final segments = uri.pathSegments;
      for (var i = 0; i < segments.length - 1; i++) {
        if (pathNames.contains(segments[i].toLowerCase())) {
          String val = segments[i + 1];
          try {
            val = Uri.decodeComponent(val);
          } catch (_) {}
          return _clean(val);
        }
      }
    } catch (_) {}
    return null;
  }

  static String? _queryValue(String link, String key) {
    final uri = Uri.tryParse(link);
    if (uri == null) return null;
    try {
      return _clean(uri.queryParameters[key]);
    } catch (_) {}
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
