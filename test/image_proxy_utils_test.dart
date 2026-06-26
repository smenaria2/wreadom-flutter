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
}
