import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

import '../../domain/models/book.dart';
import '../../domain/models/feed_post.dart';
import '../../localization/generated/app_localizations.dart';
import '../../utils/app_link_helper.dart';
import '../screens/book_detail_screen.dart';
import '../screens/category_books_screen.dart';
import '../screens/conversation_screen.dart';
import '../screens/collaboration_request_screen.dart';
import '../screens/daily_topic_screen.dart';
import '../screens/discovery_screen.dart';
import '../screens/follow_list_screen.dart';
import '../screens/login_screen.dart';
import '../screens/help_screen.dart';
import '../screens/home_banner_screen.dart';
import '../screens/language_settings_screen.dart';
import '../screens/legal_document_screen.dart';
import '../screens/main_navigation_shell.dart';
import '../screens/notifications_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/profile_settings_screen.dart';
import '../screens/public_profile_screen.dart';
import '../screens/reader_screen.dart';
import '../screens/saved_books_screen.dart';
import '../screens/static_info_screen.dart';
import '../screens/writer_dashboard_screen.dart';
import '../screens/writer_pad_screen.dart';
import '../screens/archive_reader_screen.dart';
import 'app_routes.dart';

class ReaderArguments {
  const ReaderArguments({required this.book, this.initialChapterIndex = 0});

  final Book book;
  final int initialChapterIndex;
}

class PublicProfileArguments {
  const PublicProfileArguments({required this.userId});

  final String userId;
}

class BookDetailArguments {
  const BookDetailArguments({
    required this.bookId,
    this.book,
    this.initialReaderChapterIndex,
    this.targetCommentId,
    this.targetReplyId,
  });

  final String bookId;
  final Book? book;
  final int? initialReaderChapterIndex;
  final String? targetCommentId;
  final String? targetReplyId;
}

class ConversationArguments {
  const ConversationArguments({
    required this.conversationId,
    required this.title,
    this.subtitle,
  });

  final String conversationId;
  final String title;
  final String? subtitle;
}

class WriterPadArguments {
  const WriterPadArguments({this.book, this.initialTopic});

  final Book? book;
  final String? initialTopic;
}

class PostDetailArguments {
  const PostDetailArguments({
    required this.postId,
    this.post,
    this.targetCommentId,
    this.targetReplyId,
  });

  final String postId;
  final FeedPost? post;
  final String? targetCommentId;
  final String? targetReplyId;
}

class CollaborationRequestArguments {
  const CollaborationRequestArguments({required this.bookId});

  final String bookId;
}

class AppRouter {
  static MaterialPageRoute _notFound([String? message, String? rawLink]) {
    final webFallbackUrl = _webFallbackUrl(rawLink);
    return MaterialPageRoute(
      builder: (ctx) => StaticInfoScreen(
        title: 'Page Not Found',
        body: message ?? 'The requested page could not be found.',
        actionLabel: webFallbackUrl == null ? null : 'Open in in-app browser',
        actionIcon: Icons.open_in_browser_rounded,
        onAction: webFallbackUrl == null
            ? null
            : () => Navigator.of(ctx).push(
                MaterialPageRoute(
                  builder: (context) => LegalDocumentScreen(
                    title: 'Wreadom',
                    url: webFallbackUrl.toString(),
                  ),
                ),
              ),
      ),
    );
  }

  static Future<void> openExternalPolicy(
    BuildContext context,
    String routeName,
  ) async {
    await Navigator.of(context).pushNamed(routeName);
  }

  static RouteSettings? routeSettingsForAppLink(String rawLink) {
    final resolved = _resolveIncomingName(rawLink);
    if (resolved == null) return null;
    return RouteSettings(
      name: resolved.route,
      arguments: _argumentsForResolvedLink(resolved),
    );
  }

