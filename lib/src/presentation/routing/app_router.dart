import 'package:flutter/material.dart';

import '../../domain/models/book.dart';
import '../../domain/models/feed_post.dart';
import '../../utils/app_link_helper.dart';
import '../screens/book_detail_screen.dart';
import '../screens/category_books_screen.dart';
import '../screens/conversation_screen.dart';
import '../screens/daily_topic_screen.dart';
import '../screens/discovery_screen.dart';
import '../screens/follow_list_screen.dart';
import '../screens/login_screen.dart';
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
  const BookDetailArguments({required this.bookId, this.book});

  final String bookId;
  final Book? book;
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
  const WriterPadArguments({this.book});

  final Book? book;
}

class PostDetailArguments {
  const PostDetailArguments({required this.postId, this.post});

  final String postId;
  final FeedPost? post;
}

class AppRouter {
  static MaterialPageRoute _notFound([String? message]) {
    return MaterialPageRoute(
      builder: (_) => StaticInfoScreen(
        title: 'Not Found',
        body: message ?? 'The requested page could not be found.',
      ),
    );
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    String? name = settings.name;
    Object? arguments = settings.arguments;

    if (name != null &&
        (name.startsWith('http://') || name.startsWith('https://'))) {
      final resolved = AppLinkHelper.resolve(name);
      if (resolved != null) {
        name = resolved.route;
        arguments = resolved.payload;
      }
    }

    switch (name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.main:
      case AppRoutes.root:
        final initialIndex = (arguments ?? settings.arguments) as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => MainNavigationShell(initialIndex: initialIndex),
        );
      case AppRoutes.bookDetail:
        final args = arguments ?? settings.arguments;
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
          builder: (_) => BookDetailScreen(bookId: bookId, preloadedBook: book),
        );
      case AppRoutes.reader:
        final argsValue = arguments ?? settings.arguments;
        if (argsValue is! ReaderArguments) {
          return _notFound('Reader details are missing.');
        }
        final args = argsValue;
        return MaterialPageRoute(
          builder: (_) => ReaderScreen(
            book: args.book,
            initialChapterIndex: args.initialChapterIndex,
          ),
        );
      case AppRoutes.publicProfile:
        final argsValue = arguments ?? settings.arguments;
        final args = argsValue is PublicProfileArguments
            ? argsValue
            : PublicProfileArguments(userId: argsValue.toString());
        return MaterialPageRoute(
          builder: (_) => PublicProfileScreen(userId: args.userId),
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case AppRoutes.conversation:
        final argsValue = arguments ?? settings.arguments;
        if (argsValue is! ConversationArguments) {
          return _notFound('Conversation details are missing.');
        }
        final args = argsValue;
        return MaterialPageRoute(
          builder: (_) => ConversationScreen(
            conversationId: args.conversationId,
            title: args.title,
            subtitle: args.subtitle,
          ),
        );
      case AppRoutes.writerDashboard:
        return MaterialPageRoute(builder: (_) => const WriterDashboardScreen());
      case AppRoutes.discovery:
        return MaterialPageRoute(
          settings: RouteSettings(
            name: name,
            arguments: arguments ?? settings.arguments,
          ),
          builder: (_) => const DiscoveryScreen(),
        );
      case AppRoutes.writerPad:
        final argsValue = arguments ?? settings.arguments;
        if (argsValue != null && argsValue is! WriterPadArguments) {
          return _notFound('Writer details are missing.');
        }
        final args = argsValue as WriterPadArguments?;
        return MaterialPageRoute(
          builder: (_) => WriterPadScreen(book: args?.book),
        );
      case AppRoutes.postDetail:
        final args = arguments ?? settings.arguments;
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
          builder: (_) => PostDetailScreen(postId: postId, preloadedPost: post),
        );
      case AppRoutes.category:
        final args = arguments ?? settings.arguments;
        final category = args is CategoryBooksArguments
            ? args.category
            : args.toString();
        return MaterialPageRoute(
          builder: (_) => CategoryBooksScreen(category: category),
        );
      case AppRoutes.savedBooks:
        return MaterialPageRoute(builder: (_) => const SavedBooksScreen());
      case AppRoutes.followList:
        final argsValue = arguments ?? settings.arguments;
        if (argsValue is! FollowListArguments) {
          return _notFound('Follow list details are missing.');
        }
        final args = argsValue;
        return MaterialPageRoute(
          builder: (_) => FollowListScreen(
            userId: args.userId,
            mode: args.mode,
            title: args.title,
          ),
        );
      case AppRoutes.profileSettings:
        return MaterialPageRoute(builder: (_) => const ProfileSettingsScreen());
      case AppRoutes.help:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Help',
            body:
                'Wreadom helps you read, write, connect, and manage your profile from one app. Use the profile settings screen to update privacy and account preferences.',
          ),
        );
      case AppRoutes.privacy:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Privacy Policy',
            body:
                'Your profile, reading, writing, and messaging data are stored using the existing Wreadom Firebase backend. Privacy settings affect profile visibility and follower-only content.',
          ),
        );
      case AppRoutes.terms:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Terms of Service',
            body:
                'Use Wreadom respectfully. Do not abuse messaging, posting, or publishing tools. Moderation and reporting are handled through the shared Wreadom backend.',
          ),
        );
      case AppRoutes.certificate:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Certificate',
            body:
                'Participation certificates are supported in the main Wreadom experience. This Flutter build exposes the route and can be expanded to render generated certificates from backend data.',
          ),
        );
      case AppRoutes.dailyTopic:
        final args = arguments ?? settings.arguments;
        String? topicId;
        DailyTopicArguments? topicArgs;
        if (args is DailyTopicArguments) {
          topicArgs = args;
          topicId = args.topicId;
        } else if (args != null && args.toString() != 'null') {
          topicId = args.toString();
        }
        return MaterialPageRoute(
          builder: (_) => DailyTopicScreen(
            topicId: topicId,
            preloadedTopic: topicArgs?.topic,
          ),
        );
      case AppRoutes.competition:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Competition',
            body:
                'Competitions and winners can be surfaced from the shared Wreadom backend. This route provides the mobile entry point for that experience.',
          ),
        );
      default:
        return _notFound();
    }
  }
}
