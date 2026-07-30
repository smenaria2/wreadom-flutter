import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/services/generated_hindi_dictionary.dart';
import '../../tool/generate_hindi_dictionary.dart' as generator;

void main() {
  group('Hindi Dictionary Generator Unit Tests', () {
    test('isValidTsvRow identifies valid and invalid TSV rows', () {
      expect(generator.isValidTsvRow(['नमस्ते', 'namaste', '10']), isTrue);
      expect(generator.isValidTsvRow(['नमस्ते', 'namaste']), isFalse);
      expect(generator.isValidTsvRow(['', 'namaste', '10']), isFalse);
      expect(generator.isValidTsvRow(['नमस्ते', '', '10']), isFalse);
      expect(generator.isValidTsvRow(['नमस्ते', 'namaste', 'abc']), isFalse);
      expect(generator.isValidTsvRow(['नमस्ते', 'namaste', '-5']), isFalse);
      expect(generator.isValidTsvRow(['नमस्ते', 'namaste', '0']), isFalse);
    });

    test('parseTsvLines normalizes Roman keys and aggregates attestation counts', () {
      final lines = [
        'नमस्ते\tnamaste\t5',
        'नमस्ते\tNamaste \t3',
        'नमस्कर\tnamaste\t2',
        'invalid row without tabs',
        'भारत\tbharat\t10',
      ];
      final aggregated = <String, Map<String, int>>{};
      generator.parseTsvLines(lines, aggregated);

      expect(aggregated.containsKey('namaste'), isTrue);
      expect(aggregated['namaste']!['नमस्ते'], equals(8));
      expect(aggregated['namaste']!['नमस्कर'], equals(2));
      expect(aggregated['bharat']!['भारत'], equals(10));
    });

    test('buildSortedDictionary ranks by count desc, ties lexically, and limits to top 4', () {
      final aggregated = {
        'test': {
          'द': 5,
          'अ': 10,
          'ब': 10,
          'ग': 8,
          'इ': 3,
          'फ': 1,
        }
      };

      final dict = generator.buildSortedDictionary(aggregated, maxCandidates: 4);
      expect(dict['test']!.length, equals(4));
      // Expected order: 'अ' (count 10, lex asc), 'ब' (count 10, lex asc), 'ग' (count 8), 'द' (count 5)
      expect(dict['test'], equals(['अ', 'ब', 'ग', 'द']));
    });

    test('generateDartCode formats deterministic code with metadata', () {
      final dict = {
        'abc': ['अ', 'ब'],
        'xyz': ['क'],
      };
      final code = generator.generateDartCode(
        version: 'v1.0',
        sha256: 'testsha256',
        dictionary: dict,
      );

      expect(code, contains('// Pinned Dakshina Dataset Version: v1.0'));
      expect(code, contains('// Dataset SHA-256 Checksum: testsha256'));
      expect(code, contains("const String kDakshinaVersion = 'v1.0';"));
      expect(code, contains("const String kDakshinaSha256 = 'testsha256';"));
      expect(code, contains("'abc': ['अ', 'ब'],"));
      expect(code, contains("'xyz': ['क'],"));
    });

    test('Checked-in dictionary metadata matches pinned values', () {
      expect(kDakshinaVersion, equals('v1.0'));
      expect(kDakshinaSha256, equals(generator.kDakshinaPinnedSha256));
    });

    test('--check mode detects stale dictionary content', () {
      final tempFile = File('test/unit/fixtures_temp_dict.dart');
      try {
        tempFile.writeAsStringSync('stale content');
        final code = generator.generateDartCode(
          version: 'v1.0',
          sha256: 'testsha256',
          dictionary: {'a': ['अ']},
        );
        expect(tempFile.readAsStringSync() == code, isFalse);
      } finally {
        if (tempFile.existsSync()) tempFile.deleteSync();
      }
    });
  });
}
