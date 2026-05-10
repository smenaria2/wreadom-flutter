import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

Future<void> shareBookLinkWithCover({
  required String text,
  required String subject,
  required String? coverUrl,
  required String fileNameBase,
}) async {
  final cover = await _downloadShareableCover(coverUrl);
  if (cover == null) {
    await Share.share(text, subject: subject);
    return;
  }

  await Share.shareXFiles(
    [
      XFile.fromData(
        cover.bytes,
        name: '${_safeFilePart(fileNameBase)}-cover.${cover.extension}',
        mimeType: cover.mimeType,
      ),
    ],
    text: text,
    subject: subject,
  );
}

Future<_ShareableCover?> _downloadShareableCover(String? coverUrl) async {
  final url = coverUrl?.trim();
  if (url == null || url.isEmpty) return null;

  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return null;

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    if (response.bodyBytes.isEmpty) return null;

    final mimeType = _imageMimeType(response.headers['content-type']);
    return _ShareableCover(
      bytes: response.bodyBytes,
      mimeType: mimeType,
      extension: _extensionForMimeType(mimeType),
    );
  } catch (_) {
    return null;
  }
}

String _imageMimeType(String? contentType) {
  final normalized = contentType?.split(';').first.trim().toLowerCase();
  if (normalized != null && normalized.startsWith('image/')) {
    return normalized;
  }
  return 'image/jpeg';
}

String _extensionForMimeType(String mimeType) {
  return switch (mimeType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    _ => 'jpg',
  };
}

String _safeFilePart(String value) {
  final safe = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return safe.isEmpty ? 'wreadom' : safe;
}

class _ShareableCover {
  const _ShareableCover({
    required this.bytes,
    required this.mimeType,
    required this.extension,
  });

  final Uint8List bytes;
  final String mimeType;
  final String extension;
}
