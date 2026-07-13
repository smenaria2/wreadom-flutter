import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/utils/collection_firestore_utils.dart';

void main() {
  test('normalizes collection defaults, timestamps, and valid covers', () {
    final value = normalizeCollection({
      'ownerId': 'owner',
      'title': 'Favorites',
      'bookCount': 2.9,
      'createdAt': {'seconds': 12},
      'coverBooks': [
        {'bookId': 'a', 'coverUrl': 'https://example.com/a.jpg'},
        {'bookId': '', 'coverUrl': 'bad'},
        'malformed',
      ],
    }, 'collection-id');

    expect(value.id, 'collection-id');
    expect(value.description, isEmpty);
    expect(value.bookCount, 2);
    expect(value.createdAt, 12000);
    expect(value.coverBooks.map((cover) => cover.bookId), ['a']);
  });

  test('membership identity comes from document id', () {
    final value = normalizeCollectionBook({
      'bookId': 'spoofed',
      'position': 3.8,
      'addedAt': 42,
    }, 'real-id');

    expect(value.bookId, 'real-id');
    expect(value.position, 3);
    expect(value.addedAt, 42);
  });
}
