import '../presentation/routing/app_routes.dart';

class AppLinkHelper {
  static const host = 'wreadom.in';
  static const origin = 'https://$host';

  static String book(String bookId) {
    return 'https://wreadom.in/?book=$bookId';
  }

  static String chapter(String bookId, int chapterNumber) {
    return 'https://wreadom.in/?book=$bookId&mode=read&chapter=$chapterNumber';
  }

  static String post(String postId) =>
      '$origin/?page=feed&post=${Uri.encodeComponent(postId)}';
  static String user(String userId) => '$origin/user/$userId';
  static String category(String name) =>
      '$origin/category/${Uri.encodeComponent(name)}';
  static String dailyTopic(String topicId) =>
      '$origin/daily-topic?id=${Uri.encodeComponent(topicId)}';

  static ResolvedAppLink? resolve(String rawLink) {
    if (rawLink.trim().isEmpty) return null;

    final uri = Uri.tryParse(rawLink.trim());
    if (uri == null) return null;

    final isWebLink = uri.scheme == 'http' || uri.scheme == 'https';
    if (isWebLink && uri.host != host) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final queryBookId = uri.queryParameters['book'];
    final queryPostId = uri.queryParameters['post'];
    final queryTopicId = uri.queryParameters['id'];
    final queryPage = uri.queryParameters['page']?.trim().toLowerCase();
    if (segments.isEmpty) {
      if (queryPage == 'writer') {
        return const ResolvedAppLink(AppRoutes.writerDashboard, null);
      }
      if (queryPage == 'search' || queryPage == 'discovery') {
        return const ResolvedAppLink(AppRoutes.discovery, null);
      }
      if (_hasValue(queryBookId)) {
        return ResolvedAppLink(
          AppRoutes.bookDetail,
          queryBookId,
          chapterIndex: _chapterIndexFromQuery(uri),
        );
      }
      if (_hasValue(queryPostId)) {
        return ResolvedAppLink(AppRoutes.postDetail, queryPostId);
      }
      if (_hasValue(queryTopicId) && queryPage == 'daily-topic') {
        return ResolvedAppLink(AppRoutes.dailyTopic, queryTopicId);
      }
      return _resolveMalformedQueryPath(rawLink);
    }

    final type = segments.first.toLowerCase();
    String? id = segments.length > 1 ? Uri.decodeComponent(segments[1]) : null;

    switch (type) {
      case 'book':
      case 'b':
        id ??= queryBookId;
        if (_hasValue(id)) {
          return ResolvedAppLink(AppRoutes.bookDetail, id!);
        }
        break;
      case 'post':
      case 'posts':
      case 'feed':
      case 'p':
        id ??= queryPostId;
        if (_hasValue(id)) {
          return ResolvedAppLink(AppRoutes.postDetail, id!);
        }
        break;
      case 'user':
      case 'u':
      case 'profile':
        if (_hasValue(id)) {
          return ResolvedAppLink(AppRoutes.publicProfile, id!);
        }
        break;
      case 'messages':
      case 'message':
      case 'conversation':
      case 'conversations':
        id ??= uri.queryParameters['conversationId'];
        if (_hasValue(id)) {
          return ResolvedAppLink(AppRoutes.conversation, id!);
        }
        break;
      case 'daily-topic':
        id ??= queryTopicId;
        return ResolvedAppLink(AppRoutes.dailyTopic, _hasValue(id) ? id : null);
      case 'category':
        if (_hasValue(id)) {
          return ResolvedAppLink(AppRoutes.category, id!);
        }
        break;
      case 'discovery':
      case 'search':
        return const ResolvedAppLink(AppRoutes.discovery, null);
      case 'writer':
        return const ResolvedAppLink(AppRoutes.writerDashboard, null);
    }

    final malformed = _resolveMalformedQueryPath(rawLink);
    if (malformed != null) return malformed;

    return null;
  }

  static ResolvedAppLink? _resolveMalformedQueryPath(String rawLink) {
    final match = RegExp(
      r'(?:^|[/?&])page=feed&post=([^&#\s]+)',
    ).firstMatch(rawLink.trim());
    final id = match == null ? null : Uri.decodeComponent(match.group(1)!);
    if (_hasValue(id)) return ResolvedAppLink(AppRoutes.postDetail, id!);
    return null;
  }

  static bool _hasValue(String? value) {
    return value != null &&
        value.trim().isNotEmpty &&
        value != 'null' &&
        value != 'undefined';
  }

  static int? _chapterIndexFromQuery(Uri uri) {
    final mode = uri.queryParameters['mode']?.trim().toLowerCase();
    if (mode != 'read') return null;

    final chapterNumber = int.tryParse(uri.queryParameters['chapter'] ?? '');
    if (chapterNumber == null) return null;
    return chapterNumber <= 1 ? 0 : chapterNumber - 1;
  }
}

class ResolvedAppLink {
  const ResolvedAppLink(this.route, this.payload, {this.chapterIndex});

  final String route;
  final String? payload;
  final int? chapterIndex;
}
