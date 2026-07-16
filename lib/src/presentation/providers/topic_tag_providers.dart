import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String cleanTopicTag(String value) => value
    .replaceAll(RegExp(r'_+'), ' ')
    .replaceAll(RegExp(r'[#"]'), '')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');

String normalizeTopicTag(String value) => cleanTopicTag(value).toLowerCase();

List<String> _rankTopicTags(
  Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
) {
  final ranked = documents.toList()
    ..sort((a, b) {
      final usageComparison = ((b.data()['usageCount'] as num?)?.toInt() ?? 0)
          .compareTo((a.data()['usageCount'] as num?)?.toInt() ?? 0);
      if (usageComparison != 0) return usageComparison;
      return (a.data()['normalizedName']?.toString() ?? '').compareTo(
        b.data()['normalizedName']?.toString() ?? '',
      );
    });

  return ranked
      .map((doc) => doc.data()['displayName']?.toString().trim() ?? '')
      .where((tag) => tag.isNotEmpty)
      .take(8)
      .toList(growable: false);
}

final popularTopicTagsProvider = FutureProvider<List<String>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('topic-tags')
      .orderBy('usageCount', descending: true)
      .limit(8)
      .get();
  return _rankTopicTags(snapshot.docs);
});

final topicTagSuggestionsProvider = FutureProvider.family<List<String>, String>(
  (ref, rawQuery) async {
    final query = normalizeTopicTag(rawQuery);
    if (query.isEmpty) return const [];

    final snapshot = await FirebaseFirestore.instance
        .collection('topic-tags')
        .orderBy('normalizedName')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(24)
        .get();

    return _rankTopicTags(snapshot.docs);
  },
);
