import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/widgets/audio_comment_player.dart';
import 'package:librebook_flutter/src/presentation/widgets/audio_post_player.dart';

void main() {
  testWidgets('AudioCommentPlayer displays Play button initially and duration', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AudioCommentPlayer(
              url: 'https://wreadom-audio.smenaria2.workers.dev/audio-reviews/sample.m4a',
              objectKey: 'audio-reviews/sample.m4a',
              durationMs: 45000,
            ),
          ),
        ),
      ),
    );

    // Initial state: Play button visible, Stop button not visible
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle_filled_rounded), findsNothing);
    expect(find.byIcon(Icons.stop_circle_rounded), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('0:00 / 0:45'), findsOneWidget);
  });

  testWidgets('AudioCommentPlayer displays Stop button when active', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Set the audio as active
    container
        .read(activeAudioPostUrlProvider.notifier)
        .setActiveUrl('audio-reviews/sample.m4a', showMiniPlayer: false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: AudioCommentPlayer(
              url: 'https://wreadom-audio.smenaria2.workers.dev/audio-reviews/sample.m4a',
              objectKey: 'audio-reviews/sample.m4a',
              durationMs: 45000,
            ),
          ),
        ),
      ),
    );

    // When active, both Play (or Pause) and Stop buttons should be present
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    expect(find.byIcon(Icons.stop_circle_rounded), findsOneWidget);

    // Tapping Stop should clear the active URL
    await tester.tap(find.byIcon(Icons.stop_circle_rounded));
    await tester.pump();

    expect(container.read(activeAudioPostUrlProvider), isNull);
  });
}
