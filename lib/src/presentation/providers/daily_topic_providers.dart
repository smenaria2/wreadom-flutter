import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/homepage/homepage_metadata.dart';
import 'homepage_providers.dart';
import 'dart:async';

class DailyTopicsNotifier extends AsyncNotifier<List<DailyTopic>> {
  int _limit = 3;

  @override
  FutureOr<List<DailyTopic>> build() async {
    final metadata = await ref.watch(homepageMetadataProvider.future);
    final allTopics = metadata.dailyTopics.where((t) => t.isEnabled).toList();
    
    return allTopics.take(_limit).toList();
  }

  Future<void> fetchMore() async {
    if (state.isLoading || !state.hasValue) return;
    
    final metadata = await ref.read(homepageMetadataProvider.future);
    final allTopics = metadata.dailyTopics.where((t) => t.isEnabled).toList();
    
    if (_limit >= allTopics.length) return;
    
    _limit += 3;
    state = AsyncValue.data(allTopics.take(_limit).toList());
  }
}

final dailyTopicsProvider = AsyncNotifierProvider<DailyTopicsNotifier, List<DailyTopic>>(() {
  return DailyTopicsNotifier();
});
