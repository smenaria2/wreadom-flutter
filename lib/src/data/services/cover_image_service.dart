import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:librebook_flutter/src/config/env_config.dart';

class CoverImageService {
  final String _unsplashAccessKey;

  CoverImageService({String? unsplashAccessKey})
      : _unsplashAccessKey = unsplashAccessKey ?? EnvConfig.unsplashAccessKey;

  /// Translates a given title to English using Lingva Translate.
  /// Falls back to the original title if translation fails.
  Future<String> translateTitle(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'untitled story') {
      return 'story';
    }

    final translateUrl = Uri.parse(
      'https://lingva.ml/api/v1/auto/en/${Uri.encodeComponent(trimmed)}',
    );

    try {
      final response = await http.get(translateUrl).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['translation'] != null) {
          return data['translation'].toString();
        }
      }
    } catch (_) {
      // Fallback silently to original title
    }
    return trimmed;
  }

  /// Searches Unsplash for images matching [query].
  /// Returns a list of image URLs (limited to 3 images).
  Future<List<String>> searchImages(String query) async {
    if (_unsplashAccessKey.isEmpty) {
      return const [];
    }

    final unsplashUrl = Uri.parse(
      'https://api.unsplash.com/search/photos?query=${Uri.encodeComponent(query)}&per_page=3&orientation=portrait',
    );

    try {
      final response = await http.get(
        unsplashUrl,
        headers: {
          'Authorization': 'Client-ID $_unsplashAccessKey',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        if (results != null) {
          return results
              .map((item) => item['urls']?['regular'] as String?)
              .whereType<String>()
              .toList();
        }
      }
    } catch (_) {
      // Return empty list on failure
    }
    return const [];
  }
}
