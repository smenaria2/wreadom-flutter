import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/utils/writer_html_codec.dart';

void main() {
  group('writer html codec', () {
    test('loads formatted html without exposing literal tags', () {
      final document = documentFromHtml('<p><strong>Hello</strong> world</p>');

      expect(document.toPlainText(), contains('Hello world'));
      expect(document.toPlainText(), isNot(contains('<strong>')));
    });

    test('round trips core formatting as sanitized html', () {
      final document = documentFromHtml(
        '<h2>Chapter</h2><p><em>Hello</em> <u>reader</u></p>'
        '<blockquote>Remember this</blockquote><ul><li>First</li></ul>',
      );

      final html = htmlFromDocument(document);

      expect(html, contains('<h2>Chapter</h2>'));
      expect(html, contains('<em>Hello</em>'));
      expect(html, contains('<u>reader</u>'));
      expect(html, contains('<blockquote>Remember this</blockquote>'));
      expect(html, contains('<ul><li>First</li></ul>'));
    });

    test('round trips trusted image embeds', () {
      const image =
          'https://res.cloudinary.com/demo/image/upload/f_auto/sample.jpg';

      final html = htmlFromDocument(
        documentFromHtml('<p><img src="$image" alt="Sample"></p>'),
      );

      expect(html, contains('<img src="$image">'));
      expect(html, isNot(contains('alt=')));
    });

    test('round trips supported media links as embeds', () {
      const media = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

      final html = htmlFromDocument(
        documentFromHtml('<p><a href="$media">video</a></p>'),
      );

      expect(html, contains('href="$media"'));
      expect(html, contains('YouTube'));
    });

    test('removes unsafe markup', () {
      final html = sanitizeWriterHtml(
        '<p>Safe</p><script>alert("x")</script><a href="javascript:x">bad</a>',
      );

      expect(html, contains('<p>Safe</p>'));
      expect(html, isNot(contains('<script>')));
      expect(html, isNot(contains('javascript:')));
    });

    test('plain text legacy content remains readable', () {
      final document = documentFromHtml('A simple older draft');

      expect(document.toPlainText(), contains('A simple older draft'));
    });

    test('word count handles html and non-breaking whitespace', () {
      expect(wordCountFromHtml('<p>One\u00A0two\tthree</p><p>four</p>'), 4);
      expect(wordCountFromHtml('<p>&nbsp;</p>'), 0);
    });
  });
}
