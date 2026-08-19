import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/widgets/audio_post_player.dart';

void main() {
  test('autoplay action is idempotent and preserves playback position', () {
    expect(
      audioPostPlaybackActionFor(
        activeIdentity: 'audio-a',
        loadedIdentity: 'audio-a',
        requestedIdentity: 'audio-a',
        isPlaying: true,
        isCompleted: false,
      ),
      AudioPostPlaybackAction.none,
    );
    expect(
      audioPostPlaybackActionFor(
        activeIdentity: 'audio-a',
        loadedIdentity: 'audio-a',
        requestedIdentity: 'audio-a',
        isPlaying: false,
        isCompleted: false,
      ),
      AudioPostPlaybackAction.resume,
    );
    expect(
      audioPostPlaybackActionFor(
        activeIdentity: 'audio-a',
        loadedIdentity: 'audio-a',
        requestedIdentity: 'audio-a',
        isPlaying: false,
        isCompleted: true,
      ),
      AudioPostPlaybackAction.restart,
    );
    expect(
      audioPostPlaybackActionFor(
        activeIdentity: 'audio-a',
        loadedIdentity: 'audio-a',
        requestedIdentity: 'audio-b',
        isPlaying: true,
        isCompleted: false,
      ),
      AudioPostPlaybackAction.load,
    );
  });

  test('reel and post detail opt into one-shot guarded autoplay', () {
    final player = File(
      'lib/src/presentation/widgets/audio_post_player.dart',
    ).readAsStringSync();
    final reel = File(
      'lib/src/presentation/components/reel_post_content.dart',
    ).readAsStringSync();
    final detail = File(
      'lib/src/presentation/screens/post_detail_screen.dart',
    ).readAsStringSync();

    expect(player, contains('ensureAudioPostPlaying'));
    expect(player, contains('_autoPlayAttempted'));
    expect(player, contains('_audioPostRequestGeneration'));
    expect(player, contains('_isLatestAudioPostRequest'));
    expect(reel, contains('autoPlay: isActive'));
    expect(detail, contains('autoPlayAudio: true'));
  });

  test('audio reviews reuse the single coordinated background player', () {
    final source = File(
      'lib/src/presentation/widgets/comment_widgets.dart',
    ).readAsStringSync();

    expect(source, contains('ref.read(audioPostPlayerProvider)'));
    expect(source, contains('toggleSharedNetworkAudio('));
    expect(source, isNot(contains('AudioPlayer(useProxyForRequestHeaders')));
    expect(source, isNot(contains('_player.dispose()')));
  });
}
