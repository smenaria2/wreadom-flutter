// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(feedRepository)
final feedRepositoryProvider = FeedRepositoryProvider._();

final class FeedRepositoryProvider
    extends $FunctionalProvider<FeedRepository, FeedRepository, FeedRepository>
    with $Provider<FeedRepository> {
  FeedRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedRepositoryHash();

  @$internal
  @override
  $ProviderElement<FeedRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FeedRepository create(Ref ref) {
    return feedRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedRepository>(value),
    );
  }
}

String _$feedRepositoryHash() => r'18b12c8a4906d2bdb01469ab38696644f8b2e9f0';

@ProviderFor(feedPosts)
final feedPostsProvider = FeedPostsProvider._();

final class FeedPostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FeedPost>>,
          List<FeedPost>,
          FutureOr<List<FeedPost>>
        >
    with $FutureModifier<List<FeedPost>>, $FutureProvider<List<FeedPost>> {
  FeedPostsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedPostsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedPostsHash();

  @$internal
  @override
  $FutureProviderElement<List<FeedPost>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FeedPost>> create(Ref ref) {
    return feedPosts(ref);
  }
}

String _$feedPostsHash() => r'ed21944b30b48c09fced0de4bbda2bd7ab88f5c6';

@ProviderFor(userFeedPosts)
final userFeedPostsProvider = UserFeedPostsFamily._();

final class UserFeedPostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FeedPost>>,
          List<FeedPost>,
          FutureOr<List<FeedPost>>
        >
    with $FutureModifier<List<FeedPost>>, $FutureProvider<List<FeedPost>> {
  UserFeedPostsProvider._({
    required UserFeedPostsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userFeedPostsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userFeedPostsHash();

  @override
  String toString() {
    return r'userFeedPostsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FeedPost>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FeedPost>> create(Ref ref) {
    final argument = this.argument as String;
    return userFeedPosts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserFeedPostsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userFeedPostsHash() => r'091b05c0798c9c2f79b53cb067e609a7b97a66ac';

final class UserFeedPostsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<FeedPost>>, String> {
  UserFeedPostsFamily._()
    : super(
        retry: null,
        name: r'userFeedPostsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserFeedPostsProvider call(String userId) =>
      UserFeedPostsProvider._(argument: userId, from: this);

  @override
  String toString() => r'userFeedPostsProvider';
}
