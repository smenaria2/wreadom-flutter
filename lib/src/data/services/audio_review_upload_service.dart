import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class AudioReviewUploadService {
  AudioReviewUploadService({FirebaseFunctions? functions, Dio? dio})
    : _functions = functions ?? FirebaseFunctions.instance,
      _dio = dio ?? Dio();

  static const int maxDurationMs = 120000;
  static const int maxAudioBytes = 2 * 1024 * 1024;
  static const String mimeType = 'audio/mp4';

  final FirebaseFunctions _functions;
  final Dio _dio;

  Future<AudioReviewUploadResult> uploadAudioReview({
    required String filePath,
    required String bookId,
    required String userId,
    String? chapterId,
    required int durationMs,
  }) async {
    if (durationMs <= 0 || durationMs > maxDurationMs) {
      throw const AudioReviewUploadException(
        'Audio review must be 2 minutes or shorter.',
      );
    }

    final file = XFile(filePath, mimeType: mimeType);
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const AudioReviewUploadException('Recorded audio is empty.');
    }
    if (bytes.length > maxAudioBytes) {
      throw const AudioReviewUploadException(
        'Audio review must be 2MB or smaller.',
      );
    }

    final callable = _functions.httpsCallable('createAudioReviewUploadTarget');
    final response = await callable.call<Map<String, dynamic>>({
      'bookId': bookId,
      'chapterId': chapterId,
      'durationMs': durationMs,
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
      throw const AudioReviewUploadException(
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

    return AudioReviewUploadResult(
      audioUrl: audioUrl,
      audioObjectKey: objectKey,
      audioDurationMs: durationMs,
      audioMimeType: mimeType,
      audioSizeBytes: bytes.length,
    );
  }

  Future<void> deleteAudioReviewObject(String objectKey) async {
    final key = objectKey.trim();
    if (key.isEmpty) return;
    try {
      await _functions.httpsCallable('deleteAudioReviewObject').call({
        'objectKey': key,
      });
    } catch (_) {
      // Metadata removal should not be blocked by best-effort storage cleanup.
    }
  }
}

class AudioReviewUploadResult {
  const AudioReviewUploadResult({
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

class AudioReviewUploadException implements Exception {
  const AudioReviewUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
