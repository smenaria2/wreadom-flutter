import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/homepage/homepage_metadata.dart';
import 'homepage_providers.dart';
import 'theme_provider.dart';

const _dailyTopicsCacheKey = 'daily_topics_cache_v1';

bool _dailyTopicsBackgroundRefreshQueued = false;

class DailyTopicsNotifier extends AsyncNotifier<List<DailyTopic>> {
  int _limit = 3;
  List<DailyTopic> _allTopics = const [];

  @override
  FutureOr<List<DailyTopic>> build() async {
    final metadata = await ref.watch(homepageMetadataProvider.future);
    final metadataTopics = metadata.dailyTopics
        .where((t) => t.isEnabled)
        .toList();
    final cachedTopics = _readCachedTopics();
    _allTopics = _mergeTopics(cachedTopics, metadataTopics);
    _queueBackgroundRefresh(metadataTopics);

    return _allTopics.take(_limit).toList();
  }

  Future<void> fetchMore() async {
    if (state.isLoading || !state.hasValue) return;

    if (_allTopics.isEmpty) {
      final metadata = await ref.read(homepageMetadataProvider.future);
      _allTopics = _mergeTopics(_readCachedTopics(), metadata.dailyTopics);
    }

    if (_limit >= _allTopics.length) return;

    _limit += 3;
    state = AsyncValue.data(_allTopics.take(_limit).toList());
  }

  Future<DailyTopic?> findTopicById(String? topicId) async {
    final topics = await _ensureAllTopics();
    if (topics.isEmpty) return null;

    final normalizedTopicId = _normalizedTopicKey(topicId);
    if (normalizedTopicId == null) return topics.first;

    for (final topic in topics) {
      if (_normalizedTopicKey(topic.id) == normalizedTopicId ||
          _normalizedTopicKey(topic.topicName) == normalizedTopicId) {
        return topic;
      }
    }

    return _fetchRemoteTopic(topicId!.trim());
  }

  Future<List<DailyTopic>> _ensureAllTopics() async {
    if (_allTopics.isNotEmpty) return _allTopics;
    final metadata = await ref.read(homepageMetadataProvider.future);
    _allTopics = _mergeTopics(_readCachedTopics(), metadata.dailyTopics);
    return _allTopics;
  }

  List<DailyTopic> _readCachedTopics() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_dailyTopicsCacheKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((topic) => DailyTopic.fromJson(Map<String, dynamic>.from(topic)))
          .where((topic) => topic.isEnabled)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeCachedTopics(List<DailyTopic> topics) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final json = topics.map(_topicCacheJson).toList();
    await prefs.setString(_dailyTopicsCacheKey, jsonEncode(json));
  }

  Map<String, Object?> _topicCacheJson(DailyTopic topic) {
    return {
      'id': topic.id,
      'topicName': topic.topicName,
      'description': topic.description,
      'fullDescription': topic.fullDescription,
      'coverImageUrl': topic.coverImageUrl,
      'isEnabled': topic.isEnabled,
      'timestamp': topic.sortTimestamp,
    };
  }

  void _queueBackgroundRefresh(List<DailyTopic> metadataTopics) {
    if (_dailyTopicsBackgroundRefreshQueued) return;
    _dailyTopicsBackgroundRefreshQueued = true;
    unawaited(_refreshRemoteTopics(metadataTopics));
  }

  Future<void> _refreshRemoteTopics(List<DailyTopic> metadataTopics) async {
    try {
      final remoteTopics = await _fetchRemoteTopics();
      if (remoteTopics == null) return;

      await _writeCachedTopics(remoteTopics);
      _allTopics = _mergeTopics(remoteTopics, metadataTopics);
      if (ref.mounted && state.hasValue) {
        state = AsyncValue.data(_allTopics.take(_limit).toList());
      }
    } finally {
      Timer(const Duration(minutes: 5), () {
        _dailyTopicsBackgroundRefreshQueued = false;
      });
    }
  }

  Future<List<DailyTopic>?> _fetchRemoteTopics() async {
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
      return null;
    }
  }

  Future<DailyTopic?> _fetchRemoteTopic(String topicId) async {
    final normalizedTopicId = _normalizedTopicKey(topicId);
    if (normalizedTopicId == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('daily-topics')
          .doc(topicId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;
        final topic = DailyTopic.fromJson(data);
        return topic.isEnabled ? topic : null;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('daily-topics')
          .where('topicName', isEqualTo: topicId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final data = Map<String, dynamic>.from(snapshot.docs.first.data());
      data['id'] = snapshot.docs.first.id;
      final topic = DailyTopic.fromJson(data);
      return topic.isEnabled ? topic : null;
    } catch (_) {
      return null;
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
    return byKey.values.where((topic) => topic.isEnabled).toList()
      ..sort((a, b) => b.sortTimestamp.compareTo(a.sortTimestamp));
  }
}

String? _normalizedTopicKey(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  try {
    return Uri.decodeComponent(trimmed).trim().toLowerCase();
  } catch (_) {
    return trimmed.trim().toLowerCase();
  }
}

final dailyTopicsProvider =
    AsyncNotifierProvider<DailyTopicsNotifier, List<DailyTopic>>(() {
      return DailyTopicsNotifier();
    });
