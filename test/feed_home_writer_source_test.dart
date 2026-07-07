import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feed scope selector is rendered inside feed page list headers', () {
    final source = File(
      'lib/src/presentation/screens/home_feed_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('SliverToBoxAdapter')));
    expect(source, contains('class _FeedScopeSelector'));
    expect(source, contains('children: feedHeaders'));
    expect(source, contains('...feedHeaders'));
  });

  test('home shelf book card reserves fixed cover and text space', () {
    final source = File(
      'lib/src/presentation/screens/home_books_screen.dart',
    ).readAsStringSync();

    expect(source, contains('const shelfHeight = 244.0'));
    expect(source, contains('height: 180'));
    expect(source, contains('height: 54'));
    expect(source, contains('overflow: TextOverflow.ellipsis'));
  });

  test(
    'writer editor persists manual title locks and keyboard compact mode',
    () {
      final source = File(
        'lib/src/presentation/screens/writer_pad_screen.dart',
      ).readAsStringSync();

      expect(source, contains('isTitleLocked: draft.isTitleLocked'));
      expect(source, contains('chapter.isTitleLocked ??'));
      expect(source, contains('isTitleLocked = true'));
      expect(source, contains('final compactForWriting'));
      expect(source, contains('AnimatedPadding'));
    },
  );
}
