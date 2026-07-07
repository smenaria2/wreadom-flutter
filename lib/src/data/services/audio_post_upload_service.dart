import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

typedef AudioPostUploadTargetFactory =
    Future<Map<String, dynamic>> Function(Map<String, dynamic> data);
typedef AudioPostUploadPutClient =
    Future<void> Function(
      String uploadUrl,
      Uint8List bytes,
      Map<String, String> headers,
      String mimeType,
    );

class AudioPostUploadService {
  AudioPostUploadService({
    FirebaseFunctions? functions,
    Dio? dio,
    AudioPostUploadTargetFactory? createUploadTarget,
    AudioPostUploadPutClient? putClient,
  }) : _customFunctions = functions,
       _dio = dio ?? Dio(),
       _createUploadTarget = createUploadTarget,
       _putClient = putClient;

  static const int maxAudioBytes = 10 * 1024 * 1024; // 10MB

  final FirebaseFunctions? _customFunctions;
  final Dio _dio;
  final AudioPostUploadTargetFactory? _createUploadTarget;
  final AudioPostUploadPutClient? _putClient;

  FirebaseFunctions get _functions =>
      _customFunctions ?? FirebaseFunctions.instance;

  Future<AudioPostUploadResult> uploadAudioPost({
    required XFile file,
    required String userId,
    required String mimeType,
    required int durationMs,
    required int sizeBytes,
  }) async {
    try {
      if (userId.trim().isEmpty) {
        throw const AudioPostUploadException(
          'Login is required to upload audio.',
        );
      }

      final bytes = await file.readAsBytes();
      final normalizedMimeType = inferAudioPostMimeType(
        fileName: file.name,
        mimeType: mimeType,
      );
      validateAudioPostUpload(
        bytes: bytes,
        mimeType: normalizedMimeType,
        durationMs: durationMs,
        declaredSizeBytes: sizeBytes,
      );
      final uploadMimeType = normalizedMimeType!;

      final target = await _requestUploadTarget({
        'mimeType': uploadMimeType,
        'sizeBytes': bytes.length,
        'durationMs': durationMs,
      });
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

      await _putAudioBytes(
        uploadUrl: uploadUrl,
        bytes: bytes,
        headers: headers,
        mimeType: uploadMimeType,
      );

      return AudioPostUploadResult(
        audioUrl: audioUrl,
        audioObjectKey: objectKey,
        audioDurationMs: durationMs,
        audioMimeType: uploadMimeType,
        audioSizeBytes: bytes.length,
      );
    } catch (e) {
      if (e is AudioPostUploadException) {
        rethrow;
      }
      throw AudioPostUploadException(e.toString());
    }
  }

  Future<Map<String, dynamic>> _requestUploadTarget(
    Map<String, dynamic> data,
  ) async {
    if (_createUploadTarget != null) {
      return _createUploadTarget(data);
    }

    final callable = _functions.httpsCallable('createAudioPostUploadTarget');
    final response = await callable.call<Map<String, dynamic>>(data);
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> _putAudioBytes({
    required String uploadUrl,
    required Uint8List bytes,
    required Map<String, String> headers,
    required String mimeType,
  }) async {
    try {
      if (_putClient != null) {
        await _putClient(uploadUrl, bytes, headers, mimeType);
        return;
      }

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
    } on AudioPostUploadException {
      rethrow;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      throw AudioPostUploadException(
        status == null
            ? 'Audio upload failed.'
            : 'Audio upload failed ($status).',
      );
    } catch (_) {
      throw const AudioPostUploadException('Audio upload failed.');
    }
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

String? inferAudioPostMimeType({required String fileName, String? mimeType}) {
  final mime = mimeType?.trim().toLowerCase();
  if (_supportedAudioMimeTypes.contains(mime)) return mime;

  final name = fileName.toLowerCase();
  if (name.endsWith('.m4a')) return 'audio/m4a';
  if (name.endsWith('.aac')) return 'audio/aac';
  if (name.endsWith('.mp3')) return 'audio/mpeg';
  if (name.endsWith('.mp4')) return 'audio/mp4';
  if (name.endsWith('.wav')) return 'audio/wav';
  if (name.endsWith('.ogg')) return 'audio/ogg';
  if (name.endsWith('.opus')) return 'audio/opus';
  if (name.endsWith('.amr')) return 'audio/amr';
  if (name.endsWith('.flac')) return 'audio/flac';
  return null;
}

void validateAudioPostUpload({
  required Uint8List bytes,
  required String? mimeType,
  required int durationMs,
  int? declaredSizeBytes,
}) {
  if (bytes.isEmpty) {
    throw const AudioPostUploadException('Audio file is empty.');
  }
  if (bytes.length > AudioPostUploadService.maxAudioBytes ||
      (declaredSizeBytes != null &&
          declaredSizeBytes > AudioPostUploadService.maxAudioBytes)) {
    throw const AudioPostUploadException('Audio post must be 10MB or smaller.');
  }
  if (!_supportedAudioMimeTypes.contains(mimeType)) {
    throw const AudioPostUploadException('Unsupported audio type.');
  }
  if (durationMs <= 0) {
    throw const AudioPostUploadException(
      'Audio duration could not be verified.',
    );
  }
}

const _supportedAudioMimeTypes = {
  'audio/mp4',
  'audio/m4a',
  'audio/aac',
  'audio/mpeg',
  'audio/mp3',
  'audio/wav',
  'audio/x-wav',
  'audio/ogg',
  'audio/opus',
  'audio/amr',
  'audio/flac',
};

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
