import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/utils/instagram_profile_utils.dart';

void main() {
  group('normalizeInstagramHandle', () {
    test('normalizes a plain handle and an @handle', () {
      expect(normalizeInstagramHandle('wreadom.in'), 'wreadom.in');
      expect(normalizeInstagramHandle('@wreadom.in'), 'wreadom.in');
    });

    test('normalizes Instagram profile URLs', () {
      expect(
        normalizeInstagramHandle('https://www.instagram.com/wreadom.in/'),
        'wreadom.in',
      );
      expect(
        normalizeInstagramHandle('instagram.com/wreadom.in?utm_source=app'),
        'wreadom.in',
      );
    });

    test('rejects non-profile and malformed values', () {
      expect(
        normalizeInstagramHandle('https://instagram.com/reel/abc123'),
        isNull,
      );
      expect(normalizeInstagramHandle('https://instagram.com/explore'), isNull);
      expect(
        normalizeInstagramHandle('https://example.com/wreadom.in'),
        isNull,
      );
      expect(normalizeInstagramHandle('not a handle'), isNull);
      expect(normalizeInstagramHandle('@'), isNull);
    });
  });

  test('builds the canonical Instagram profile URL', () {
    expect(
      instagramProfileUrl('wreadom.in'),
      'https://www.instagram.com/wreadom.in/',
    );
  });
}
