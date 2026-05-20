import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/constants/cloudinary_constants.dart';

class CloudinaryUploadService {
  CloudinaryUploadService({http.Client? client, String? cloudName})
    : _client = client ?? http.Client(),
      _cloudName = cloudName ?? CloudinaryConstants.cloudName;

  static const int maxImageBytes = 10 * 1024 * 1024;
  static const String uploadPreset = CloudinaryConstants.uploadPreset;

  final http.Client _client;
  final String _cloudName;

  Future<String> uploadImage({
    required XFile file,
    required String folder,
    required String userId,
    String deliveryTransform = 'f_auto,q_auto,w_1200,c_limit',
  }) async {
    final bytes = await file.readAsBytes();
    return uploadImageBytes(
      bytes: bytes,
      fileName: file.name.isEmpty ? 'upload.jpg' : file.name,
      folder: folder,
      userId: userId,
      mimeType: file.mimeType,
      deliveryTransform: deliveryTransform,
    );
  }

  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    required String userId,
    String? mimeType,
    String deliveryTransform = 'f_auto,q_auto,w_1200,c_limit',
  }) async {
    if (_cloudName.trim().isEmpty) {
      throw const CloudinaryUploadException(
        'Cloudinary cloud name is not configured.',
      );
    }
    if (uploadPreset.trim().isEmpty) {
      throw const CloudinaryUploadException(
        'Cloudinary upload preset is not configured.',
      );
    }

    if (bytes.length > maxImageBytes) {
      throw const CloudinaryUploadException('Image must be 10MB or smaller.');
    }
    if (!_isSupportedImage(fileName: fileName, mimeType: mimeType)) {
      throw const CloudinaryUploadException(
        'Please choose a PNG, JPEG, WebP, GIF, HEIC, or AVIF image.',
      );
    }

    final endpoint = Uri.https(
      'api.cloudinary.com',
      '/v1_1/${_cloudName.trim()}/image/upload',
    );
    final request = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'librebook/$folder'
      ..fields['tags'] = 'user_id_$userId'
      ..fields['context'] = 'uploader_id=$userId'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName.trim().isEmpty ? 'upload.jpg' : fileName,
        ),
      );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final reason = _cloudinaryErrorMessage(response.body);
      throw CloudinaryUploadException(
        reason == null
            ? 'Cloudinary upload failed (${response.statusCode}).'
            : 'Cloudinary upload failed (${response.statusCode}): $reason',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = payload['secure_url'];
    if (secureUrl is! String || secureUrl.trim().isEmpty) {
      throw const CloudinaryUploadException(
        'Cloudinary did not return an image URL.',
      );
    }
    return _withDeliveryTransform(secureUrl, deliveryTransform);
  }

  bool _isSupportedImage({required String fileName, String? mimeType}) {
    final mime = mimeType?.toLowerCase();
    if (mime != null && mime.startsWith('image/')) return true;
    final name = fileName.toLowerCase();
    return const [
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.gif',
      '.heic',
      '.heif',
      '.avif',
    ].any(name.contains);
  }

  String? _cloudinaryErrorMessage(String body) {
    try {
      final payload = jsonDecode(body) as Map<String, dynamic>;
      final error = payload['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _withDeliveryTransform(String url, String transform) {
    final cleanTransform = transform.trim();
    if (cleanTransform.isEmpty || !url.contains('/image/upload/')) return url;
    if (url.contains('/upload/$cleanTransform/')) return url;
    return url.replaceFirst('/upload/', '/upload/$cleanTransform/');
  }
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
