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
    });

    test('rejects unsupported links', () {
      final info = classifyWriterMediaUrl('https://example.com/story');

      expect(info.type, WriterMediaType.unsupported);
      expect(info.isSupported, isFalse);
    });
  });
}
