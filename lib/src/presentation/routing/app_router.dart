import 'package:flutter/material.dart';

import '../../domain/models/book.dart';
import '../../domain/models/feed_post.dart';
import '../screens/book_detail_screen.dart';
import '../screens/conversation_screen.dart';
import '../screens/discovery_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation_shell.dart';
import '../screens/notifications_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/profile_settings_screen.dart';
import '../screens/public_profile_screen.dart';
import '../screens/reader_screen.dart';
import '../screens/static_info_screen.dart';
import '../screens/writer_dashboard_screen.dart';
import '../screens/writer_pad_screen.dart';
import 'app_routes.dart';

class ReaderArguments {
  const ReaderArguments({
    required this.book,
    this.initialChapterIndex = 0,
  });

  final Book book;
  final int initialChapterIndex;
}

class PublicProfileArguments {
  const PublicProfileArguments({
    required this.userId,
  });

  final String userId;
}

class BookDetailArguments {
  const BookDetailArguments({
    required this.bookId,
    this.book,
  });

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
  const WriterPadArguments({
    this.book,
  });

  final Book? book;
}

class PostDetailArguments {
  const PostDetailArguments({
    required this.postId,
    this.post,
  });

  final String postId;
  final FeedPost? post;
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.main:
      case AppRoutes.root:
        final initialIndex = settings.arguments as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => MainNavigationShell(initialIndex: initialIndex),
        );
      case AppRoutes.bookDetail:
        final args = settings.arguments;
        String bookId;
        Book? book;

        if (args is Book) {
          bookId = args.id;
          book = args;
        } else if (args is BookDetailArguments) {
          bookId = args.bookId;
          book = args.book;
        } else {
          bookId = args.toString();
        }

        return MaterialPageRoute(
          builder: (_) => BookDetailScreen(
            bookId: bookId,
            preloadedBook: book,
          ),
        );
      case AppRoutes.reader:
        final args = settings.arguments as ReaderArguments;
        return MaterialPageRoute(
          builder: (_) => ReaderScreen(
            book: args.book,
            initialChapterIndex: args.initialChapterIndex,
          ),
        );
      case AppRoutes.publicProfile:
        final args = settings.arguments as PublicProfileArguments;
        return MaterialPageRoute(
          builder: (_) => PublicProfileScreen(userId: args.userId),
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case AppRoutes.conversation:
        final args = settings.arguments as ConversationArguments;
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
        return MaterialPageRoute(builder: (_) => const DiscoveryScreen());
      case AppRoutes.writerPad:
        final args = settings.arguments as WriterPadArguments?;
        return MaterialPageRoute(
          builder: (_) => WriterPadScreen(book: args?.book),
        );
      case AppRoutes.postDetail:
        final args = settings.arguments;
        String postId;
        FeedPost? post;

        if (args is FeedPost) {
          postId = args.id ?? '';
          post = args;
        } else if (args is PostDetailArguments) {
          postId = args.postId;
          post = args.post;
        } else {
          postId = args.toString();
        }

        return MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            postId: postId,
            preloadedPost: post,
          ),
        );
      case AppRoutes.profileSettings:
        return MaterialPageRoute(builder: (_) => const ProfileSettingsScreen());
      case AppRoutes.help:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Help',
            body:
                'Librebook helps you read, write, connect, and manage your profile from one app. Use the profile settings screen to update privacy and account preferences.',
          ),
        );
      case AppRoutes.privacy:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Privacy Policy',
            body:
                'Your profile, reading, writing, and messaging data are stored using the existing Librebook Firebase backend. Privacy settings affect profile visibility and follower-only content.',
          ),
        );
      case AppRoutes.terms:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Terms of Service',
            body:
                'Use Librebook respectfully. Do not abuse messaging, posting, or publishing tools. Moderation and reporting are handled through the shared Librebook backend.',
          ),
        );
      case AppRoutes.certificate:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Certificate',
            body:
                'Participation certificates are supported in the main Librebook experience. This Flutter build now exposes the route and can be expanded to render generated certificates from backend data.',
          ),
        );
      case AppRoutes.dailyTopic:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Daily Topic',
            body:
                'Daily topics can be surfaced from shared homepage metadata. This screen is now reachable and ready for backend-driven topic content.',
          ),
        );
      case AppRoutes.competition:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Competition',
            body:
                'Competitions and winners can be surfaced from the shared Librebook backend. This route provides the mobile entry point for that experience.',
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Not Found',
            body: 'The requested page could not be found.',
          ),
        );
    }
  }
}
