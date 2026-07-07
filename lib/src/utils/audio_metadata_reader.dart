import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

const MethodChannel audioMetadataChannel = MethodChannel(
  'in.wreadom.app/audio_metadata',
);

Future<int> resolveAudioDurationMs(
  String? path, {
  AudioPlayer? player,
  bool skipJustAudio = false,
}) async {
  final value = path?.trim();
  if (value == null || value.isEmpty) return 0;

  if (!skipJustAudio) {
    final justAudioDuration = await _readJustAudioDurationMs(value, player);
    if (justAudioDuration > 0) return justAudioDuration;
  }

  return _readPlatformDurationMs(value);
}

Future<int> _readJustAudioDurationMs(String path, AudioPlayer? player) async {
  final ownedPlayer = player ?? AudioPlayer();
  try {
    final duration = await ownedPlayer.setAudioSource(AudioSource.file(path));
    await ownedPlayer.stop();
    return duration?.inMilliseconds ?? 0;
  } catch (error) {
    debugPrint('Could not read audio duration with just_audio: $error');
    return 0;
  } finally {
    if (player == null) {
      try {
        await ownedPlayer.dispose();
      } catch (error) {
        debugPrint('Could not dispose audio metadata player: $error');
      }
    }
  }
}

Future<int> _readPlatformDurationMs(String path) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return 0;
  try {
    final durationMs = await audioMetadataChannel.invokeMethod<int>(
      'readDurationMs',
      {'path': path},
    );
    return durationMs == null || durationMs <= 0 ? 0 : durationMs;
  } on MissingPluginException {
    return 0;
  } catch (error) {
    debugPrint('Could not read audio duration with platform metadata: $error');
    return 0;
  }
}
