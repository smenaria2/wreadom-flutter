import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class AudioPostUploadService {
  AudioPostUploadService({FirebaseFunctions? functions, Dio? dio})
      : _functions = functions ?? FirebaseFunctions.instance,
        _dio = dio ?? Dio();

  static const int maxAudioBytes = 10 * 1024 * 1024; // 10MB

  final FirebaseFunctions _functions;
  final Dio _dio;

  Future<AudioPostUploadResult> uploadAudioPost({
    required String filePath,
    required String userId,
    required String mimeType,
    required int durationMs,
    required int sizeBytes,
  }) async {
    if (sizeBytes <= 0 || sizeBytes > maxAudioBytes) {
      throw const AudioPostUploadException(
        'Audio post must be 10MB or smaller.',
      );
    }

    final file = XFile(filePath, mimeType: mimeType);
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const AudioPostUploadException('Audio file is empty.');
    }

    final callable = _functions.httpsCallable('createAudioPostUploadTarget');
    final response = await callable.call<Map<String, dynamic>>({
      'mimeType': mimeType,
      'sizeBytes': bytes.length,
    });

    final target = Map<String, dynamic>.from(response.data);
    final uploadUrl = target['uploadUrl']?.toString();
    final objectKey = target['objectKey']?.toString();
    final audioUrl = target['audioUrl']?.toString();
    final rawHeaders = target['headers'];

    if (uploadUrl == null ||
        uploadUrl.isEmpty ||
        objectKey == null ||
        objectKey.isEmpty ||
        audioUrl == null ||
        audioUrl.isEmpty ||
        rawHeaders is! Map) {
      throw const AudioPostUploadException(
        'Audio upload target was incomplete.',
      );
    }

    final headers = rawHeaders.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );

    await _dio.put<void>(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: headers,
        contentType: mimeType,
        responseType: ResponseType.plain,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    return AudioPostUploadResult(
      audioUrl: audioUrl,
      audioObjectKey: objectKey,
      audioDurationMs: durationMs,
      audioMimeType: mimeType,
      audioSizeBytes: bytes.length,
    );
  }

  Future<void> deleteAudioPostObject(String objectKey) async {
    final key = objectKey.trim();
    if (key.isEmpty) return;
    try {
      await _functions.httpsCallable('deleteAudioPostObject').call({
        'objectKey': key,
      });
    } catch (_) {
      // Metadata removal should not be blocked by best-effort storage cleanup.
    }
  }
}

class AudioPostUploadResult {
  const AudioPostUploadResult({
    required this.audioUrl,
    required this.audioObjectKey,
    required this.audioDurationMs,
    required this.audioMimeType,
    required this.audioSizeBytes,
  });

  final String audioUrl;
  final String audioObjectKey;
  final int audioDurationMs;
  final String audioMimeType;
  final int audioSizeBytes;
}

class AudioPostUploadException implements Exception {
  const AudioPostUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
