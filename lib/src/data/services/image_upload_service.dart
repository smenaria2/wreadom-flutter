import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

typedef ImageUploadTargetFactory =
    Future<Map<String, dynamic>> Function(Map<String, dynamic> data);
typedef ImageUploadPutClient =
    Future<void> Function(
      String uploadUrl,
      Uint8List bytes,
      Map<String, String> headers,
      String mimeType,
    );

enum ImageUploadPreset {
  feed(maxWidth: 1600, maxHeight: 1600),
  inline(maxWidth: 1600, maxHeight: 1600),
  leaf(maxWidth: 1600, maxHeight: 1600),
  profilePhoto(maxWidth: 600, maxHeight: 600),
  profileCover(maxWidth: 1600, maxHeight: 600),
  bookCover(maxWidth: 600, maxHeight: 900),
  dailyTopic(maxWidth: 1200, maxHeight: 675),
  general(maxWidth: 1600, maxHeight: 1600);

  const ImageUploadPreset({required this.maxWidth, required this.maxHeight});

  final int maxWidth;
  final int maxHeight;
}

class ImageUploadService {
  ImageUploadService({
    FirebaseFunctions? functions,
    Dio? dio,
    ImageUploadTargetFactory? createUploadTarget,
    ImageUploadPutClient? putClient,
  }) : _customFunctions = functions,
       _dio = dio ?? Dio(),
       _createUploadTarget = createUploadTarget,
       _putClient = putClient;

  static const int maxImageBytes = 10 * 1024 * 1024;

  final FirebaseFunctions? _customFunctions;
  final Dio _dio;
  final ImageUploadTargetFactory? _createUploadTarget;
  final ImageUploadPutClient? _putClient;

  FirebaseFunctions get _functions =>
      _customFunctions ?? FirebaseFunctions.instance;

  Future<String> uploadImage({
    required XFile file,
    required String folder,
    required String userId,
    ImageUploadPreset preset = ImageUploadPreset.general,
  }) async {
    final bytes = await file.readAsBytes();
    return uploadImageBytes(
      bytes: bytes,
      fileName: file.name.isEmpty ? 'upload.jpg' : file.name,
      folder: folder,
      userId: userId,
      mimeType: file.mimeType,
      preset: preset,
    );
  }

  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    required String userId,
    String? mimeType,
    ImageUploadPreset preset = ImageUploadPreset.general,
  }) async {
    if (userId.trim().isEmpty) {
      throw const ImageUploadException('Login is required to upload images.');
    }
    if (bytes.isEmpty) {
      throw const ImageUploadException('Image file is empty.');
    }
    if (bytes.length > maxImageBytes) {
      throw const ImageUploadException('Image must be 10MB or smaller.');
    }

    final normalizedMimeType = inferSupportedImageMimeType(
      fileName: fileName,
      mimeType: mimeType,
    );
    if (normalizedMimeType == null) {
      throw const ImageUploadException(
        'Please choose a PNG, JPEG, WebP, or GIF image.',
      );
    }

    final prepared = _resizeImageIfNeeded(
      bytes: bytes,
      mimeType: normalizedMimeType,
      preset: preset,
    );

    final target = await _requestUploadTarget({
      'folder': folder,
      'mimeType': prepared.mimeType,
    });
    final uploadUrl = target['uploadUrl']?.toString();
    final objectKey = target['objectKey']?.toString();
    final imageUrl = target['imageUrl']?.toString();
    final rawHeaders = target['headers'];

    if (uploadUrl == null ||
        uploadUrl.isEmpty ||
        objectKey == null ||
        objectKey.isEmpty ||
        imageUrl == null ||
        imageUrl.isEmpty ||
        rawHeaders is! Map) {
      throw const ImageUploadException('Image upload target was incomplete.');
    }

    final headers = rawHeaders.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );

    await _putImageBytes(
      uploadUrl: uploadUrl,
      bytes: prepared.bytes,
      headers: headers,
      mimeType: prepared.mimeType,
    );

    return imageUrl;
  }

  Future<Map<String, dynamic>> _requestUploadTarget(
    Map<String, dynamic> data,
  ) async {
    if (_createUploadTarget != null) {
      return _createUploadTarget(data);
    }

    final callable = _functions.httpsCallable('createImageUploadTarget');
    final response = await callable.call<Map<String, dynamic>>(data);
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> _putImageBytes({
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
    } on ImageUploadException {
      rethrow;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      throw ImageUploadException(
        status == null
            ? 'Image upload failed.'
            : 'Image upload failed ($status).',
      );
    } catch (_) {
      throw const ImageUploadException('Image upload failed.');
    }
  }
}

String? inferSupportedImageMimeType({
  required String fileName,
  String? mimeType,
}) {
  final mime = mimeType?.trim().toLowerCase();
  if (_supportedImageMimeTypes.contains(mime)) return mime;

  final name = fileName.toLowerCase();
  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.webp')) return 'image/webp';
  if (name.endsWith('.gif')) return 'image/gif';
  return null;
}

const _supportedImageMimeTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
};

_PreparedImage _resizeImageIfNeeded({
  required Uint8List bytes,
  required String mimeType,
  required ImageUploadPreset preset,
}) {
  if (mimeType != 'image/jpeg' && mimeType != 'image/png') {
    return _PreparedImage(bytes: bytes, mimeType: mimeType);
  }

  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    // Fall back to original bytes if decoding/parsing fails
  }
  if (decoded == null) {
    return _PreparedImage(bytes: bytes, mimeType: mimeType);
  }
  if (decoded.width <= preset.maxWidth && decoded.height <= preset.maxHeight) {
    return _PreparedImage(bytes: bytes, mimeType: mimeType);
  }

  final scale = math.min(
    preset.maxWidth / decoded.width,
    preset.maxHeight / decoded.height,
  );
  final width = math.max(1, (decoded.width * scale).round());
  final height = math.max(1, (decoded.height * scale).round());
  final resized = img.copyResize(
    decoded,
    width: width,
    height: height,
    interpolation: img.Interpolation.average,
  );

  if (mimeType == 'image/png') {
    return _PreparedImage(
      bytes: Uint8List.fromList(img.encodePng(resized)),
      mimeType: mimeType,
    );
  }

  return _PreparedImage(
    bytes: Uint8List.fromList(img.encodeJpg(resized, quality: 90)),
    mimeType: mimeType,
  );
}

class _PreparedImage {
  const _PreparedImage({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

class ImageUploadException implements Exception {
  const ImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
