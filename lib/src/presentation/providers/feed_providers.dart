import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/firebase_feed_repository.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/models/feed_post.dart';

part 'feed_providers.g.dart';

@riverpod
FeedRepository feedRepository(Ref ref) {
  return FirebaseFeedRepository();
}

@riverpod
Future<List<FeedPost>> feedPosts(Ref ref) async {
  return ref.watch(feedRepositoryProvider).getFeedPosts();
}

@riverpod
Future<List<FeedPost>> userFeedPosts(Ref ref, String userId) async {
  return ref.watch(feedRepositoryProvider).getUserFeedPosts(userId);
}
