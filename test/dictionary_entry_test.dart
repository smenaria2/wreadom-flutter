import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/dictionary_entry.dart';

void main() {
  test('parses structured entries and sense-specific translations', () {
    final result = DictionaryLookupResult.fromJson({
      'word': 'bank',
      'entries': [
        {
          'language': {'code': 'en', 'name': 'English'},
          'partOfSpeech': 'noun',
          'pronunciations': [
            {'type': 'ipa', 'text': '/bæŋk/'},
          ],
          'senses': [
            {
              'definition': 'A financial institution.',
              'examples': ['I deposited money at the bank.'],
              'translations': [
                {
                  'language': {'code': 'hi', 'name': 'Hindi'},
                  'word': 'बैंक',
                },
              ],
            },
          ],
        },
      ],
      'source': {
        'url': 'https://en.wiktionary.org/wiki/bank',
        'license': {
          'name': 'CC BY-SA 4.0',
          'url': 'https://creativecommons.org/licenses/by-sa/4.0/',
        },
      },
    });

    expect(result.word, 'bank');
    expect(result.entries.single.partOfSpeech, 'noun');
    expect(result.entries.single.pronunciations.single, '/bæŋk/');
    expect(
      result.entries.single.senses.single.translations.single.word,
      'बैंक',
    );
  });

  test('rejects responses without usable entries', () {
    expect(
      () => DictionaryLookupResult.fromJson({'word': 'missing', 'entries': []}),
      throwsA(
        isA<DictionaryFailure>().having(
          (failure) => failure.type,
          'type',
          DictionaryFailureType.invalidResponse,
        ),
      ),
    );
  });
}
