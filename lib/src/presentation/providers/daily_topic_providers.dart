import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/homepage/homepage_metadata.dart';
import 'homepage_providers.dart';
import 'dart:async';

class DailyTopicsNotifier extends AsyncNotifier<List<DailyTopic>> {
  int _limit = 3;

  @override
  FutureOr<List<DailyTopic>> build() async {
    final metadata = await ref.watch(homepageMetadataProvider.future);
    final metadataTopics = metadata.dailyTopics.where((t) => t.isEnabled).toList();
    final remoteTopics = await _fetchRemoteTopics();
    final allTopics = _mergeTopics(remoteTopics, metadataTopics);
    
    return allTopics.take(_limit).toList();
  }

  Future<void> fetchMore() async {
    if (state.isLoading || !state.hasValue) return;
    
    final metadata = await ref.read(homepageMetadataProvider.future);
    final metadataTopics = metadata.dailyTopics.where((t) => t.isEnabled).toList();
    final remoteTopics = await _fetchRemoteTopics();
    final allTopics = _mergeTopics(remoteTopics, metadataTopics);
    
    if (_limit >= allTopics.length) return;
    
    _limit += 3;
    state = AsyncValue.data(allTopics.take(_limit).toList());
  }

  Future<List<DailyTopic>> _fetchRemoteTopics() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('daily-topics')
          .where('isEnabled', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return DailyTopic.fromJson(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  List<DailyTopic> _mergeTopics(
    List<DailyTopic> primary,
    List<DailyTopic> fallback,
  ) {
    final byKey = <String, DailyTopic>{};
    for (final topic in [...fallback, ...primary]) {
      final key = topic.id.isNotEmpty ? topic.id : topic.topicName;
      if (key.isNotEmpty) byKey[key] = topic;
    }
    return byKey.values.where((topic) => topic.isEnabled).toList();
  }
}

final dailyTopicsProvider = AsyncNotifierProvider<DailyTopicsNotifier, List<DailyTopic>>(() {
  return DailyTopicsNotifier();
});
