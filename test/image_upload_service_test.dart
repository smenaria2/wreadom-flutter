import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/services/image_upload_service.dart';

void main() {
  group('ImageUploadService', () {
    test('successful signed upload returns Worker URL', () async {
      Map<String, dynamic>? requestedTarget;
      Uint8List? uploadedBytes;
      Map<String, String>? uploadedHeaders;

      final service = ImageUploadService(
        createUploadTarget: (data) async {
          requestedTarget = data;
          return {
            'uploadUrl': 'https://s3.us-east-005.backblazeb2.com/bucket/key',
            'headers': {'content-type': data['mimeType']},
            'objectKey': 'images/feed_posts/user_1.jpg',
            'imageUrl':
                'https://wreadom-images.smenaria2.workers.dev/images/feed_posts/user_1.jpg',
          };
        },
        putClient: (uploadUrl, bytes, headers, mimeType) async {
          uploadedBytes = bytes;
          uploadedHeaders = headers;
        },
      );

      final result = await service.uploadImageBytes(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'post.jpg',
        folder: 'feed_posts',
        userId: 'user',
        preset: ImageUploadPreset.feed,
      );

      expect(requestedTarget, {
        'folder': 'feed_posts',
        'mimeType': 'image/jpeg',
      });
      expect(uploadedBytes, Uint8List.fromList([1, 2, 3]));
      expect(uploadedHeaders, {'content-type': 'image/jpeg'});
      expect(
        result,
        startsWith('https://wreadom-images.smenaria2.workers.dev/'),
      );
    });

    test('unauthenticated upload fails clearly', () async {
      final service = ImageUploadService(
        createUploadTarget: (_) async => throw StateError('should not call'),
        putClient: (_, _, _, _) async {},
      );

      await expectLater(
        service.uploadImageBytes(
          bytes: Uint8List.fromList([1]),
          fileName: 'post.jpg',
          folder: 'feed_posts',
          userId: '',
        ),
        throwsA(
          isA<ImageUploadException>().having(
            (error) => error.message,
            'message',
            contains('Login is required'),
          ),
        ),
      );
    });

    test('unsupported image type is rejected', () async {
      final service = ImageUploadService(
        createUploadTarget: (_) async => throw StateError('should not call'),
        putClient: (_, _, _, _) async {},
      );

      await expectLater(
        service.uploadImageBytes(
          bytes: Uint8List.fromList([1]),
          fileName: 'post.bmp',
          folder: 'feed_posts',
          userId: 'user',
          mimeType: 'image/bmp',
        ),
        throwsA(isA<ImageUploadException>()),
      );
    });

    test('failed B2 PUT surfaces a useful error', () async {
      final service = ImageUploadService(
        createUploadTarget: (_) async => {
          'uploadUrl': 'https://s3.us-east-005.backblazeb2.com/bucket/key',
          'headers': {'content-type': 'image/png'},
          'objectKey': 'images/feed_posts/user_1.png',
          'imageUrl':
              'https://wreadom-images.smenaria2.workers.dev/images/feed_posts/user_1.png',
        },
        putClient: (_, _, _, _) async => throw Exception('network'),
      );

      await expectLater(
        service.uploadImageBytes(
          bytes: Uint8List.fromList([1]),
          fileName: 'post.png',
          folder: 'feed_posts',
          userId: 'user',
        ),
        throwsA(
          isA<ImageUploadException>().having(
            (error) => error.message,
            'message',
            'Image upload failed.',
          ),
        ),
      );
    });
  });
}
