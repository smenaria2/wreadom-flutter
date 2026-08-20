import '../presentation/routing/app_routes.dart';

class AppLinkHelper {
  static const host = 'wreadom.in';
  static const wwwHost = 'www.wreadom.in';
  static const origin = 'https://$host';
  static const privacyPolicyUrl = '$origin/privacy';
  static const termsUrl = '$origin/terms';

  static String createPost({String? text}) {
    final normalized = text?.trim();
    if (normalized == null || normalized.isEmpty) return '$origin/create-post';
    return Uri.parse(
      '$origin/create-post',
    ).replace(queryParameters: {'text': normalized}).toString();
  }

  static String help() => '$origin/help';
  static String questionAnswers(
    String bookId,
    String leafId, {
    String? question,
  }) {
    final queryParameters = <String, String>{};
    if (_hasValue(bookId) && _hasValue(leafId)) {
      queryParameters['book'] = bookId.trim();
      queryParameters['leaf'] = leafId.trim();
    } else if (_hasValue(question)) {
      queryParameters['question'] = question!.trim();
    }
    return Uri.parse('$origin/questions')
        .replace(
          queryParameters: queryParameters.isEmpty ? null : queryParameters,
        )
        .toString();
  }

  static String search() => '$origin/search';
  static String writer() => '$origin/writer';
  static String savedBooks() => '$origin/saved-books';
  static String notifications() => '$origin/notifications';
  static String profileSettings() => '$origin/settings/profile';
  static String languageSettings() => '$origin/settings/language';
  static String leaderboard() => '$origin/leaderboard';

  static String _entityLink(
    List<String> pathSegments, [
    Map<String, String>? query,
  ]) {
    final normalizedSegments = pathSegments
        .map((value) => value.trim())
        .toList();
    if (normalizedSegments.any((value) => !_hasValue(value))) {
      throw ArgumentError.value(
        pathSegments,
        'pathSegments',
        'Entity IDs cannot be empty',
      );
    }
    final normalizedQuery = query == null
        ? null
        : Map<String, String>.fromEntries(
            query.entries.where((entry) => _hasValue(entry.value)),
          );
    return Uri(
      scheme: 'https',
      host: host,
      pathSegments: normalizedSegments,
      queryParameters: normalizedQuery == null || normalizedQuery.isEmpty
          ? null
          : normalizedQuery,
    ).toString();
  }

  static String book(
    String bookId, {
    String? mode,
    int? chapter,
    String? leaf,
    String? comment,
    String? reply,
  }) => _entityLink(
    ['book', bookId],
    {
      if (_hasValue(mode)) 'mode': mode!.trim(),
      if (chapter != null) 'chapter': chapter.toString(),
      if (_hasValue(leaf)) 'leaf': leaf!.trim(),
      if (_hasValue(comment)) 'comment': comment!.trim(),
      if (_hasValue(reply)) 'reply': reply!.trim(),
    },
  );

  static String chapter(String bookId, int chapterNumber) =>
      book(bookId, mode: 'read', chapter: chapterNumber);

  static String post(
    String postId, {
    String? story,
    String? comment,
    String? reply,
  }) => _entityLink(
    ['post', postId],
    {
      if (_hasValue(story)) 'story': story!.trim(),
      if (_hasValue(comment)) 'comment': comment!.trim(),
      if (_hasValue(reply)) 'reply': reply!.trim(),
    },
  );
  static String user(String userId) => _entityLink(['profile', userId]);
  static String collection(String collectionId) =>
      _entityLink(['collection', collectionId]);
  static String category(String name) => _entityLink(['category', name]);
  static String dailyTopic(String topicId) =>
      _entityLink(['daily-topic', topicId]);

