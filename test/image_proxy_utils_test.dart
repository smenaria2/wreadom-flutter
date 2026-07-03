import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/utils/image_proxy_utils.dart';

void main() {
  group('optimizedImageUrl', () {
    test('adds Cloudflare image params to Backblaze Worker URLs', () {
      final result = optimizedImageUrl(
        'https://wreadom-images.smenaria2.workers.dev/images/feed/post.jpg',
        width: 320,
        height: 200,
        quality: 90,
        fit: 'cover',
      );

      final uri = Uri.parse(result);
      expect(uri.queryParameters['width'], '320');
      expect(uri.queryParameters['height'], '200');
      expect(uri.queryParameters['quality'], '90');
      expect(uri.queryParameters['fit'], 'cover');
      expect(uri.queryParameters['format'], 'auto');
    });

    test('preserves non-Worker URLs', () {
      const url = 'https://res.cloudinary.com/demo/image/upload/sample.jpg';

      expect(optimizedImageUrl(url, width: 320), url);
    });
  });

  group('optimizedAvatarUrl', () {
    test('optimizes worker URLs with default avatar dimensions', () {
      final result = optimizedAvatarUrl(
        'https://wreadom-images.smenaria2.workers.dev/avatars/user123.jpg',
      );

      final uri = Uri.parse(result!);
      expect(uri.queryParameters['width'], '150');
      expect(uri.queryParameters['height'], '150');
      expect(uri.queryParameters['fit'], 'cover');
    });

    test('optimizes worker URLs with custom avatar dimensions', () {
      final result = optimizedAvatarUrl(
        'https://wreadom-images.smenaria2.workers.dev/avatars/user123.jpg',
        width: 240,
        height: 240,
      );

      final uri = Uri.parse(result!);
      expect(uri.queryParameters['width'], '240');
      expect(uri.queryParameters['height'], '240');
      expect(uri.queryParameters['fit'], 'cover');
    });

    test('handles null and empty URLs gracefully', () {
      expect(optimizedAvatarUrl(null), isNull);
      expect(optimizedAvatarUrl(''), isEmpty);
      expect(optimizedAvatarUrl('   '), '   ');
    });

    test('preserves non-worker URLs', () {
      const url = 'https://someplace.com/avatar.png';
      expect(optimizedAvatarUrl(url), url);
    });
  });
}

