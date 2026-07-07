import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:librebook_flutter/src/data/services/audio_post_upload_service.dart';

void main() {
  group('AudioPostUploadService', () {
    test(
      'successful signed upload sends normalized metadata and returns result',
      () async {
        Map<String, dynamic>? requestedTarget;
        Uint8List? uploadedBytes;
        Map<String, String>? uploadedHeaders;
        String? uploadedMimeType;

        final service = AudioPostUploadService(
          createUploadTarget: (data) async {
            requestedTarget = data;
            return {
              'uploadUrl': 'https://s3.us-east-005.backblazeb2.com/bucket/key',
              'headers': {'content-type': data['mimeType']},
              'objectKey': 'audio-posts/user/clip.m4a',
              'audioUrl':
                  'https://wreadom-audio.example/audio-posts/user/clip.m4a',
            };
          },
          putClient: (uploadUrl, bytes, headers, mimeType) async {
            uploadedBytes = bytes;
            uploadedHeaders = headers;
            uploadedMimeType = mimeType;
          },
        );

        final result = await service.uploadAudioPost(
          file: XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'clip.mp3'),
          userId: 'user_1',
          mimeType: 'audio/mpeg',
          durationMs: 1200,
          sizeBytes: 3,
        );

        expect(requestedTarget, {
          'mimeType': 'audio/mpeg',
          'sizeBytes': 3,
          'durationMs': 1200,
        });
        expect(uploadedBytes, Uint8List.fromList([1, 2, 3]));
        expect(uploadedHeaders, {'content-type': 'audio/mpeg'});
        expect(uploadedMimeType, 'audio/mpeg');
        expect(result.audioObjectKey, 'audio-posts/user/clip.m4a');
        expect(result.audioMimeType, 'audio/mpeg');
        expect(result.audioSizeBytes, 3);
      },
    );

    test('empty file is rejected before requesting upload target', () async {
      final service = AudioPostUploadService(
        createUploadTarget: (_) async => throw StateError('should not call'),
        putClient: (_, _, _, _) async {},
      );

      await expectLater(
        service.uploadAudioPost(
          file: XFile.fromData(Uint8List(0), name: 'clip.m4a'),
          userId: 'user_1',
          mimeType: 'audio/m4a',
          durationMs: 1000,
          sizeBytes: 0,
        ),
        throwsA(
          isA<AudioPostUploadException>().having(
            (error) => error.message,
            'message',
            'Audio file is empty.',
          ),
        ),
      );
    });

    test('actual byte size over limit is rejected', () async {
      final service = AudioPostUploadService(
        createUploadTarget: (_) async => throw StateError('should not call'),
        putClient: (_, _, _, _) async {},
      );

      await expectLater(
        service.uploadAudioPost(
          file: XFile.fromData(
            Uint8List(AudioPostUploadService.maxAudioBytes + 1),
            name: 'clip.m4a',
          ),
          userId: 'user_1',
          mimeType: 'audio/m4a',
          durationMs: 1000,
          sizeBytes: 1,
        ),
        throwsA(
          isA<AudioPostUploadException>().having(
            (error) => error.message,
            'message',
            'Audio post must be 10MB or smaller.',
          ),
        ),
      );
    });

    test('declared byte size over limit is rejected', () async {
      final service = AudioPostUploadService(
        createUploadTarget: (_) async => throw StateError('should not call'),
        putClient: (_, _, _, _) async {},
      );

      await expectLater(
        service.uploadAudioPost(
          file: XFile.fromData(Uint8List.fromList([1]), name: 'clip.m4a'),
          userId: 'user_1',
          mimeType: 'audio/m4a',
          durationMs: 1000,
          sizeBytes: AudioPostUploadService.maxAudioBytes + 1,
        ),
        throwsA(isA<AudioPostUploadException>()),
      );
    });

    test('unsupported audio type is rejected', () async {
      final service = AudioPostUploadService(
        createUploadTarget: (_) async => throw StateError('should not call'),
        putClient: (_, _, _, _) async {},
      );

      await expectLater(
        service.uploadAudioPost(
          file: XFile.fromData(Uint8List.fromList([1]), name: 'clip.txt'),
          userId: 'user_1',
          mimeType: 'text/plain',
          durationMs: 1000,
          sizeBytes: 1,
        ),
        throwsA(
          isA<AudioPostUploadException>().having(
            (error) => error.message,
            'message',
            'Unsupported audio type.',
          ),
        ),
      );
    });

    test('infers shared audio mime types from common extensions', () {
      expect(inferAudioPostMimeType(fileName: 'clip.ogg'), 'audio/ogg');
      expect(inferAudioPostMimeType(fileName: 'voice.opus'), 'audio/opus');
      expect(inferAudioPostMimeType(fileName: 'recording.amr'), 'audio/amr');
      expect(inferAudioPostMimeType(fileName: 'master.flac'), 'audio/flac');
    });
    test('zero duration is rejected', () async {
      final service = AudioPostUploadService(
        createUploadTarget: (_) async => throw StateError('should not call'),
        putClient: (_, _, _, _) async {},
      );

      await expectLater(
        service.uploadAudioPost(
          file: XFile.fromData(Uint8List.fromList([1]), name: 'clip.m4a'),
          userId: 'user_1',
          mimeType: 'audio/m4a',
          durationMs: 0,
          sizeBytes: 1,
        ),
        throwsA(
          isA<AudioPostUploadException>().having(
            (error) => error.message,
            'message',
            'Audio duration could not be verified.',
          ),
        ),
      );
    });

    test('incomplete upload target is rejected', () async {
      final service = AudioPostUploadService(
        createUploadTarget: (_) async => {
          'uploadUrl': 'https://s3.us-east-005.backblazeb2.com/bucket/key',
          'headers': {'content-type': 'audio/m4a'},
        },
        putClient: (_, _, _, _) async => throw StateError('should not call'),
      );

      await expectLater(
        service.uploadAudioPost(
          file: XFile.fromData(Uint8List.fromList([1]), name: 'clip.m4a'),
          userId: 'user_1',
          mimeType: 'audio/m4a',
          durationMs: 1000,
          sizeBytes: 1,
        ),
        throwsA(
          isA<AudioPostUploadException>().having(
            (error) => error.message,
            'message',
            'Audio upload target was incomplete.',
          ),
        ),
      );
    });

    test('failed B2 PUT surfaces a useful error', () async {
      final service = AudioPostUploadService(
        createUploadTarget: (_) async => {
          'uploadUrl': 'https://s3.us-east-005.backblazeb2.com/bucket/key',
          'headers': {'content-type': 'audio/m4a'},
          'objectKey': 'audio-posts/user/clip.m4a',
          'audioUrl': 'https://wreadom-audio.example/audio-posts/user/clip.m4a',
        },
        putClient: (_, _, _, _) async => throw Exception('network'),
      );

      await expectLater(
        service.uploadAudioPost(
          file: XFile.fromData(Uint8List.fromList([1]), name: 'clip.m4a'),
          userId: 'user_1',
          mimeType: 'audio/m4a',
          durationMs: 1000,
          sizeBytes: 1,
        ),
        throwsA(
          isA<AudioPostUploadException>().having(
            (error) => error.message,
            'message',
            'Audio upload failed.',
          ),
        ),
      );
    });
  });
}
