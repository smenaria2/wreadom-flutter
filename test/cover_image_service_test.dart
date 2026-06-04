// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:librebook_flutter/src/config/env_config.dart';
import 'package:librebook_flutter/src/data/services/cover_image_service.dart';

void main() {
  group('CoverImageService Tests', () {
    late CoverImageService service;

    setUp(() {
      service = CoverImageService();
    });

    test(
      'translateTitle repairs mojibake Hindi text before translation',
      () async {
        const hindiTitle =
            '\u092e\u0947\u0930\u0940 \u0928\u0908 \u0915\u093f\u0924\u093e\u092c';
        final mojibakeHindiTitle = latin1.decode(utf8.encode(hindiTitle));
        final service = CoverImageService(
          httpClient: MockClient((request) async {
            expect(request.url.queryParameters['q'], equals(hindiTitle));
            return http.Response(
              jsonEncode([
                [
                  ['My new book'],
                ],
              ]),
              200,
            );
          }),
        );

        final result = await service.translateTitle(mojibakeHindiTitle);

        expect(result, equals('My new book'));
      },
    );

    test(
      'translateTitle uses an English cover query when Hindi translation fails',
      () async {
        const hindiTitle =
            '\u092e\u0947\u0930\u0940 \u0928\u0908 \u0915\u093f\u0924\u093e\u092c';
        final service = CoverImageService(
          httpClient: MockClient((request) async => http.Response('', 503)),
        );

        final result = await service.translateTitle(hindiTitle);

        expect(result, equals('hindi book cover story'));
      },
    );

    test('translateTitle handles empty/untitled title fallback', () async {
      final resultEmpty = await service.translateTitle('');
      expect(resultEmpty, equals('story'));

      final resultUntitled = await service.translateTitle('Untitled Story');
      expect(resultUntitled, equals('story'));
    });

    test('searchImages fetches exactly 3 images from Unsplash', () async {
      if (EnvConfig.unsplashAccessKey.isEmpty) {
        print(
          'Skipping Unsplash search test because UNSPLASH_ACCESS_KEY is not configured.',
        );
        return;
      }

      final query = 'story';
      final images = await service.searchImages(query);

      print('Fetched ${images.length} images from Unsplash: $images');
      expect(images.length, lessThanOrEqualTo(3));
      if (images.isNotEmpty) {
        expect(images.first, startsWith('http'));
      }
    });
  });
}
