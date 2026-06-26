// ignore_for_file: unnecessary_null_comparison, dead_code
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:librebook_flutter/src/presentation/widgets/audio_post_player.dart';
import 'package:librebook_flutter/src/presentation/widgets/glass_surface.dart';
import 'package:librebook_flutter/src/utils/app_haptics.dart';

class AudioPostMiniPlayer extends ConsumerWidget {
  const AudioPostMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUrl = ref.watch(activeAudioPostUrlProvider);
    if (activeUrl == null || activeUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final player = ref.watch(audioPostPlayerProvider);

    return StreamBuilder<SequenceState?>(
      stream: player.sequenceStateStream,
      builder: (context, sequenceSnapshot) {
        final sequenceState = sequenceSnapshot.data ?? player.sequenceState;
        if (sequenceState == null) {
          return const SizedBox.shrink();
        }
        final currentSource = sequenceState.currentSource;
        final mediaItem = currentSource?.tag as MediaItem?;

        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 86.0), // Float directly above the bottom navigation bar
            child: GlassSurface(
              strong: true,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // Cover Art / Book Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: mediaItem.artUri != null
                                ? CachedNetworkImage(
                                    imageUrl: mediaItem.artUri.toString(),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const ColoredBox(color: Colors.grey),
                                    errorWidget: (context, url, error) => const Icon(Icons.music_note_rounded),
                                  )
                                : Container(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.music_note_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title / Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                mediaItem.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mediaItem.album ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Play/Pause button
                        StreamBuilder<PlayerState>(
                          stream: player.playerStateStream,
                          builder: (context, stateSnapshot) {
                            final playerState = stateSnapshot.data ?? player.playerState;
                            final playing = playerState.playing;
                            return IconButton(
                              icon: Icon(
                                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                size: 28,
                              ),
                              onPressed: () async {
                                unawaited(AppHaptics.light());
                                if (playing) {
                                  await player.pause();
                                } else {
                                  await player.play();
                                }
                              },
                            );
                          },
                        ),
                        // Close / Stop button
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          onPressed: () async {
                            unawaited(AppHaptics.light());
                            await player.stop();
                            ref.read(activeAudioPostUrlProvider.notifier).setActiveUrl(null);
                          },
                        ),
                      ],
                    ),
                  ),
                  // Progress indicator
                  StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, posSnapshot) {
                      final position = posSnapshot.data ?? player.position;
                      final duration = player.duration ?? Duration.zero;
                      final double progress = duration.inMilliseconds > 0
                          ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                          : 0.0;
                      return SizedBox(
                        height: 3,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
