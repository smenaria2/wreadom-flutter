import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/leaf_attachment.dart';
import 'package:librebook_flutter/src/presentation/components/book/leaf_components.dart';

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

    test('round trips certificate leaf metadata', () {
      const leaf = LeafAttachment(
        id: 'certificate_123_daily_topic',
        type: LeafType.certificate,
        createdBy: 'user1',
        createdByRole: 'app',
        createdAt: 123,
        title: 'Certificate',
        certificateTopicName: 'Agaaz Topics',
        certificateIssuedAt: 456,
        certificateParticipantName: 'A Writer',
        certificateParticipantPhotoUrl: 'https://example.com/avatar.jpg',
      );

      final json = leaf.toJson();

      expect(json['type'], 'certificate');
      expect(json['certificateTopicName'], 'Agaaz Topics');
      expect(json['certificateIssuedAt'], 456);
      expect(LeafAttachment.fromJson(json), leaf);
    });

    test('manual Leaf creation does not expose certificates', () {
      expect(manualLeafTypes, isNot(contains(LeafType.certificate)));
    });
  });
}
