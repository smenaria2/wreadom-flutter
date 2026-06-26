import 'dart:convert';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class SilentAudioSourceHelper {
  static File? _silentFile;

  static const String _silentMp3Base64 =
      'SUQzBAAAAAAAI1RTU0UAAAAPAAADTGF2ZjU2LjM2LjEwMAAAAAAAAAAAAAAA//OEAAAAAAAAAAAAAAAAAAAAAAAASW5mbwAAAA8AAAAEAAABIADAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV6urq6urq6urq6urq6urq6urq6urq6urq6v////////////////////////////////8AAAAATGF2YzU2LjQxAAAAAAAAAAAAAAAAJAAAAAAAAAAAASDs90hvAAAAAAAAAAAAAAAAAAAA//MUZAAAAAGkAAAAAAAAA0gAAAAATEFN//MUZAMAAAGkAAAAAAAAA0gAAAAARTMu//MUZAYAAAGkAAAAAAAAA0gAAAAAOTku//MUZAkAAAGkAAAAAAAAA0gAAAAANVVV';

  static Future<AudioSource> getSilentAudioSource({
    required String id,
    dynamic tag,
  }) async {
    if (_silentFile == null) {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/silent_tts.mp3');
      if (!await file.exists()) {
        final bytes = base64Decode(_silentMp3Base64);
        await file.writeAsBytes(bytes);
      }
      _silentFile = file;
    }

    return AudioSource.file(
      _silentFile!.path,
      tag: tag,
    );
  }
}
