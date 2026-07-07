import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/utils/audio_metadata_reader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioMetadataChannel, null);
  });

  test(
    'resolveAudioDurationMs falls back to Android metadata channel',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      MethodCall? receivedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(audioMetadataChannel, (call) async {
            receivedCall = call;
            return 42000;
          });

      final durationMs = await resolveAudioDurationMs(
        'missing-but-valid.mp3',
        skipJustAudio: true,
      );

      expect(durationMs, 42000);
      expect(receivedCall?.method, 'readDurationMs');
      expect(receivedCall?.arguments, {'path': 'missing-but-valid.mp3'});
    },
  );
}
