import '../presentation/routing/app_routes.dart';

class AppLinkHelper {
  static const host = 'wreadom.in';
  static const origin = 'https://$host';

  static String book(String bookId) => '$origin/book/$bookId';
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
    final queryPostId = uri.queryParameters['post'];
    if (segments.isEmpty) {
      if (_hasValue(queryPostId)) {
        return ResolvedAppLink(AppRoutes.postDetail, queryPostId);
      }
      return _resolveMalformedQueryPath(rawLink);
    }

    final type = segments.first.toLowerCase();
    String? id = segments.length > 1 ? Uri.decodeComponent(segments[1]) : null;

    switch (type) {
      case 'book':
      case 'b':
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
        if (_hasValue(id)) {
          return ResolvedAppLink(AppRoutes.publicProfile, id!);
        }
        break;
      case 'daily-topic':
        id ??= uri.queryParameters['id'];
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
}

class ResolvedAppLink {
  const ResolvedAppLink(this.route, this.payload);

  final String route;
  final String? payload;
}
