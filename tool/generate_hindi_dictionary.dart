import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

const String kDakshinaPinnedVersion = 'v1.0';
const String kDakshinaPinnedSha256 =
    '83530bec211893d9df429298f42e63c350c25ad56f9f5172f85edb0575ee5b03';
const String kDakshinaDownloadUrl =
    'https://storage.googleapis.com/gresearch/dakshina/dakshina_dataset_v1.0.tar';

/// Validates whether a TSV row has valid structure: at least 3 parts,
/// non-empty Devanagari & Roman, and a positive integer attestation count.
bool isValidTsvRow(List<String> parts) {
  if (parts.length < 3) return false;
  final devanagari = parts[0].trim();
  final roman = parts[1].trim();
  final countStr = parts[2].trim();
  if (devanagari.isEmpty || roman.isEmpty) return false;
  final count = int.tryParse(countStr);
  return count != null && count > 0;
}

/// Parses TSV lines and aggregates attestation counts for duplicate
/// (normalized Roman, Devanagari) pairs into [aggregated].
void parseTsvLines(
  Iterable<String> lines,
  Map<String, Map<String, int>> aggregated,
) {
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final parts = trimmed.split('\t');
    if (!isValidTsvRow(parts)) continue;

    final devanagari = parts[0].trim();
    final roman = parts[1].trim();
    final count = int.parse(parts[2].trim());

    final normalizedRoman = roman.toLowerCase();
    final candidatesMap = aggregated.putIfAbsent(normalizedRoman, () => {});
    candidatesMap[devanagari] = (candidatesMap[devanagari] ?? 0) + count;
  }
}

/// Ranks candidates per Roman key by attestation count descending, breaking
/// ties with stable Unicode code-point order, and keeps the top [maxCandidates].
Map<String, List<String>> buildSortedDictionary(
  Map<String, Map<String, int>> aggregated, {
  int maxCandidates = 4,
}) {
  final dictionary = <String, List<String>>{};
  final sortedKeys = aggregated.keys.toList()..sort();

  for (final key in sortedKeys) {
    final candidateMap = aggregated[key]!;
    final entries = candidateMap.entries.toList();

    entries.sort((a, b) {
      final countCmp = b.value.compareTo(a.value); // Count descending
      if (countCmp != 0) return countCmp;
      return a.key.compareTo(b.key); // Lexical ascending for ties
    });

    dictionary[key] =
        entries.take(maxCandidates).map((e) => e.key).toList(growable: false);
  }

  return dictionary;
}

/// Generates a deterministic const Dart lookup file with dataset metadata.
String generateDartCode({
  required String version,
  required String sha256,
  required Map<String, List<String>> dictionary,
}) {
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// Pinned Dakshina Dataset Version: $version');
  buffer.writeln('// Dataset SHA-256 Checksum: $sha256');
  buffer.writeln();
  buffer.writeln("const String kDakshinaVersion = '$version';");
  buffer.writeln("const String kDakshinaSha256 = '$sha256';");
  buffer.writeln();
  buffer.writeln(
      '/// Pre-compiled Roman-Hindi to Devanagari dictionary generated from Dakshina lexicon splits.');
  buffer.writeln(
      'const Map<String, List<String>> kHindiDictionary = <String, List<String>>{');

  final keys = dictionary.keys.toList()..sort();
  for (final key in keys) {
    final escapedKey = key.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    final candidates = dictionary[key]!;
    final escapedCandidates = candidates
        .map((c) => "'${c.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'")
        .join(', ');
    buffer.writeln("  '$escapedKey': [$escapedCandidates],");
  }

  buffer.writeln('};');
  return buffer.toString();
}

Future<void> main(List<String> args) async {
  final checkOnly = args.contains('--check');

  // Check local cache locations
  final cacheDir = Directory('.dakshina_cache');
  if (!cacheDir.existsSync()) {
    cacheDir.createSync(recursive: true);
  }
  final tarFile = File('${cacheDir.path}/dakshina_dataset_v1.0.tar');
  final tmpTarFile = File('tmp_dakshina.tar');

  List<int> tarBytes;
  if (tarFile.existsSync()) {
    tarBytes = tarFile.readAsBytesSync();
  } else if (tmpTarFile.existsSync()) {
    tarBytes = tmpTarFile.readAsBytesSync();
    // Copy to cache for future runs
    tarFile.writeAsBytesSync(tarBytes);
  } else {
    stdout.writeln('Downloading Dakshina dataset from $kDakshinaDownloadUrl...');
    final response = await http.get(Uri.parse(kDakshinaDownloadUrl));
    if (response.statusCode != 200) {
      stderr.writeln('Failed to download dataset. HTTP status: ${response.statusCode}');
      exit(1);
    }
    tarBytes = response.bodyBytes;
    tarFile.writeAsBytesSync(tarBytes);
  }

  stdout.writeln('Verifying dataset SHA-256 checksum...');
  final calculatedSha256 = sha256.convert(tarBytes).toString().toLowerCase();
  if (calculatedSha256 != kDakshinaPinnedSha256) {
    stderr.writeln(
        'SHA-256 checksum mismatch! Expected: $kDakshinaPinnedSha256, Got: $calculatedSha256');
    exit(1);
  }
  stdout.writeln('Checksum verified successfully.');

  stdout.writeln('Extracting and parsing Hindi lexicon splits...');
  final archive = TarDecoder().decodeBytes(tarBytes);
  final aggregated = <String, Map<String, int>>{};

  int splitCount = 0;
  for (final file in archive) {
    if (file.isFile &&
        (file.name.contains('/hi/lexicons/hi.translit.sampled.') ||
            file.name.contains('hi/lexicons/hi.translit.sampled.')) &&
        file.name.endsWith('.tsv')) {
      splitCount++;
      stdout.writeln('Processing Hindi lexicon split: ${file.name}');
      final content = utf8.decode(file.content as List<int>);
      parseTsvLines(content.split('\n'), aggregated);
    }
  }

  stdout.writeln('Processed $splitCount splits. Aggregated ${aggregated.length} Roman keys.');

  final dictionary = buildSortedDictionary(aggregated);
  final generatedCode = generateDartCode(
    version: kDakshinaPinnedVersion,
    sha256: kDakshinaPinnedSha256,
    dictionary: dictionary,
  );

  final targetFile = File('lib/src/data/services/generated_hindi_dictionary.dart');

  if (checkOnly) {
    if (!targetFile.existsSync()) {
      stderr.writeln('Error: Generated dictionary file does not exist.');
      exit(1);
    }
    final existingContent = targetFile.readAsStringSync();
    if (existingContent != generatedCode) {
      stderr.writeln('Error: Generated dictionary file is stale or out of date.');
      exit(1);
    }
    stdout.writeln('Generated dictionary is up-to-date.');
    exit(0);
  } else {
    targetFile.writeAsStringSync(generatedCode);
    stdout.writeln(
        'Successfully wrote generated dictionary to ${targetFile.path} (${dictionary.length} keys).');
  }
}
