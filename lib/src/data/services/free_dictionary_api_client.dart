import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/dictionary_entry.dart';

class FreeDictionaryApiClient {
  FreeDictionaryApiClient({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> lookup({
    required String word,
    required String language,
    required bool includeTranslations,
  }) async {
    final uri = Uri.https(
      'freedictionaryapi.com',
      '/api/v1/entries/$language/$word',
      {'translations': '$includeTranslations'},
    );
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      switch (response.statusCode) {
        case 200:
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) return decoded;
          throw const DictionaryFailure(DictionaryFailureType.invalidResponse);
        case 404:
          throw const DictionaryFailure(DictionaryFailureType.wordNotFound);
        case 429:
          throw const DictionaryFailure(DictionaryFailureType.rateLimited);
        default:
          throw DictionaryFailure(
            DictionaryFailureType.serviceUnavailable,
            'Dictionary service returned ${response.statusCode}',
          );
      }
    } on DictionaryFailure {
      rethrow;
    } on TimeoutException {
      throw const DictionaryFailure(DictionaryFailureType.timeout);
    } on FormatException {
      throw const DictionaryFailure(DictionaryFailureType.invalidResponse);
    } on http.ClientException {
      throw const DictionaryFailure(DictionaryFailureType.offline);
    }
  }

  void close() => _client.close();
}
