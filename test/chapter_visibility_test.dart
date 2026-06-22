import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/chapter.dart';

void main() {
  test('legacy chapter JSON defaults to visible', () {
    final chapter = Chapter.fromJson(const {
      'id': 'chapter-1',
      'title': 'Opening',
      'content': '<p>Hello</p>',
      'index': 0,
    });

    expect(chapter.isHidden, isFalse);
  });

  test('hidden chapter JSON round-trips visibility', () {
    const chapter = Chapter(
      id: 'chapter-2',
      title: 'Secret',
      content: '<p>Hidden</p>',
      index: 1,
      isHidden: true,
    );

    expect(Chapter.fromJson(chapter.toJson()).isHidden, isTrue);
  });
}
