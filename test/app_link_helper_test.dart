import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';
import 'package:librebook_flutter/src/utils/app_link_helper.dart';

void main() {
  group('AppLinkHelper', () {
    test('exposes canonical web policy URLs', () {
      expect(AppLinkHelper.privacyPolicyUrl, 'https://wreadom.in/privacy');
      expect(AppLinkHelper.termsUrl, 'https://wreadom.in/terms');
    });

    test('builds canonical web-compatible post share URL', () {
      expect(
        AppLinkHelper.post('post 123'),
        'https://wreadom.in/post/post%20123',
      );
    });

    test('builds canonical entity share URLs', () {
      expect(
        AppLinkHelper.book('book 123'),
        'https://wreadom.in/book/book%20123',
      );
      expect(
        AppLinkHelper.user('user 123'),
        'https://wreadom.in/profile/user%20123',
      );
      expect(
        AppLinkHelper.dailyTopic('topic 123'),
        'https://wreadom.in/daily-topic/topic%20123',
      );
      expect(
        AppLinkHelper.chapter('book 123', 3),
        'https://wreadom.in/book/book%20123?mode=read&chapter=3',
      );
    });

    test('builds canonical qualified links and rejects missing IDs', () {
      expect(
        AppLinkHelper.book(
          'book 1',
          mode: 'read',
          chapter: 4,
          leaf: 'leaf/2',
          comment: 'comment 3',
          reply: 'reply 4',
        ),
        'https://wreadom.in/book/book%201?mode=read&chapter=4&leaf=leaf%2F2&comment=comment+3&reply=reply+4',
      );
      expect(
        AppLinkHelper.post(
          'post 1',
          story: 'story/2',
          comment: 'comment 3',
          reply: 'reply 4',
        ),
        'https://wreadom.in/post/post%201?story=story%2F2&comment=comment+3&reply=reply+4',
      );
      expect(() => AppLinkHelper.book('  '), throwsArgumentError);
      expect(() => AppLinkHelper.post('undefined'), throwsArgumentError);
      expect(() => AppLinkHelper.user('null'), throwsArgumentError);
    });

    test('retains canonical book and post navigation qualifiers', () {
      final book = AppLinkHelper.resolve(
        '/book/book-1?mode=read&chapter=3&leaf=leaf-2&comment=comment-3&reply=reply-4',
      );
      final post = AppLinkHelper.resolve(
        '/post/post-1?story=story-2&comment=comment-3&reply=reply-4',
      );

      expect(book?.chapterIndex, 2);
      expect(book?.leafId, 'leaf-2');
      expect(book?.commentId, 'comment-3');
      expect(book?.replyId, 'reply-4');
      expect(post?.storyId, 'story-2');
      expect(post?.commentId, 'comment-3');
      expect(post?.replyId, 'reply-4');
    });
    test('resolves canonical feed post query URL', () {
      final resolved = AppLinkHelper.resolve(
        'https://wreadom.in/?page=feed&post=abc123',
      );

      expect(resolved?.route, AppRoutes.postDetail);
      expect(resolved?.payload, 'abc123');
    });

    test('resolves Flutter web relative feed post route', () {
      final resolved = AppLinkHelper.resolve('/?page=feed&post=abc123');

      expect(resolved?.route, AppRoutes.postDetail);
      expect(resolved?.payload, 'abc123');
    });

    test('resolves canonical book query URL', () {
      final resolved = AppLinkHelper.resolve(
        'https://wreadom.in/?book=book123',
      );

      expect(resolved?.route, AppRoutes.bookDetail);
      expect(resolved?.payload, 'book123');
      expect(resolved?.chapterIndex, isNull);
    });

    test('resolves backend book path id query URL', () {
      final resolved = AppLinkHelper.resolve('/book?id=book123');

      expect(resolved?.route, AppRoutes.bookDetail);
      expect(resolved?.payload, 'book123');
    });

    test('resolves book leaf query URLs', () {
      final canonical = AppLinkHelper.resolve(
        'https://wreadom.in/?book=book123&leaf=leaf9',
      );
      final backend = AppLinkHelper.resolve('/book?id=book123&leaf=leaf9');

      expect(canonical?.route, AppRoutes.bookDetail);
      expect(canonical?.payload, 'book123');
      expect(canonical?.leafId, 'leaf9');
      expect(backend?.route, AppRoutes.bookDetail);
      expect(backend?.payload, 'book123');
      expect(backend?.leafId, 'leaf9');
    });

    test('resolves shared chapter query URL with zero based index', () {
      final resolved = AppLinkHelper.resolve(
        'https://wreadom.in/?book=book123&mode=read&chapter=3',
      );

      expect(resolved?.route, AppRoutes.bookDetail);
      expect(resolved?.payload, 'book123');
      expect(resolved?.chapterIndex, 2);
    });

    test('resolves relative book and post paths from Flutter web', () {
      final book = AppLinkHelper.resolve('/book/book123');
      final post = AppLinkHelper.resolve('/posts/post123');

      expect(book?.route, AppRoutes.bookDetail);
      expect(book?.payload, 'book123');
      expect(post?.route, AppRoutes.postDetail);
      expect(post?.payload, 'post123');
    });

    test('resolves feed path query URL', () {
      final resolved = AppLinkHelper.resolve(
        'https://wreadom.in/feed?post=abc123',
      );

      expect(resolved?.route, AppRoutes.postDetail);
      expect(resolved?.payload, 'abc123');
    });

    test('resolves legacy post path URLs', () {
      for (final link in [
        'https://wreadom.in/posts/abc123',
        'https://wreadom.in/post/abc123',
        'https://wreadom.in/p/abc123',
      ]) {
        final resolved = AppLinkHelper.resolve(link);

        expect(resolved?.route, AppRoutes.postDetail);
        expect(resolved?.payload, 'abc123');
      }
    });

    test('resolves malformed page feed path mentioned by users', () {
      final resolved = AppLinkHelper.resolve(
        'https://wreadom.in/page=feed&post=abc123',
      );

      expect(resolved?.route, AppRoutes.postDetail);
      expect(resolved?.payload, 'abc123');
    });

    test('rejects external hosts', () {
      final resolved = AppLinkHelper.resolve(
        'https://example.com/book/book123',
      );

      expect(resolved, isNull);
    });

    test('rejects missing or empty ids', () {
      for (final link in [
        'https://wreadom.in/book',
        'https://wreadom.in/book/',
        'https://wreadom.in/user/null',
        'https://wreadom.in/post/undefined',
        'https://wreadom.in/category/%20',
      ]) {
        expect(AppLinkHelper.resolve(link), isNull);
      }
    });

    test('resolves discovery and writer paths without payloads', () {
      final discovery = AppLinkHelper.resolve('/search');
      final writer = AppLinkHelper.resolve('/writer');
      final writerQuery = AppLinkHelper.resolve(
        'https://wreadom.in/?page=writer',
      );

      expect(discovery?.route, AppRoutes.discovery);
      expect(discovery?.payload, isNull);
      expect(writer?.route, AppRoutes.writerDashboard);
      expect(writer?.payload, isNull);
      expect(writerQuery?.route, AppRoutes.writerDashboard);
      expect(writerQuery?.payload, isNull);
    });

    test('resolves canonical legal policy paths', () {
      final privacy = AppLinkHelper.resolve('https://wreadom.in/privacy');
      final terms = AppLinkHelper.resolve('https://wreadom.in/terms');
      final wwwTerms = AppLinkHelper.resolve('https://www.wreadom.in/terms');

      expect(privacy?.route, AppRoutes.privacy);
      expect(privacy?.payload, isNull);
      expect(terms?.route, AppRoutes.terms);
      expect(terms?.payload, isNull);
      expect(wwwTerms?.route, AppRoutes.terms);
    });

    test('builds canonical app page and function URLs', () {
      expect(AppLinkHelper.createPost(), 'https://wreadom.in/create-post');
      expect(AppLinkHelper.help(), 'https://wreadom.in/help');
      expect(AppLinkHelper.search(), 'https://wreadom.in/search');
      expect(AppLinkHelper.writer(), 'https://wreadom.in/writer');
      expect(AppLinkHelper.savedBooks(), 'https://wreadom.in/saved-books');
      expect(AppLinkHelper.notifications(), 'https://wreadom.in/notifications');
      expect(
        AppLinkHelper.profileSettings(),
        'https://wreadom.in/settings/profile',
      );
      expect(
        AppLinkHelper.languageSettings(),
        'https://wreadom.in/settings/language',
      );
      expect(AppLinkHelper.leaderboard(), 'https://wreadom.in/leaderboard');
      expect(
        AppLinkHelper.questionAnswers('book 1', 'leaf/2'),
        'https://wreadom.in/questions?book=book+1&leaf=leaf%2F2',
      );
      expect(
        AppLinkHelper.questionAnswers('', '', question: 'How to write?'),
        'https://wreadom.in/questions?question=How+to+write%3F',
      );
    });

    test('builds and resolves Unicode prefilled create-post URLs', () {
      final link = AppLinkHelper.createPost(
        text:
            ' \u{0906}\u{091C} \u{0915}\u{0940} \u{0915}\u{0939}\u{093E}\u{0928}\u{0940} ',
      );
      final resolved = AppLinkHelper.resolve(link);

      expect(resolved?.route, AppRoutes.createPost);
      expect(
        resolved?.payload,
        '\u{0906}\u{091C} \u{0915}\u{0940} \u{0915}\u{0939}\u{093E}\u{0928}\u{0940}',
      );
      expect(AppLinkHelper.createPost(text: '   '), AppLinkHelper.createPost());
    });

    test('resolves create-post and help compatibility aliases', () {
      for (final path in ['/create-post', '/new-post', '/compose']) {
        expect(AppLinkHelper.resolve(path)?.route, AppRoutes.createPost);
      }
      for (final path in ['/help', '/guide']) {
        expect(AppLinkHelper.resolve(path)?.route, AppRoutes.help);
      }
    });

    test('resolves safe parameterless app pages on both hosts', () {
      final routes = <String, String>{
        '/saved-books': AppRoutes.savedBooks,
        '/notifications': AppRoutes.notifications,
        '/settings/profile': AppRoutes.profileSettings,
        '/settings/language': AppRoutes.languageSettings,
        '/leaderboard': AppRoutes.leaderboard,
      };
      for (final entry in routes.entries) {
        expect(
          AppLinkHelper.resolve('https://wreadom.in${entry.key}')?.route,
          entry.value,
        );
        expect(
          AppLinkHelper.resolve('https://www.wreadom.in${entry.key}')?.route,
          entry.value,
        );
      }
    });

    test('resolves question IDs and rejects incomplete question links', () {
      for (final path in ['/questions', '/answers']) {
        final resolved = AppLinkHelper.resolve('$path?book=book-1&leaf=leaf-2');
        expect(resolved?.route, AppRoutes.questionAnswers);
        expect(resolved?.payload, 'book-1');
        expect(resolved?.leafId, 'leaf-2');
      }
      final textQuestion = AppLinkHelper.resolve(
        '/questions?question=How+to+write%3F',
      );
      expect(textQuestion?.route, AppRoutes.questionAnswers);
      expect(textQuestion?.question, 'How to write?');
      expect(AppLinkHelper.resolve('/questions?book=book-1'), isNull);
      expect(AppLinkHelper.resolve('/questions?leaf=leaf-2'), isNull);
    });
  });
}
