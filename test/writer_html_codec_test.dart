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
        '<h2>Chapter</h2><p><em>Hello</em> <u>reader</u></p>',
      );

      final html = htmlFromDocument(document);

      expect(html, contains('<h2>Chapter</h2>'));
      expect(html, contains('<em>Hello</em>'));
      expect(html, contains('<u>reader</u>'));
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
      expect(
        wordCountFromHtml('<p>One\u00A0two\tthree</p><p>four</p>'),
        4,
      );
      expect(wordCountFromHtml('<p>&nbsp;</p>'), 0);
    });
  });
}
