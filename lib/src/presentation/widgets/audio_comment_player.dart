import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../utils/cloudflare_audio_resolver.dart';
import 'audio_post_player.dart';

/// Compact audio player for comment and review voice notes.
///
/// Shares the singleton audio player with background playback support
/// but isolates its controls locally without opening the feed mini-player.
class AudioCommentPlayer extends ConsumerStatefulWidget {
  const AudioCommentPlayer({
    super.key,
    required this.url,
    this.objectKey,
    this.durationMs,
    this.textColor,
    this.metadataColor,
  });

  final String url;
  final String? objectKey;
  final int? durationMs;
  final Color? textColor;
  final Color? metadataColor;

  @override
  ConsumerState<AudioCommentPlayer> createState() => _AudioCommentPlayerState();
}

class _AudioCommentPlayerState extends ConsumerState<AudioCommentPlayer> {
  late final AudioPlayer _player;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = ref.read(audioPostPlayerProvider);
  }

  @override
  void didUpdateWidget(covariant AudioCommentPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.objectKey != widget.objectKey) {
      _error = null;
    }
  }

  String? get _audioIdentity {
    final objectKey = widget.objectKey?.trim();
    if (objectKey != null && objectKey.isNotEmpty) return objectKey;
    final url = widget.url.trim();
    return url.isEmpty ? null : url;
  }

  Duration? get _metadataDuration {
    final milliseconds = widget.durationMs;
    return milliseconds == null || milliseconds <= 0
        ? null
        : Duration(milliseconds: milliseconds);
  }

  void _handlePlaybackFailure(Object error, StackTrace stack) {
    debugPrint(
      'Error playing audio in AudioCommentPlayer: '
      '${sanitizeAudioPlaybackError(error)}\n$stack',
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = 'Could not play audio';
    });
  }

  Future<void> _play() async {
    final audioIdentity = _audioIdentity;
    if (audioIdentity == null) return;

    final isCurrent = ref.read(activeAudioPostUrlProvider) == audioIdentity;
    if (isCurrent && _player.playing) return;

    if (isCurrent &&
        !_player.playing &&
        _player.processingState != ProcessingState.completed) {
      await _player.play();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await toggleSharedNetworkAudio(
        ref,
        audioIdentity: audioIdentity,
        showInMiniPlayer: false,
        resolveRequest: (forceRefresh) => resolveCloudflareAudioRequest(
          objectKey: widget.objectKey,
          url: widget.url,
          forceRefreshToken: forceRefresh,
        ),
        createSource: (request) => createCloudflareAudioSource(
          request: request,
          mediaItem: MediaItem(
            id: audioIdentity,
            album: 'Audio Review',
            title: 'Audio review',
            duration: _metadataDuration,
            extras: const {'sourceType': 'audioReview'},
          ),
        ),
      );
    } catch (e, stack) {
      _handlePlaybackFailure(e, stack);
    } finally {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pause() async {
    final audioIdentity = _audioIdentity;
    if (audioIdentity == null) return;
    final isCurrent = ref.read(activeAudioPostUrlProvider) == audioIdentity;
    if (isCurrent && _player.playing) {
      await _player.pause();
    }
  }

  Future<void> _stop() async {
    final audioIdentity = _audioIdentity;
    if (audioIdentity == null) return;
    final isCurrent = ref.read(activeAudioPostUrlProvider) == audioIdentity;
    if (isCurrent) {
      ref.read(activeAudioPostUrlProvider.notifier).setActiveUrl(null);
      unawaited(_player.pause());
      unawaited(_player.seek(Duration.zero));
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrent = ref.watch(activeAudioPostUrlProvider) == _audioIdentity;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final isPlaying = isCurrent &&
                    state?.playing == true &&
                    state?.processingState != ProcessingState.completed;
                final isBuffering = isCurrent &&
                    (state?.processingState == ProcessingState.loading ||
                        state?.processingState == ProcessingState.buffering) &&
                    state?.processingState != ProcessingState.completed;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Dedicated Play / Pause Button
                    IconButton(
                      tooltip: isPlaying ? 'Pause audio' : 'Play audio',
                      visualDensity: VisualDensity.compact,
                      onPressed: isPlaying ? _pause : _play,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),

                    // 2. Dedicated Stop Button (shown when current active review)
                    if (isCurrent)
                      IconButton(
                        tooltip: 'Stop audio',
                        visualDensity: VisualDensity.compact,
                        onPressed: _stop,
                        icon: Icon(
                          Icons.stop_circle_rounded,
                          color: theme.colorScheme.primary.withValues(alpha: 0.8),
                          size: 24,
                        ),
                      ),

                    // 3. Separate Loading Indicator
                    if (isCurrent && (_loading || isBuffering))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 4),
            StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final fallback = Duration(milliseconds: widget.durationMs ?? 0);
                final position = isCurrent
                    ? snapshot.data ?? Duration.zero
                    : Duration.zero;
                final duration = isCurrent
                    ? _player.duration ?? fallback
                    : fallback;
                final label = duration.inMilliseconds > 0
                    ? '${_formatAudioTime(position)} / ${_formatAudioTime(duration)}'
                    : 'Audio review';
                return Text(
                  _error ?? label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _error == null
                        ? widget.metadataColor ?? widget.textColor
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

String _formatAudioTime(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 120).toInt();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
