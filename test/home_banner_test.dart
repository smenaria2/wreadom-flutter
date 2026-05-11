import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:librebook_flutter/src/domain/models/home_banner.dart';
import 'package:librebook_flutter/src/presentation/screens/home_banner_screen.dart';

void main() {
  test('HomeBanner parses optional rich html body', () {
    final banner = HomeBanner.fromJson({
      'id': 'banner-1',
      'title': 'Weekly picks',
      'body': 'Plain fallback',
      'bodyHtml': '<p><strong>Rich</strong> fallback</p>',
      'isEnabled': true,
    });

    expect(banner.body, 'Plain fallback');
    expect(banner.bodyHtml, '<p><strong>Rich</strong> fallback</p>');
    expect(
      banner.toJson()['bodyHtml'],
      '<p><strong>Rich</strong> fallback</p>',
    );
  });

  testWidgets('HomeBannerScreen renders rich html without literal tags', (
    tester,
  ) async {
    const banner = HomeBanner(
      id: 'banner-1',
      title: 'Weekly picks',
      subtitle: '',
      body: 'Plain fallback',
      bodyHtml:
          '<html><body><p><strong>Hello</strong> reader</p><table><tr><td>Featured book</td></tr></table><script>alert(1)</script></body></html>',
      coverImageUrl: '',
      buttonText: '',
      buttonLink: '',
      isEnabled: true,
      timestamp: 1,
      lastUpdated: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(home: HomeBannerScreen(banner: banner)),
    );
    await tester.pumpAndSettle();

    final renderedText = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((widget) => widget.text.toPlainText())
        .join('\n');

    expect(find.byType(HtmlWidget), findsOneWidget);
    expect(renderedText, contains('Hello'));
    expect(renderedText, contains('Featured book'));
    expect(renderedText, isNot(contains('<p>')));
    expect(renderedText, isNot(contains('<table>')));
    expect(renderedText, isNot(contains('alert')));
  });
}
