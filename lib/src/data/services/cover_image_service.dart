import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:librebook_flutter/src/config/env_config.dart';

class CoverImageService {
  final String _unsplashAccessKey;
  final http.Client _httpClient;

  CoverImageService({String? unsplashAccessKey, http.Client? httpClient})
    : _unsplashAccessKey = unsplashAccessKey ?? EnvConfig.unsplashAccessKey,
      _httpClient = httpClient ?? http.Client();

  /// Translates a given title to English using Google Translate API.
  /// Falls back to the original title if translation fails.
  Future<String> translateTitle(String title) async {
    final trimmed = _repairMojibake(title).trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'untitled story') {
      return 'story';
    }

    final translateUrl = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=en&dt=t&q=${Uri.encodeComponent(trimmed)}',
    );

    try {
      final response = await _httpClient
          .get(translateUrl)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty && data[0] is List) {
          final sentences = data[0] as List;
          final buffer = StringBuffer();
          for (final sentence in sentences) {
            if (sentence is List &&
                sentence.isNotEmpty &&
                sentence[0] != null) {
              buffer.write(sentence[0].toString());
            }
          }
          if (buffer.isNotEmpty) {
            final translated = buffer.toString().trim();
            if (translated.isNotEmpty && translated != trimmed) {
              return translated;
            }
          }
        }
      }
    } catch (_) {
      // Fallback silently to original title
    }
    return _fallbackSearchQuery(trimmed);
  }

  /// Searches Unsplash for images matching [query].
  /// Returns a list of image URLs (limited to 3 images).
  Future<List<String>> searchImages(String query) async {
    if (_unsplashAccessKey.isEmpty) {
      return const [];
    }

    final searchQuery = _fallbackSearchQuery(_repairMojibake(query).trim());

    final unsplashUrl = Uri.parse(
      'https://api.unsplash.com/search/photos?query=${Uri.encodeComponent(searchQuery)}&per_page=3&orientation=portrait',
    );

    try {
      final response = await _httpClient
          .get(
            unsplashUrl,
            headers: {'Authorization': 'Client-ID $_unsplashAccessKey'},
          )
          .timeout(const Duration(seconds: 8));

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

  String _fallbackSearchQuery(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'untitled story') {
      return 'story';
    }
    if (_containsDevanagari(trimmed) || _looksLikeMojibake(trimmed)) {
      return 'hindi book cover story';
    }
    return trimmed;
  }

  String _repairMojibake(String value) {
    if (!_looksLikeMojibake(value)) return value;
    try {
      return utf8.decode(value.codeUnits, allowMalformed: false);
    } catch (_) {
      return value;
    }
  }

  bool _containsDevanagari(String value) {
    return RegExp(r'[\u0900-\u097F]').hasMatch(value);
  }

  bool _looksLikeMojibake(String value) {
    return RegExp(r'[ÃÂàâ][\u0080-\u00FF]').hasMatch(value);
  }
}
