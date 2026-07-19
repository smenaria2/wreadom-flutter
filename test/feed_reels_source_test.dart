import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';

void main() {
  final source = File(
    'lib/src/presentation/screens/feed_reels_screen.dart',
  ).readAsStringSync();

  final rendererSource = File(
    'lib/src/presentation/components/reel_post_content.dart',
  ).readAsStringSync();
  final reelButtonSource = File(
    'lib/src/presentation/widgets/reel_feed_button.dart',
  ).readAsStringSync();

  test('reel route is public and distinct from the standard feed', () {
    expect(AppRoutes.feedReels, '/feed-reels');
    expect(source, contains('FeedFilter.public'));
    expect(source, contains('PageView.builder'));
    expect(source, contains('ReelPostContent'));
    expect(source, isNot(contains('child: FeedPostCard')));
    expect(source, isNot(contains('ValueKey(_playbackGeneration)')));
    expect(source, contains('scrollDirection: Axis.horizontal'));
  });

  test('reel uses simple paging and a reduced-motion-aware entry button', () {
    expect(rendererSource, contains('SingleChildScrollView'));
    expect(source, contains('_SwipeGuide'));
    expect(source, contains('viewportFraction: .96'));
    expect(source, contains('AnimatedScale'));
    expect(source, contains('AnimatedOpacity'));
    expect(source, isNot(contains('BookPageTurn')));
    expect(source, isNot(contains('rotateY(')));
    expect(
      reelButtonSource,
      contains('MediaQuery.disableAnimationsOf(context)'),
    );
  });

  test('reel includes social, comment preview, and playback coordination', () {
    expect(source, contains('latestFeedPostCommentProvider'));
    expect(source, contains('showFeedPostCommentsSheet'));
    expect(rendererSource, contains('onDoubleTap: onDoubleTap'));
    expect(source, contains('activeAudioPostUrlProvider.notifier'));
    expect(source, contains(r"reel-content-${post.id}-$isActive"));
    expect(source, contains("'feed_reel_share'"));
  });
}
