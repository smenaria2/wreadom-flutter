import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/comment.dart';
import 'package:librebook_flutter/src/domain/models/feed_post.dart';
import 'package:librebook_flutter/src/domain/models/message.dart';
import 'package:librebook_flutter/src/domain/models/paged_result.dart';
import 'package:librebook_flutter/src/domain/repositories/feed_repository.dart';
import 'package:librebook_flutter/src/presentation/providers/feed_providers.dart';
import 'package:librebook_flutter/src/presentation/utils/message_display_utils.dart';

void main() {
  test('feed controller appends pages and stops when page is short', () async {
    final repo = _FakeFeedRepository();
    final container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWith((ref) => repo)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      pagedFeedPostsProvider(FeedFilter.public),
      (_, _) {},
    );
    addTearDown(subscription.close);

    await _waitFor(() {
      return container
          .read(pagedFeedPostsProvider(FeedFilter.public))
          .items
          .isNotEmpty;
    });
    var state = container.read(pagedFeedPostsProvider(FeedFilter.public));

    expect(state.items.map((post) => post.id), ['p1', 'p2']);
    expect(state.hasMore, isTrue);

    await container
        .read(pagedFeedPostsProvider(FeedFilter.public).notifier)
        .loadMore();
    state = container.read(pagedFeedPostsProvider(FeedFilter.public));

    expect(state.items.map((post) => post.id), ['p1', 'p2', 'p3']);
    expect(state.hasMore, isFalse);
  });

  test('visibleConversations hides conversations without a last message', () {
    final conversations = [
      _conversation('empty'),
      _conversation('active', lastMessage: _lastMessage('hello')),
    ];

    expect(visibleConversations(conversations).map((c) => c.id), ['active']);
  });

  test('message group placement keeps consecutive senders together', () {
    final messages = [
      _message('a', 'one'),
      _message('a', 'two'),
      _message('b', 'three'),
    ];

    expect(messageGroupPlacement(messages, 0).startsGroup, isTrue);
    expect(messageGroupPlacement(messages, 0).continuesGroup, isTrue);
    expect(messageGroupPlacement(messages, 1).startsGroup, isFalse);
    expect(messageGroupPlacement(messages, 1).continuesGroup, isFalse);
    expect(messageGroupPlacement(messages, 2).startsGroup, isTrue);
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 20; i++) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
}

FeedPost _post(String id, int timestamp) {
  return FeedPost(
    id: id,
    userId: 'user',
    username: 'User',
    type: 'post',
    text: 'Post $id',
    timestamp: timestamp,
    likes: const [],
    visibility: 'public',
  );
}

Message _message(String senderId, String text) {
  return Message(
    id: text,
    senderId: senderId,
    senderName: senderId,
    text: text,
    timestamp: 1,
    type: 'text',
    readBy: const [],
  );
}

LastMessageInfo _lastMessage(String text) {
  return LastMessageInfo(
    text: text,
    senderId: 'a',
    timestamp: 1,
    readBy: const [],
  );
}

Conversation _conversation(String id, {LastMessageInfo? lastMessage}) {
  return Conversation(
    id: id,
    participants: const ['a', 'b'],
    participantDetails: const {},
    memberStatus: const {},
    lastMessage: lastMessage,
    type: 'direct',
    createdAt: 1,
    updatedAt: 1,
    createdBy: 'a',
  );
}

class _FakeFeedRepository implements FeedRepository {
  @override
  Future<PagedResult<FeedPost>> getFeedPostsPage({
    int limit = 10,
    Object? cursor,
  }) async {
    if (cursor == null) {
      return PagedResult(
        items: [_post('p1', 3), _post('p2', 2)],
        hasMore: true,
        nextCursor: 'page-2',
      );
    }
    return PagedResult(items: [_post('p3', 1)], hasMore: false);
  }

  @override
  Future<List<FeedPost>> getFeedPosts({int limit = 10, dynamic lastDoc}) async {
    return (await getFeedPostsPage(limit: limit, cursor: lastDoc)).items;
  }

  @override
  Future<PagedResult<FeedPost>> getFollowingFeedPage(
    List<String> followedUserIds, {
    int limit = 10,
    Object? cursor,
  }) async {
    return const PagedResult(items: [], hasMore: false);
  }

  @override
  Future<List<FeedPost>> getFollowingFeed(
    List<String> followedUserIds, {
    int limit = 10,
    dynamic lastDoc,
  }) async {
    return const [];
  }

  @override
  Future<PagedResult<FeedPost>> getUserFeedPostsPage(
    String userId, {
    int limit = 10,
    Object? cursor,
  }) async {
    return const PagedResult(items: [], hasMore: false);
  }

  @override
  Future<List<FeedPost>> getUserFeedPosts(
    String userId, {
    int limit = 10,
    dynamic lastDoc,
  }) async {
    return const [];
  }

  @override
  Future<void> addComment(String postId, Map<String, dynamic> comment) async {}

  @override
  Future<void> addCommentReply(
    String postId,
    String commentId,
    CommentReply reply,
  ) async {}

  @override
  Future<void> createFeedPost(FeedPost post) async {}

  @override
  Future<void> deleteComment(String postId, String commentId) async {}

  @override
  Future<void> deleteFeedPost(String postId) async {}

  @override
  Future<void> deleteReply(
    String postId,
    String commentId,
    String replyId,
  ) async {}

  @override
  Future<FeedPost?> findUserReviewPost({
    required String userId,
    required String bookId,
    String? chapterId,
  }) async {
    return null;
  }

  @override
  Future<FeedPost?> getFeedPost(String postId) async => null;

  @override
  Future<void> toggleCommentLike(
    String postId,
    String commentId,
    String userId,
  ) async {}

  @override
  Future<void> toggleLike(String postId, String userId) async {}

  @override
  Future<void> toggleReplyLike(
    String postId,
    String commentId,
    String replyId,
    String userId,
  ) async {}

  @override
  Future<void> updateCommentText(
    String postId,
    String commentId,
    String text,
  ) async {}

  @override
  Future<void> updateFeedPost(
    String postId,
    Map<String, dynamic> updates,
  ) async {}

  @override
  Future<void> updateReplyText(
    String postId,
    String commentId,
    String replyId,
    String text,
  ) async {}

  @override
  Future<String> uploadPostImage(Uint8List bytes, String fileName) async => '';
}
