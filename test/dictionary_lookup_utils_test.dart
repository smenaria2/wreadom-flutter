import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/utils/dictionary_lookup_utils.dart';

void main() {
  group('normalizeSelectedDictionaryWord', () {
    test('accepts one word and trims punctuation', () {
      expect(normalizeSelectedDictionaryWord('“hello,”'), 'hello');
      expect(normalizeSelectedDictionaryWord("don't"), "don't");
      expect(normalizeSelectedDictionaryWord('well-being'), 'well-being');
      expect(normalizeSelectedDictionaryWord('किताब'), 'किताब');
    });

    test('rejects multiple words', () {
      expect(normalizeSelectedDictionaryWord('hello world'), isNull);
      expect(normalizeSelectedDictionaryWord('hello\nworld'), isNull);
    });
  });

  test('normalizes book language metadata', () {
    expect(normalizeDictionaryLanguageCode(['English']), 'en');
    expect(normalizeDictionaryLanguageCode(['hin']), 'hi');
    expect(normalizeDictionaryLanguageCode(['Arabic']), 'ar');
    expect(normalizeDictionaryLanguageCode(const []), 'en');
  });
}