  static Object? _argumentsForResolvedLink(ResolvedAppLink resolved) {
    if (resolved.route == AppRoutes.bookDetail && resolved.payload != null) {
      return BookDetailArguments(
        bookId: resolved.payload!,
        initialReaderChapterIndex: resolved.chapterIndex,
      );
    }
    if (resolved.route == AppRoutes.postDetail && resolved.payload != null) {
      return PostDetailArguments(postId: resolved.payload!);
    }
    if (resolved.route == AppRoutes.publicProfile && resolved.payload != null) {
      return PublicProfileArguments(userId: resolved.payload!);
    }
    if (resolved.route == AppRoutes.conversation && resolved.payload != null) {
      return ConversationArguments(
        conversationId: resolved.payload!,
        title: '',
      );
    }
    if (resolved.route == AppRoutes.collaborationRequest &&
        resolved.payload != null) {
      return CollaborationRequestArguments(bookId: resolved.payload!);
    }
    return resolved.payload;
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    String? name = settings.name;
    Object? arguments = settings.arguments;

    final resolvedIncoming = arguments == null
        ? _resolveIncomingName(name)
        : null;
    final didResolveIncoming = resolvedIncoming != null;
    if (resolvedIncoming != null) {
      name = resolvedIncoming.route;
      arguments = _argumentsForResolvedLink(resolvedIncoming);
    }
    final resolvedArguments = didResolveIncoming
        ? arguments
        : arguments ?? settings.arguments;
    final routeSettings = RouteSettings(
      name: name,
      arguments: resolvedArguments,
    );

    switch (name) {
      case AppRoutes.login:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const LoginScreen(),
        );
      case AppRoutes.main:
      case AppRoutes.root:
        if (firebase_auth.FirebaseAuth.instance.currentUser == null) {
          return MaterialPageRoute(
            settings: routeSettings,
            builder: (_) => const LoginScreen(),
          );
        }
        final initialIndex = resolvedArguments as int? ?? 0;
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => MainNavigationShell(initialIndex: initialIndex),
        );
      case AppRoutes.bookDetail:
        final args = resolvedArguments;
        String bookId;
        Book? book;

