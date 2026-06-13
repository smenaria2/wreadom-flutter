import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/leaf_attachment.dart';

void main() {
  group('LeafAttachment', () {
    test('parses backend note leaf JSON', () {
      final leaf = LeafAttachment.fromJson({
        'id': 'leaf1',
        'type': 'text',
        'createdBy': 'user1',
        'createdAt': 123,
        'textHtml': '<p>Hello</p>',
        'textPlain': 'Hello',
      });

      expect(leaf.id, 'leaf1');
      expect(leaf.type, LeafType.text);
      expect(leaf.createdBy, 'user1');
      expect(leaf.createdAt, 123);
      expect(leaf.textHtml, '<p>Hello</p>');
      expect(leaf.textPlain, 'Hello');
    });

    test('round trips link leaf type fields', () {
      final leaf = LeafAttachment(
        id: 'leaf2',
        type: LeafType.link,
        createdBy: 'user1',
        createdAt: 456,
        url: 'https://youtu.be/dQw4w9WgXcQ',
        linkType: LeafLinkType.youtube,
        title: 'YouTube',
      );

      final json = leaf.toJson();

      expect(json['type'], 'link');
      expect(json['linkType'], 'youtube');
      expect(LeafAttachment.fromJson(json), leaf);
    });
  });
}
