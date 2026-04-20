import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryUploadService {
  CloudinaryUploadService({
    http.Client? client,
    String cloudName = const String.fromEnvironment('CLOUDINARY_CLOUD_NAME'),
  }) : _client = client ?? http.Client(),
       _cloudName = cloudName;

  static const int maxImageBytes = 10 * 1024 * 1024;
  static const String uploadPreset = 'ml_default';

  final http.Client _client;
  final String _cloudName;

  Future<String> uploadImage({
    required XFile file,
    required String folder,
    required String userId,
  }) async {
    if (_cloudName.trim().isEmpty) {
      throw const CloudinaryUploadException(
        'Cloudinary cloud name is not configured.',
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > maxImageBytes) {
      throw const CloudinaryUploadException('Image must be 10MB or smaller.');
    }
    if (!_isSupportedImage(file)) {
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
          filename: file.name.isEmpty ? 'upload.jpg' : file.name,
        ),
      );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CloudinaryUploadException(
        'Cloudinary upload failed (${response.statusCode}).',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = payload['secure_url'];
    if (secureUrl is! String || secureUrl.trim().isEmpty) {
      throw const CloudinaryUploadException(
        'Cloudinary did not return an image URL.',
      );
    }
    return secureUrl;
  }

  bool _isSupportedImage(XFile file) {
    final mime = file.mimeType?.toLowerCase();
    if (mime != null && mime.startsWith('image/')) return true;
    final name = '${file.name} ${file.path}'.toLowerCase();
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
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