        if (args is Book) {
          bookId = args.id;
          book = args;
        } else if (args is BookDetailArguments) {
          bookId = args.bookId;
          book = args.book;
        } else if (args == null ||
            args.toString().trim().isEmpty ||
            args.toString() == 'null') {
          return _notFound('Book details are missing.');
        } else {
          bookId = args.toString();
        }

        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => BookDetailScreen(
            bookId: bookId,
            preloadedBook: book,
            initialReaderChapterIndex: args is BookDetailArguments
                ? args.initialReaderChapterIndex
                : resolvedIncoming
                      ?.chapterIndex, // resolvedIncoming.chapterIndex
            targetCommentId: args is BookDetailArguments
                ? args.targetCommentId
                : null,
            targetReplyId: args is BookDetailArguments
                ? args.targetReplyId
                : null,
          ),
        );
      case AppRoutes.reader:
        final argsValue = resolvedArguments;
        if (argsValue is! ReaderArguments) {
          return _notFound('Reader details are missing.');
        }
        final args = argsValue;
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => ReaderScreen(
            book: args.book,
            initialChapterIndex: args.initialChapterIndex,
          ),
        );
      case AppRoutes.publicProfile:
        final argsValue = resolvedArguments;
        final userId = argsValue is PublicProfileArguments
            ? argsValue.userId
            : argsValue?.toString();
        if (_isMissingRouteValue(userId)) {
          return _notFound('Profile details are missing.');
        }
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => PublicProfileScreen(userId: userId!.trim()),
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const NotificationsScreen(),
        );
      case AppRoutes.conversation:
        final argsValue = resolvedArguments;
        if (argsValue is! ConversationArguments) {
          return _notFound('Conversation details are missing.');
        }
        final args = argsValue;
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => ConversationScreen(
            conversationId: args.conversationId,
            title: args.title,
            subtitle: args.subtitle,
          ),
        );
      case AppRoutes.collaborationRequest:
        final argsValue = resolvedArguments;
        final bookId = argsValue is CollaborationRequestArguments
            ? argsValue.bookId
            : argsValue?.toString();
        if (bookId == null || bookId.trim().isEmpty) {
          return _notFound('Collaboration request details are missing.');
        }
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => CollaborationRequestScreen(bookId: bookId),
        );
      case AppRoutes.writerDashboard:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const WriterDashboardScreen(),
        );
      case AppRoutes.discovery:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const DiscoveryScreen(),
        );
      case AppRoutes.writerPad:
        final argsValue = resolvedArguments;
        if (argsValue != null && argsValue is! WriterPadArguments) {
          return _notFound('Writer details are missing.');
        }
        final args = argsValue as WriterPadArguments?;
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => WriterPadScreen(
            book: args?.book,
            initialTopic: args?.initialTopic,
          ),
        );
      case AppRoutes.postDetail:
        final args = resolvedArguments;
        String postId;
        FeedPost? post;

        if (args is FeedPost) {
          postId = args.id ?? '';
          post = args;
        } else if (args is PostDetailArguments) {
          postId = args.postId;
          post = args.post;
        } else if (args == null ||
            args.toString().trim().isEmpty ||
            args.toString() == 'null') {
          return _notFound('Post details are missing.');
        } else {
          postId = args.toString();
        }

        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => PostDetailScreen(
            postId: postId,
            preloadedPost: post,
            targetCommentId: args is PostDetailArguments
                ? args.targetCommentId
                : null,
            targetReplyId: args is PostDetailArguments
                ? args.targetReplyId
                : null,
          ),
        );
      case AppRoutes.category:
        final args = resolvedArguments;
        final category = args is CategoryBooksArguments
            ? args.category
            : args?.toString();
        if (_isMissingRouteValue(category)) {
          return _notFound('Category details are missing.');
        }
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => CategoryBooksScreen(category: category!.trim()),
        );
      case AppRoutes.savedBooks:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const SavedBooksScreen(),
        );
      case AppRoutes.followList:
        final argsValue = resolvedArguments;
        if (argsValue is! FollowListArguments) {
          return _notFound('Follow list details are missing.');
        }
        final args = argsValue;
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => FollowListScreen(
            userId: args.userId,
            mode: args.mode,
            title: args.title,
          ),
        );
      case AppRoutes.profileSettings:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const ProfileSettingsScreen(),
        );
      case AppRoutes.help:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const HelpScreen(),
        );
      case AppRoutes.languageSettings:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const LanguageSettingsScreen(),
        );
      case AppRoutes.privacy:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const LegalDocumentScreen(
            title: 'Privacy Policy',
            url: AppLinkHelper.privacyPolicyUrl,
          ),
        );
      case AppRoutes.terms:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const LegalDocumentScreen(
            title: 'Terms of Use',
            url: AppLinkHelper.termsUrl,
          ),
        );
      case AppRoutes.certificate:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return StaticInfoScreen(
              title: l10n.certificateUnavailableTitle,
              body: l10n.certificateUnavailableBody,
            );
          },
        );
      case AppRoutes.dailyTopic:
        final args = resolvedArguments;
        String? topicId;
        DailyTopicArguments? topicArgs;
        if (args is DailyTopicArguments) {
          topicArgs = args;
          topicId = args.topicId;
        } else if (args != null && args.toString() != 'null') {
          topicId = args.toString();
        }
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => DailyTopicScreen(
            topicId: topicId,
            preloadedTopic: topicArgs?.topic,
          ),
        );
      case AppRoutes.homeBanner:
        final args = resolvedArguments;
        if (args is! HomeBannerArguments) {
          return _notFound('Banner details are missing.');
        }
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => HomeBannerScreen(banner: args.banner),
        );
      case AppRoutes.competition:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return StaticInfoScreen(
              title: l10n.competitionUnavailableTitle,
              body: l10n.competitionUnavailableBody,
            );
          },
        );
      case AppRoutes.archiveReader:
        final args = resolvedArguments;
        if (args is! Book) {
          return _notFound('Book details are missing for Archive Reader.');
        }
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => ArchiveReaderScreen(book: args),
        );
      default:
        return _notFound(null, name);
    }
  }

  static Uri? _webFallbackUrl(String? rawLink) {
    if (rawLink == null || rawLink.trim().isEmpty) return null;
    final uri = Uri.tryParse(rawLink.trim());
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    if (uri.host != AppLinkHelper.host && uri.host != AppLinkHelper.wwwHost) {
      return null;
    }
    return uri;
  }

  static ResolvedAppLink? _resolveIncomingName(String? name) {
    if (name == null || name.trim().isEmpty) return null;

    final resolved = AppLinkHelper.resolve(name);
    if (resolved != null) return resolved;

    final uri = Uri.tryParse(name);
    if (uri == null) return null;

    if (uri.hasFragment) {
      final fragment = uri.fragment.startsWith('/')
          ? uri.fragment
          : '/${uri.fragment}';
      final fragmentResolved = AppLinkHelper.resolve(fragment);
      if (fragmentResolved != null) return fragmentResolved;
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final localPath = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
      final localResolved = AppLinkHelper.resolve(localPath);
      if (localResolved != null) return localResolved;

      if ((uri.path.isEmpty || uri.path == '/') && !uri.hasQuery) {
        return const ResolvedAppLink(AppRoutes.root, null);
      }
    }

    return null;
  }

  static bool _isMissingRouteValue(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty || trimmed == 'null';
  }
}