  static String? _safeDecode(String? value) {
    if (value == null) return null;
    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return value;
    }
  }

  static String _normalizeRawLink(String rawLink) {
    final trimmed = rawLink.trim();
    if (trimmed.isEmpty) return trimmed;
    // If the link does not have a '?' query delimiter, but has '&' attached to a path segment (e.g. /book/123&comment=456)
    if (!trimmed.contains('?') && trimmed.contains('&')) {
      final firstAmp = trimmed.indexOf('&');
      final schemeIndex = trimmed.indexOf('://');
      final firstSlashAfterScheme = schemeIndex != -1
          ? trimmed.indexOf('/', schemeIndex + 3)
          : trimmed.indexOf('/');
      if (firstSlashAfterScheme != -1 && firstAmp > firstSlashAfterScheme) {
        return '${trimmed.substring(0, firstAmp)}?${trimmed.substring(firstAmp + 1)}';
      }
    }
    return trimmed;
  }

  static ResolvedAppLink? resolve(String rawLink) {
    if (rawLink.trim().isEmpty) return null;

    final normalized = _normalizeRawLink(rawLink);
    final uri = Uri.tryParse(normalized);
    if (uri == null) return null;

    try {
      final isWebLink = uri.scheme == 'http' || uri.scheme == 'https';
      if (isWebLink && uri.host != host && uri.host != wwwHost) return null;

      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      final queryBookId = uri.queryParameters['book'];
      final queryPostId = uri.queryParameters['post'];
      final queryUserId = uri.queryParameters['user'];
      final queryTopicId = uri.queryParameters['id'];
      final queryLeafId = uri.queryParameters['leaf'];
      final queryQuestion = uri.queryParameters['question'];
      final queryStoryId = uri.queryParameters['story'];
      final queryCommentId =
          uri.queryParameters['comment'] ?? uri.queryParameters['commentId'];
      final queryReplyId =
          uri.queryParameters['reply'] ?? uri.queryParameters['replyId'];
      final queryPage = uri.queryParameters['page']?.trim().toLowerCase();
      final queryMode = uri.queryParameters['mode']?.trim().toLowerCase();
      if (segments.isEmpty) {
        if (queryPage == 'writer') {
          return const ResolvedAppLink(AppRoutes.writerDashboard, null);
        }
        if (queryPage == 'search' || queryPage == 'discovery') {
          return const ResolvedAppLink(AppRoutes.discovery, null);
        }
        if (_hasValue(queryBookId)) {
          if (queryMode == 'pdf') {
            return ResolvedAppLink(AppRoutes.archiveReader, queryBookId!);
          }
          return ResolvedAppLink(
            AppRoutes.bookDetail,
            queryBookId,
            chapterIndex: _chapterIndexFromQuery(uri),
            leafId: _hasValue(queryLeafId) ? queryLeafId : null,
            commentId: _hasValue(queryCommentId) ? queryCommentId : null,
            replyId: _hasValue(queryReplyId) ? queryReplyId : null,
          );
        }
        if (_hasValue(queryPostId)) {
          return ResolvedAppLink(
            AppRoutes.postDetail,
            queryPostId,
            storyId: _hasValue(queryStoryId) ? queryStoryId : null,
            commentId: _hasValue(queryCommentId) ? queryCommentId : null,
            replyId: _hasValue(queryReplyId) ? queryReplyId : null,
          );
        }
        if (_hasValue(queryUserId)) {
          return ResolvedAppLink(AppRoutes.publicProfile, queryUserId!);
        }
        if (_hasValue(queryTopicId) && queryPage == 'collection-detail') {
          return ResolvedAppLink(AppRoutes.collectionDetail, queryTopicId!);
        }
        if (_hasValue(queryTopicId) && queryPage == 'daily-topic') {
          return ResolvedAppLink(AppRoutes.dailyTopic, queryTopicId);
        }
        return _resolveMalformedQueryPath(rawLink);
      }

      final type = segments.first.toLowerCase();
      String? id = segments.length > 1 ? _safeDecode(segments[1]) : null;
      if (id != null && id.contains('&')) {
        id = id.split('&').first;
      }

      switch (type) {
        case 'book':
        case 'b':
          id ??= queryBookId ?? queryTopicId;
          if (_hasValue(id)) {
            if (queryMode == 'pdf') {
              return ResolvedAppLink(AppRoutes.archiveReader, id!);
            }
            return ResolvedAppLink(
              AppRoutes.bookDetail,
              id!,
              chapterIndex: _chapterIndexFromQuery(uri),
              leafId: _hasValue(queryLeafId) ? queryLeafId : null,
              commentId: _hasValue(queryCommentId) ? queryCommentId : null,
              replyId: _hasValue(queryReplyId) ? queryReplyId : null,
            );
          }
          break;
        case 'post':
        case 'posts':
        case 'feed':
        case 'p':
          id ??= queryPostId;
          if (_hasValue(id)) {
            return ResolvedAppLink(
              AppRoutes.postDetail,
              id!,
              storyId: _hasValue(queryStoryId) ? queryStoryId : null,
              commentId: _hasValue(queryCommentId) ? queryCommentId : null,
              replyId: _hasValue(queryReplyId) ? queryReplyId : null,
            );
          }
          break;
        case 'collection':
        case 'collections':
          if (_hasValue(id)) {
            return ResolvedAppLink(AppRoutes.collectionDetail, id!);
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
        case 'daily-topics':
        case 'agaaz-topic':
        case 'agaaz-topics':
          id ??= queryTopicId;
          return ResolvedAppLink(
            AppRoutes.dailyTopic,
            _hasValue(id) ? id : null,
          );
        case 'banner':
        case 'banners':
          id ??= uri.queryParameters['id'];
          return ResolvedAppLink(
            AppRoutes.homeBanner,
            _hasValue(id) ? id : null,
          );
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
        case 'create-post':
        case 'new-post':
        case 'compose':
          final text = uri.queryParameters['text'];
          return ResolvedAppLink(
            AppRoutes.createPost,
            _hasValue(text) ? text!.trim() : null,
          );
        case 'help':
        case 'guide':
          return const ResolvedAppLink(AppRoutes.help, null);
        case 'question':
        case 'questions':
        case 'answer':
        case 'answers':
        case 'question-answers':
          final bookId = queryBookId ?? uri.queryParameters['bookId'];
          final leafId = queryLeafId ?? uri.queryParameters['leafId'];
          final question = queryQuestion ??
              uri.queryParameters['questionId'] ??
              uri.queryParameters['q'];
          if (_hasValue(bookId) && _hasValue(leafId)) {
            return ResolvedAppLink(
              AppRoutes.questionAnswers,
              bookId!.trim(),
              leafId: leafId!.trim(),
              question: _hasValue(question) ? question!.trim() : null,
            );
          }
          if (_hasValue(question)) {
            return ResolvedAppLink(
              AppRoutes.questionAnswers,
              _hasValue(bookId) ? bookId!.trim() : null,
              leafId: _hasValue(leafId) ? leafId!.trim() : null,
              question: question!.trim(),
            );
          }
          if (_hasValue(id)) {
            return ResolvedAppLink(
              AppRoutes.questionAnswers,
              id!.trim(),
              leafId: _hasValue(leafId) ? leafId!.trim() : null,
            );
          }
          break;
        case 'saved-books':
          return const ResolvedAppLink(AppRoutes.savedBooks, null);
        case 'notifications':
          return const ResolvedAppLink(AppRoutes.notifications, null);
        case 'settings':
          final section = id?.trim().toLowerCase();
          if (section == 'profile') {
            return const ResolvedAppLink(AppRoutes.profileSettings, null);
          }
          if (section == 'language') {
            return const ResolvedAppLink(AppRoutes.languageSettings, null);
          }
          break;
        case 'leaderboard':
          return const ResolvedAppLink(AppRoutes.leaderboard, null);
        case 'privacy':
        case 'privacy-policy':
          return const ResolvedAppLink(AppRoutes.privacy, null);
        case 'terms':
        case 'terms-of-use':
          return const ResolvedAppLink(AppRoutes.terms, null);
      }

      final malformed = _resolveMalformedQueryPath(rawLink);
      if (malformed != null) return malformed;
    } catch (_) {
      // Return null or fallback if accessing queryParameters throws due to percent-encoding
    }

    return null;
  }

  static ResolvedAppLink? _resolveMalformedQueryPath(String rawLink) {
    try {
      final match = RegExp(
        r'(?:^|[/?&])page=feed&post=([^&#\s]+)',
      ).firstMatch(rawLink.trim());
      final id = match == null ? null : _safeDecode(match.group(1));
      if (_hasValue(id)) return ResolvedAppLink(AppRoutes.postDetail, id!);
    } catch (_) {}
    return null;
  }

  static bool _hasValue(String? value) {
    return value != null &&
        value.trim().isNotEmpty &&
        value.trim().toLowerCase() != 'undefined' &&
        value.trim().toLowerCase() != 'null';
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
  const ResolvedAppLink(
    this.route,
    this.payload, {
    this.chapterIndex,
    this.leafId,
    this.question,
    this.storyId,
    this.commentId,
    this.replyId,
  });

  final String route;
  final String? payload;
  final int? chapterIndex;
  final String? leafId;
  final String? question;
  final String? storyId;
  final String? commentId;
  final String? replyId;
}
