import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/utils/writer_media_utils.dart';

void main() {
  group('classifyWriterMediaUrl', () {
    test('classifies supported Leaf link providers', () {
      expect(
        classifyWriterMediaUrl('https://youtu.be/dQw4w9WgXcQ').type,
        WriterMediaType.youtube,
      );
      expect(
        classifyWriterMediaUrl('https://open.spotify.com/track/123').type,
        WriterMediaType.spotify,
      );
      expect(
        classifyWriterMediaUrl('https://www.instagram.com/p/abc123/').type,
        WriterMediaType.instagram,
      );
      expect(
        classifyWriterMediaUrl('https://www.amazon.com/dp/B08N5WRWNW').type,
        WriterMediaType.amazon,
      );
      expect(
        classifyWriterMediaUrl('https://en.wikipedia.org/wiki/Flutter').type,
        WriterMediaType.wikipedia,
      );
      expect(
        classifyWriterMediaUrl(
          'https://wreadom.in/?page=feed&post=post123',
        ).type,
        WriterMediaType.wreadomPost,
      );
    });

    test('rejects unsupported links', () {
      final info = classifyWriterMediaUrl('https://example.com/story');

      expect(info.type, WriterMediaType.unsupported);
      expect(info.isSupported, isFalse);
    });
    test('finds supported media links inside post text', () {
      final info = firstSupportedWriterMediaInfoInText(
        'Watch this https://www.instagram.com/p/abc123/ tonight',
      );

      expect(info?.type, WriterMediaType.instagram);
    });

    test('trims trailing punctuation from detected links', () {
      final info = firstSupportedWriterMediaInfoInText(
        'Watch this https://youtu.be/dQw4w9WgXcQ.',
      );

      expect(info?.type, WriterMediaType.youtube);
      expect(info?.originalUrl, 'https://youtu.be/dQw4w9WgXcQ');
    });

    test('uses the first supported link when multiple links are present', () {
      final info = firstSupportedWriterMediaInfoInText(
        'Try https://open.spotify.com/track/123 and https://youtu.be/dQw4w9WgXcQ',
      );

      expect(info?.type, WriterMediaType.spotify);
    });

    test('skips unsupported links before a supported link', () {
      final info = firstSupportedWriterMediaInfoInText(
        'Read https://example.com/story then https://youtu.be/dQw4w9WgXcQ',
      );

      expect(info?.type, WriterMediaType.youtube);
    });

    test('returns null when post text has no supported links', () {
      final info = firstSupportedWriterMediaInfoInText(
        'Read https://example.com/story and tell me what you think.',
      );

      expect(info, isNull);
    });
  });
}
