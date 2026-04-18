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
  });
}
