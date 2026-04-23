import 'package:cloud_firestore/cloud_firestore.dart';

/// Recursively ensures all maps are `Map<String, dynamic>` to avoid subtype errors
/// when parsing data from Firestore or local storage (Hive).
dynamic ensureStringMap(dynamic data) {
  if (data is Map) {
    if (data is Map<String, dynamic>) {
      // Still need to check nested values
      final Map<String, dynamic> newMap = {};
      for (final entry in data.entries) {
        newMap[entry.key] = ensureStringMap(entry.value);
      }
      return newMap;
    }

    final Map<String, dynamic> newMap = {};
    for (final entry in data.entries) {
      newMap[entry.key.toString()] = ensureStringMap(entry.value);
    }
    return newMap;
  } else if (data is List) {
    return data.map((e) => ensureStringMap(e)).toList();
  } else if (data is Timestamp) {
    // Keep timestamps as is, or convert if needed.
    // Most models expect int (milliseconds) or Timestamp.
    return data;
  }
  return data;
}

/// A safe way to cast a map to `Map<String, dynamic>`
Map<String, dynamic> asStringMap(dynamic data) {
  if (data == null) return {};
  if (data is! Map) return {};
  return ensureStringMap(data) as Map<String, dynamic>;
}
