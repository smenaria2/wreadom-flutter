import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';
import 'package:librebook_flutter/src/utils/app_link_helper.dart';

void main() {
  group('AppLinkHelper', () {
    test('builds canonical web-compatible post share URL', () {
      expect(
        AppLinkHelper.post('post 123'),
        'https://wreadom.in/?page=feed&post=post%20123',
      );
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

      expect(discovery?.route, AppRoutes.discovery);
      expect(discovery?.payload, isNull);
      expect(writer?.route, AppRoutes.writerDashboard);
      expect(writer?.payload, isNull);
    });
  });
}
