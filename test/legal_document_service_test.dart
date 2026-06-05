import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/services/legal_document_service.dart';

void main() {
  group('sanitizeLegalHtml', () {
    test('removes script tags and event attributes', () {
      final html = sanitizeLegalHtml(
        '<main><h1 onclick="bad()">Policy</h1>'
        '<script>alert(1)</script><p>Safe</p></main>',
      );

      expect(html, contains('<h1>Policy</h1>'));
      expect(html, contains('<p>Safe</p>'));
      expect(html, isNot(contains('script')));
      expect(html, isNot(contains('onclick')));
    });

    test('keeps safe legal structure and table tags', () {
      final html = sanitizeLegalHtml(
        '<article><table><tr><th>Data</th></tr>'
        '<tr><td>Account</td></tr></table><ul><li>One</li></ul></article>',
      );

      expect(html, contains('<table>'));
      expect(html, contains('<th>Data</th>'));
      expect(html, contains('<td>Account</td>'));
      expect(html, contains('<li>One</li>'));
    });

    test('keeps safe links and strips unsafe links', () {
      final html = sanitizeLegalHtml(
        '<main><a href="https://wreadom.in/privacy">Privacy</a>'
        '<a href="javascript:alert(1)">Bad</a></main>',
      );

      expect(html, contains('href="https://wreadom.in/privacy"'));
      expect(html, contains('<a>Bad</a>'));
      expect(html, isNot(contains('javascript:')));
    });
  });
}
