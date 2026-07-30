import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/services/devlipi_hindi_engine.dart';
import 'package:librebook_flutter/src/data/services/generated_hindi_dictionary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Evaluate Hindi Dictionary Top-1 accuracy and Top-3 weighted coverage', () async {
    final cacheDir = Directory('.dakshina_cache');
    final tarFile = File('${cacheDir.path}/dakshina_dataset_v1.0.tar');
    final tmpTarFile = File('tmp_dakshina.tar');

    File fileToRead;
    if (tarFile.existsSync()) {
      fileToRead = tarFile;
    } else if (tmpTarFile.existsSync()) {
      fileToRead = tmpTarFile;
    } else {
      fail('Dataset file not found for evaluation.');
    }

    stdout.writeln('Reading dataset archive for evaluation: ${fileToRead.path}');
    final tarBytes = fileToRead.readAsBytesSync();
    final archive = TarDecoder().decodeBytes(tarBytes);

    final aggregated = <String, Map<String, int>>{};

    int splitCount = 0;
    for (final file in archive) {
      if (file.isFile &&
          (file.name.contains('/hi/lexicons/hi.translit.sampled.') ||
              file.name.contains('hi/lexicons/hi.translit.sampled.')) &&
          file.name.endsWith('.tsv')) {
        splitCount++;
        stdout.writeln('Loading split: ${file.name}');
        final content = utf8.decode(file.content as List<int>);
        for (final line in content.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          final parts = trimmed.split('\t');
          if (parts.length < 3) continue;
          final devanagari = parts[0].trim();
          final roman = parts[1].trim();
          final count = int.tryParse(parts[2].trim()) ?? 0;
          if (devanagari.isEmpty || roman.isEmpty || count <= 0) continue;

          final key = roman.toLowerCase();
          final map = aggregated.putIfAbsent(key, () => {});
          map[devanagari] = (map[devanagari] ?? 0) + count;
        }
      }
    }

    stdout.writeln('Loaded $splitCount splits (${aggregated.length} total Roman keys).');

    const engine = DevlipiHindiEngine();

    int totalDictionaryKeysEvaluated = 0;
    int rankOneCorrect = 0;

    int totalWeightedCount = 0;
    int topThreeWeightedMatches = 0;

    for (final entry in aggregated.entries) {
      final romanKey = entry.key;
      final devanagariCounts = entry.value;

      if (!kHindiDictionary.containsKey(romanKey)) continue;

      totalDictionaryKeysEvaluated++;

      final sortedDevanagari = devanagariCounts.entries.toList()
        ..sort((a, b) {
          final c = b.value.compareTo(a.value);
          if (c != 0) return c;
          return a.key.compareTo(b.key);
        });

      final topAttestedDevanagari = sortedDevanagari.first.key;

      final suggestions = engine.transliterateToken(romanKey);

      if (suggestions.isNotEmpty && suggestions.first == topAttestedDevanagari) {
        rankOneCorrect++;
      }

      final topThreeSuggestions = suggestions.take(3).toSet();
      for (final devEntry in devanagariCounts.entries) {
        final devWord = devEntry.key;
        final count = devEntry.value;
        totalWeightedCount += count;
        if (topThreeSuggestions.contains(devWord)) {
          topThreeWeightedMatches += count;
        }
      }
    }

    final rankOneAccuracy = totalDictionaryKeysEvaluated > 0
        ? (rankOneCorrect / totalDictionaryKeysEvaluated) * 100
        : 0.0;
    final weightedTopThreeCoverage = totalWeightedCount > 0
        ? (topThreeWeightedMatches / totalWeightedCount) * 100
        : 0.0;

    stdout.writeln('--------------------------------------------------');
    stdout.writeln('Evaluation Results:');
    stdout.writeln('Total Dictionary-Covered Keys Evaluated: $totalDictionaryKeysEvaluated');
    stdout.writeln(
        'Rank-1 Highest-Attested Accuracy: ${rankOneAccuracy.toStringAsFixed(2)}% ($rankOneCorrect / $totalDictionaryKeysEvaluated)');
    stdout.writeln(
        'Weighted Top-3 Coverage: ${weightedTopThreeCoverage.toStringAsFixed(2)}% ($topThreeWeightedMatches / $totalWeightedCount)');
    stdout.writeln('--------------------------------------------------');

    expect(rankOneAccuracy, equals(100.0),
        reason: 'Rank-1 must return the highest-attested candidate for all dictionary keys.');
    expect(weightedTopThreeCoverage, greaterThanOrEqualTo(90.0),
        reason: 'Weighted top-3 coverage must be at least 90%.');
  });
}
