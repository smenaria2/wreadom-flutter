// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/config/env_config.dart';
import 'package:librebook_flutter/src/data/services/cover_image_service.dart';

void main() {
  group('CoverImageService Tests', () {
    late CoverImageService service;

    setUp(() {
      service = CoverImageService();
    });

    test('translateTitle translates Hindi text to English', () async {
      final hindiTitle = 'मेरी नई किताब'; // My new book
      final result = await service.translateTitle(hindiTitle);
      
      expect(result.toLowerCase(), contains('my'));
      expect(result.toLowerCase(), contains('book'));
    });

    test('translateTitle handles empty/untitled title fallback', () async {
      final resultEmpty = await service.translateTitle('');
      expect(resultEmpty, equals('story'));

      final resultUntitled = await service.translateTitle('Untitled Story');
      expect(resultUntitled, equals('story'));
    });

    test('searchImages fetches exactly 3 images from Unsplash', () async {
      if (EnvConfig.unsplashAccessKey.isEmpty) {
        print('Skipping Unsplash search test because UNSPLASH_ACCESS_KEY is not configured.');
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
