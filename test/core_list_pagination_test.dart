import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/comment.dart';
import 'package:librebook_flutter/src/domain/models/feed_post.dart';
import 'package:librebook_flutter/src/domain/models/message.dart';
import 'package:librebook_flutter/src/domain/models/paged_result.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';
import 'package:librebook_flutter/src/domain/repositories/feed_repository.dart';
import 'package:librebook_flutter/src/domain/repositories/follow_repository.dart';
import 'package:librebook_flutter/src/domain/repositories/message_repository.dart';
import 'package:librebook_flutter/src/presentation/providers/auth_providers.dart';
import 'package:librebook_flutter/src/presentation/providers/feed_providers.dart';
import 'package:librebook_flutter/src/presentation/providers/follow_providers.dart';
import 'package:librebook_flutter/src/presentation/providers/message_providers.dart';
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

  test(
    'following feed controller uses followed ids and timestamp cursor',
    () async {
      final repo = _FakeFeedRepository(
        followingPages: [
          PagedResult(
            items: [_post('f1', 30), _post('f2', 20)],
            hasMore: true,
            nextCursor: 20,
          ),
          PagedResult(items: [_post('f3', 10)], hasMore: false),
        ],
      );
      final followRepo = _FakeFollowRepository(
        fullFollowingList: const ['author-1'],
      );
      final container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWith((ref) => repo),
          followRepositoryProvider.overrideWithValue(followRepo),
          currentUserProvider.overrideWith(
            (ref) => Stream.value(_user('viewer')),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        pagedFeedPostsProvider(FeedFilter.following),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await _waitFor(() {
        return container
            .read(pagedFeedPostsProvider(FeedFilter.following))
            .items
            .isNotEmpty;
      });

      await container
          .read(pagedFeedPostsProvider(FeedFilter.following).notifier)
          .loadMore();
      final state = container.read(
        pagedFeedPostsProvider(FeedFilter.following),
      );

      expect(state.items.map((post) => post.id), ['f1', 'f2', 'f3']);
      expect(repo.followingRequests.length, 2);
      expect(repo.followingRequests[0].ids, ['author-1']);
      expect(repo.followingRequests[0].cursor, isNull);
      expect(repo.followingRequests[1].ids, ['author-1']);
      expect(repo.followingRequests[1].cursor, 20);
    },
  );

  test('following feed keeps empty state when user follows nobody', () async {
    final repo = _FakeFeedRepository();
    final followRepo = _FakeFollowRepository(fullFollowingList: const []);
    final container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWith((ref) => repo),
        followRepositoryProvider.overrideWithValue(followRepo),
        currentUserProvider.overrideWith(
          (ref) => Stream.value(_user('viewer')),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      pagedFeedPostsProvider(FeedFilter.following),
      (_, _) {},
    );
    addTearDown(subscription.close);

    await _waitFor(() {
      return !container
              .read(pagedFeedPostsProvider(FeedFilter.following))
              .isInitialLoading &&
          !container.read(pagedFeedPostsProvider(FeedFilter.following)).hasMore;
    });

    final state = container.read(pagedFeedPostsProvider(FeedFilter.following));
    expect(state.items, isEmpty);
    expect(state.hasMore, isFalse);
  });

  test(
    'following feed ignores repeated auth readiness for same user',
    () async {
      final repo = _FakeFeedRepository(
        followingPages: [
          PagedResult(items: [_post('f1', 10)], hasMore: false),
        ],
      );
      final followRepo = _FakeFollowRepository(
        fullFollowingList: const ['author-1'],
      );
      final users = StreamController<UserModel?>();
      addTearDown(users.close);
      final container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWith((ref) => repo),
          followRepositoryProvider.overrideWithValue(followRepo),
          currentUserProvider.overrideWith((ref) => users.stream),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        pagedFeedPostsProvider(FeedFilter.following),
        (_, _) {},
      );
      addTearDown(subscription.close);

      users.add(_user('viewer'));
      await _waitFor(() {
        return container
            .read(pagedFeedPostsProvider(FeedFilter.following))
            .items
            .isNotEmpty;
      });

      users.add(_user('viewer'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repo.followingRequests.length, 1);
      expect(followRepo.fullFollowingListRequests, ['viewer']);
    },
  );

  test('following feed surfaces repository timeout errors', () async {
    final repo = _FakeFeedRepository(throwOnFollowing: true);
    final followRepo = _FakeFollowRepository(
      fullFollowingList: const ['author-1'],
    );
    final container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWith((ref) => repo),
        followRepositoryProvider.overrideWithValue(followRepo),
        currentUserProvider.overrideWith(
          (ref) => Stream.value(_user('viewer')),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      pagedFeedPostsProvider(FeedFilter.following),
      (_, _) {},
    );
    addTearDown(subscription.close);

    await _waitFor(() {
      return container
              .read(pagedFeedPostsProvider(FeedFilter.following))
              .error !=
          null;
    });

    final state = container.read(pagedFeedPostsProvider(FeedFilter.following));
    expect(state.isInitialLoading, isFalse);
    expect(state.error, isA<TimeoutException>());
  });

  test('mine feed resets when signed-in account changes', () async {
    final repo = _FakeFeedRepository(
      userPages: {
        'user-a': [
          PagedResult(items: [_postForUser('a1', 'user-a')], hasMore: false),
        ],
        'user-b': [
          PagedResult(items: [_postForUser('b1', 'user-b')], hasMore: false),
        ],
      },
    );
    final users = StreamController<UserModel?>();
    addTearDown(users.close);
    final container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWith((ref) => repo),
        currentUserProvider.overrideWith((ref) => users.stream),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      pagedFeedPostsProvider(FeedFilter.mine),
      (_, _) {},
    );
    addTearDown(subscription.close);

    users.add(_user('user-a'));
    await _waitFor(() {
      return container
          .read(pagedFeedPostsProvider(FeedFilter.mine))
          .items
          .map((post) => post.id)
          .contains('a1');
    });

    users.add(_user('user-b'));
    await _waitFor(() {
      return container
          .read(pagedFeedPostsProvider(FeedFilter.mine))
          .items
          .map((post) => post.id)
          .contains('b1');
    });

    final state = container.read(pagedFeedPostsProvider(FeedFilter.mine));
    expect(state.items.map((post) => post.id), ['b1']);
    expect(repo.userFeedRequests.first, 'user-a');
    expect(repo.userFeedRequests.last, 'user-b');
  });

  test('follow list controller appends paged relationship ids', () async {
    final repo = _FakeFollowRepository(
      followingPages: const [
        PagedResult(items: ['u1', 'u2'], hasMore: true, nextCursor: 'page-2'),
        PagedResult(items: ['u3'], hasMore: false),
      ],
      followersPages: const [],
    );
    final query = const FollowListQuery(
      userId: 'viewer',
      type: FollowListType.following,
    );
    final container = ProviderContainer(
      overrides: [followRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      pagedFollowListProvider(query),
      (_, _) {},
    );
    addTearDown(subscription.close);

    await _waitFor(() {
      return container.read(pagedFollowListProvider(query)).items.isNotEmpty;
    });
    var state = container.read(pagedFollowListProvider(query));

    expect(state.items, ['u1', 'u2']);
    expect(state.hasMore, isTrue);

    await container.read(pagedFollowListProvider(query).notifier).loadMore();
    state = container.read(pagedFollowListProvider(query));

    expect(state.items, ['u1', 'u2', 'u3']);
    expect(state.hasMore, isFalse);
    expect(repo.followingRequests, [
      (userId: 'viewer', cursor: null),
      (userId: 'viewer', cursor: 'page-2'),
    ]);
  });

  test('isFollowingProvider uses direct relationship lookup', () async {
    final repo = _FakeFollowRepository(isFollowingResult: true);
    final container = ProviderContainer(
      overrides: [
        followRepositoryProvider.overrideWithValue(repo),
        currentUserProvider.overrideWith(
          (ref) => Stream.value(_user('viewer')),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      isFollowingProvider('author'),
      (_, _) {},
    );
    addTearDown(subscription.close);

    await _waitFor(() => repo.isFollowingRequests.isNotEmpty);
    final result = container.read(isFollowingProvider('author')).value;

    expect(result, isTrue);
    expect(repo.isFollowingRequests, [
      (followerId: 'viewer', followingId: 'author'),
    ]);
    expect(repo.fullFollowingListRequests, isEmpty);
  });

  test('visibleConversations hides empty and user-hidden conversations', () {
    final conversations = [
      _conversation('empty'),
      _conversation('active', lastMessage: _lastMessage('hello')),
      _conversation(
        'hidden',
        lastMessage: _lastMessage('quiet'),
        deletedFor: const ['viewer'],
      ),
    ];

    expect(
      visibleConversations(
        conversations,
        hiddenForUserId: 'viewer',
      ).map((c) => c.id),
      ['active'],
    );
  });

  test('conversation parses direct chat quota and hide state', () {
    final conversation = Conversation.fromJson({
      'id': 'direct_a_b',
      'participants': ['a', 'b'],
      'participantDetails': <String, dynamic>{},
      'memberStatus': <String, String>{'a': 'accepted', 'b': 'accepted'},
      'lastMessage': {
        'text': 'hello',
        'senderId': 'a',
        'timestamp': 1,
        'readBy': ['a'],
      },
      'type': 'direct',
      'createdAt': 1,
      'updatedAt': 2,
      'createdBy': 'a',
      'firstMessageSenderId': 'a',
      'recipientHasReplied': true,
      'deletedFor': ['a'],
    });

    expect(conversation.firstMessageSenderId, 'a');
    expect(conversation.recipientHasReplied, isTrue);
    expect(conversation.deletedFor, ['a']);
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

  test('paged conversations reset when signed-in account changes', () async {
    final repo = _FakeMessageRepository();
    final users = StreamController<UserModel?>();
    addTearDown(users.close);
    final container = ProviderContainer(
      overrides: [
        messageRepositoryProvider.overrideWithValue(repo),
        currentUserProvider.overrideWith((ref) => users.stream),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      pagedConversationsProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    users.add(_user('user-a'));
    await _waitFor(() {
      return container
          .read(pagedConversationsProvider)
          .items
          .map((conversation) => conversation.id)
          .contains('conversation-user-a');
    });

    users.add(_user('user-b'));
    await _waitFor(() {
      return container
          .read(pagedConversationsProvider)
          .items
          .map((conversation) => conversation.id)
          .contains('conversation-user-b');
    });

    final state = container.read(pagedConversationsProvider);
    expect(state.items.map((conversation) => conversation.id), [
      'conversation-user-b',
    ]);
    expect(repo.conversationPageRequests, ['user-a', 'user-b']);
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
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

FeedPost _postForUser(String id, String userId) {
  return FeedPost(
    id: id,
    userId: userId,
    username: userId,
    type: 'post',
    text: 'Post $id',
    timestamp: 1,
    likes: const [],
    visibility: 'public',
  );
}

UserModel _user(String id) {
  return UserModel(
    id: id,
    username: id,
    email: '$id@example.com',
    readingHistory: const [],
    savedBooks: const [],
    bookmarks: const [],
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

Conversation _conversation(
  String id, {
  LastMessageInfo? lastMessage,
  List<String> deletedFor = const [],
}) {
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
    deletedFor: deletedFor,
  );
}

class _FakeFeedRepository implements FeedRepository {
  _FakeFeedRepository({
    this.followingPages = const [],
    this.userPages = const {},
    this.throwOnFollowing = false,
  });

  final List<PagedResult<FeedPost>> followingPages;
  final Map<String, List<PagedResult<FeedPost>>> userPages;
  final bool throwOnFollowing;
  final followingRequests = <({List<String> ids, Object? cursor})>[];
  final userFeedRequests = <String>[];
  int _followingPageIndex = 0;
  final _userPageIndexes = <String, int>{};

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
    followingRequests.add((ids: followedUserIds, cursor: cursor));
    if (throwOnFollowing) {
      throw TimeoutException('following feed timed out');
    }
    if (followingPages.isEmpty) {
      return const PagedResult(items: [], hasMore: false);
    }
    return followingPages[_followingPageIndex++ >= followingPages.length
        ? followingPages.length - 1
        : _followingPageIndex - 1];
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
    userFeedRequests.add(userId);
    final pages = userPages[userId];
    if (pages == null || pages.isEmpty) {
      return const PagedResult(items: [], hasMore: false);
    }
    final index = _userPageIndexes[userId] ?? 0;
    _userPageIndexes[userId] = index + 1;
    return pages[index >= pages.length ? pages.length - 1 : index];
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

  @override
  Future<List<String>> getActiveQuestions() async => const [];
}

class _FakeMessageRepository implements MessageRepository {
  final conversationPageRequests = <String>[];

  @override
  Future<void> blockUserInConversation({
    required String conversationId,
    required String blockedUserId,
  }) async {}

  @override
  Future<void> deleteConversationForUser({
    required String conversationId,
    required String userId,
  }) async {}

  @override
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
    required String userId,
  }) async {}

  @override
  Future<String> getOrCreateDirectConversation({
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    return 'conversation-${currentUser.id}';
  }

  @override
  Future<PagedResult<Conversation>> getConversationsPage(
    String userId, {
    int limit = 25,
    Object? cursor,
  }) async {
    conversationPageRequests.add(userId);
    return PagedResult(
      items: [
        _conversation(
          'conversation-$userId',
          lastMessage: _lastMessage('hello $userId'),
        ),
      ],
      hasMore: false,
    );
  }

  @override
  Future<PagedResult<Message>> getMessagesPage(
    String conversationId, {
    int limit = 25,
    Object? cursor,
  }) async {
    return const PagedResult(items: [], hasMore: false);
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required UserModel sender,
    required String text,
  }) async {}

  @override
  Future<void> sendStoryMessage({
    required String conversationId,
    required UserModel sender,
    required MessageStoryData storyData,
  }) async {}

  @override
  Stream<Conversation?> watchConversation(String conversationId) {
    return Stream.value(null);
  }

  @override
  Stream<List<Conversation>> watchConversations(String userId) {
    return Stream.value(const []);
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return Stream.value(const []);
  }
}

class _FakeFollowRepository implements FollowRepository {
  _FakeFollowRepository({
    this.followingPages = const [],
    this.followersPages = const [],
    this.fullFollowingList = const [],
    this.isFollowingResult = false,
  });

  final List<PagedResult<String>> followingPages;
  final List<PagedResult<String>> followersPages;
  final List<String> fullFollowingList;
  final bool isFollowingResult;
  final followingRequests = <({String userId, Object? cursor})>[];
  final followersRequests = <({String userId, Object? cursor})>[];
  final isFollowingRequests = <({String followerId, String followingId})>[];
  final fullFollowingListRequests = <String>[];
  int _followingPageIndex = 0;
  int _followersPageIndex = 0;

  @override
  Future<void> followUser({
    required String followerId,
    required String followingId,
  }) async {}

  @override
  Future<PagedResult<String>> getFollowersPage(
    String followingId, {
    int limit = 20,
    Object? cursor,
  }) async {
    followersRequests.add((userId: followingId, cursor: cursor));
    if (followersPages.isEmpty) {
      return const PagedResult(items: [], hasMore: false);
    }
    return followersPages[_followersPageIndex++ >= followersPages.length
        ? followersPages.length - 1
        : _followersPageIndex - 1];
  }

  @override
  Future<List<String>> getFollowersList(String followingId) async => const [];

  @override
  Future<PagedResult<String>> getFollowingPage(
    String followerId, {
    int limit = 20,
    Object? cursor,
  }) async {
    followingRequests.add((userId: followerId, cursor: cursor));
    if (followingPages.isEmpty) {
      return const PagedResult(items: [], hasMore: false);
    }
    return followingPages[_followingPageIndex++ >= followingPages.length
        ? followingPages.length - 1
        : _followingPageIndex - 1];
  }

  @override
  Future<List<String>> getFollowingList(String followerId) async {
    fullFollowingListRequests.add(followerId);
    return fullFollowingList;
  }

  @override
  Future<bool> isFollowing(String followerId, String followingId) async {
    isFollowingRequests.add((followerId: followerId, followingId: followingId));
    return isFollowingResult;
  }

  @override
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {}
}
