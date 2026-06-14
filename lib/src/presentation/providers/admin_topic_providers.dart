import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/homepage/homepage_metadata.dart';
import 'daily_topic_providers.dart';
import 'homepage_providers.dart';

final adminDailyTopicsProvider = StreamProvider<List<DailyTopic>>((ref) {
  return FirebaseFirestore.instance
      .collection('daily-topics')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return DailyTopic.fromJson(data);
        }).toList(),
      );
});

final adminDailyTopicControllerProvider = Provider<AdminDailyTopicController>((
  ref,
) {
  return AdminDailyTopicController(ref);
});

class AdminDailyTopicController {
  AdminDailyTopicController(this._ref);

  final Ref _ref;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('daily-topics');

  Future<void> saveTopic(DailyTopic topic) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final data = _topicData(topic, now);
    if (topic.id.trim().isEmpty) {
      await _collection.add({
        ...data,
        'timestamp': topic.sortTimestamp > 0 ? topic.sortTimestamp : now,
      });
    } else {
      await _collection.doc(topic.id).set({
        ...data,
        'id': topic.id,
        'timestamp': topic.sortTimestamp > 0 ? topic.sortTimestamp : now,
      });
    }
    await _refreshTopicCaches();
  }

  Future<void> setEnabled(DailyTopic topic, bool isEnabled) async {
    if (topic.id.trim().isEmpty) return;
    await _collection.doc(topic.id).update({
      'isEnabled': isEnabled,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    });
    await _refreshTopicCaches();
  }

  Future<void> deleteTopic(DailyTopic topic) async {
    if (topic.id.trim().isEmpty) return;
    await _collection.doc(topic.id).delete();
    await _refreshTopicCaches();
  }

  Map<String, Object?> _topicData(DailyTopic topic, int now) {
    return {
      'topicName': topic.topicName.trim(),
      'description': topic.description.trim(),
      'fullDescription': topic.fullDescription.trim(),
      'coverImageUrl': topic.coverImageUrl.trim(),
      'isEnabled': topic.isEnabled,
      'lastUpdated': now,
    };
  }

  Future<void> _refreshTopicCaches() async {
    _ref.invalidate(adminDailyTopicsProvider);
    _ref.invalidate(homepageMetadataProvider);
    await _ref.read(dailyTopicsProvider.notifier).refreshNow();
  }
}
