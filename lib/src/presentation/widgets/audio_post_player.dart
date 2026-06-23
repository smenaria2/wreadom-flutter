import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:librebook_flutter/src/utils/app_haptics.dart';

import '../../domain/models/feed_post.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import 'glass_surface.dart';

class ActiveAudioPostUrl extends Notifier<String?> {
  @override
  String? build() => null;

  void setActiveUrl(String? url) {
    state = url;
  }
}

final activeAudioPostUrlProvider = NotifierProvider<ActiveAudioPostUrl, String?>(ActiveAudioPostUrl.new);

class AudioPostPlayer extends ConsumerStatefulWidget {
  const AudioPostPlayer({
    super.key,
    required this.post,
  });

  final FeedPost post;

  @override
  ConsumerState<AudioPostPlayer> createState() => _AudioPostPlayerState();
}

class _AudioPostPlayerState extends ConsumerState<AudioPostPlayer>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  late final AnimationController _rotationController;
  
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _error;

  double _playbackSpeed = 1.0;
  bool _wasPlayingBeforeDrag = false;
  double _dragStartValue = 0.0;
  double _dragCurrentValue = 0.0;
  double _hapticAccumulator = 0.0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Sync player speed with local state
    _player.setSpeed(_playbackSpeed);

    // Stop rotation when audio is not playing
    _player.playerStateStream.listen((state) {
      if (state.playing && state.processingState != ProcessingState.completed) {
        if (!_rotationController.isAnimating) {
          _rotationController.repeat();
        }
      } else {
        _rotationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final audioUrl = widget.post.audioUrl;
    if (audioUrl == null || audioUrl.isEmpty) return;

    if (_player.playing) {
      await _player.pause();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Update globally active audio post URL to pause others
      ref.read(activeAudioPostUrlProvider.notifier).setActiveUrl(audioUrl);

      if (!_isLoaded) {
        await _player.setUrl(audioUrl);
        _isLoaded = true;
      }

      await _player.play();
    } catch (e) {
      setState(() {
        _error = 'Could not load audio';
      });
      debugPrint('Error playing feed post audio: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _cycleSpeed() {
    final speeds = [1.0, 1.25, 1.5, 2.0];
    final nextIndex = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    setState(() {
      _playbackSpeed = speeds[nextIndex];
    });
    _player.setSpeed(_playbackSpeed);
    AppHaptics.light();
  }

  // Horizontal Swipe seek handlers on vinyl disc
  void _onDragStart(DragStartDetails details, Duration totalDuration) {
    if (totalDuration == Duration.zero) return;
    _wasPlayingBeforeDrag = _player.playing;
    if (_wasPlayingBeforeDrag) {
      _player.pause();
    }
    _dragStartValue = _player.position.inMilliseconds.toDouble();
    _dragCurrentValue = _dragStartValue;
    _hapticAccumulator = 0.0;
  }

  void _onDragUpdate(DragUpdateDetails details, Duration totalDuration) {
    if (totalDuration == Duration.zero) return;
    // Map horizontal movement (pixels) to milliseconds
    // Dragging 1px seeks by ~25ms
    final double deltaMs = details.delta.dx * 25.0 * _playbackSpeed;
    final double maxMs = totalDuration.inMilliseconds.toDouble();
    
    _dragCurrentValue = (_dragCurrentValue + deltaMs).clamp(0.0, maxMs);

    // Rotate visual controller manually during drag
    final double rotationDelta = details.delta.dx / 100.0;
    _rotationController.value = (_rotationController.value + rotationDelta) % 1.0;

    // Trigger haptics periodically during drag
    _hapticAccumulator += details.delta.dx.abs();
    if (_hapticAccumulator >= 12.0) {
      AppHaptics.light();
      _hapticAccumulator = 0.0;
    }

    // Live seek during drag for interactive feedback
    _player.seek(Duration(milliseconds: _dragCurrentValue.toInt()));
  }

  void _onDragEnd(DragEndDetails details) {
    if (_wasPlayingBeforeDrag) {
      _player.play();
    }
    AppHaptics.medium();
  }

  void _navigateToBook(BuildContext context) {
    final bookId = widget.post.bookId?.toString();
    if (bookId != null && bookId.isNotEmpty) {
      Navigator.of(context).pushNamed(
        AppRoutes.bookDetail,
        arguments: BookDetailArguments(bookId: bookId),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audioUrl = widget.post.audioUrl;

    if (audioUrl == null || audioUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    // Auto-pause if another post in the feed starts playing
    final activePlayingUrl = ref.watch(activeAudioPostUrlProvider);
    if (activePlayingUrl != audioUrl && _player.playing) {
      _player.pause();
    }

    final coverUrl = widget.post.audioCoverUrl ?? widget.post.bookCover;
    final isBookReferred = widget.post.bookId != null;

    final defaultDuration = Duration(milliseconds: widget.post.audioDurationMs ?? 0);

    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, posSnapshot) {
        final position = posSnapshot.data ?? Duration.zero;
        final totalDuration = _player.duration ?? defaultDuration;

        return StreamBuilder<PlayerState>(
          stream: _player.playerStateStream,
          builder: (context, stateSnapshot) {
            final playerState = stateSnapshot.data;
            final isPlaying = playerState?.playing ?? false;
            final isBuffering = playerState?.processingState == ProcessingState.buffering ||
                playerState?.processingState == ProcessingState.loading;

            return GlassSurface(
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: [
                  // ─── TACTILE VINYL DISC ──────────────────────
                  GestureDetector(
                    onHorizontalDragStart: (details) => _onDragStart(details, totalDuration),
                    onHorizontalDragUpdate: (details) => _onDragUpdate(details, totalDuration),
                    onHorizontalDragEnd: _onDragEnd,
                    onTap: () {
                      if (isBookReferred) {
                        _navigateToBook(context);
                      }
                    },
                    child: RotationTransition(
                      turns: _rotationController,
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          gradient: const RadialGradient(
                            colors: [
                              Color(0xFF2C2C2C),
                              Color(0xFF151515),
                              Color(0xFF000000),
                            ],
                            stops: [0.0, 0.7, 1.0],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Concentric vinyl grooves (concentric borders)
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  width: 1.0,
                                ),
                              ),
                            ),
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  width: 1.0,
                                ),
                              ),
                            ),
                            // Clip cover art in the center
                            ClipOval(
                              child: coverUrl != null && coverUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: coverUrl,
                                      width: 42,
                                      height: 42,
                                      fit: BoxFit.cover,
                                      placeholder: (_, _) => Container(
                                        color: Colors.grey.shade900,
                                        child: const Icon(Icons.music_note_rounded,
                                            color: Colors.white24, size: 20),
                                      ),
                                      errorWidget: (_, _, _) => Container(
                                        color: Colors.grey.shade900,
                                        child: const Icon(Icons.music_note_rounded,
                                            color: Colors.white24, size: 20),
                                      ),
                                    )
                                  : Container(
                                      color: theme.colorScheme.primaryContainer,
                                      width: 42,
                                      height: 42,
                                      child: Icon(
                                        Icons.music_note_rounded,
                                        color: theme.colorScheme.onPrimaryContainer,
                                        size: 20,
                                      ),
                                    ),
                            ),
                            // Center spindle hole
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.surface,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 1,
                                    spreadRadius: 0.5,
                                    offset: Offset(0, 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // ─── PLAYER CONTROLS & TIMELINE ───────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title / Subtitle
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.post.bookTitle ?? 'Audio Update',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Speed badge
                            GestureDetector(
                              onTap: _cycleSpeed,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_playbackSpeed.toStringAsFixed(2).replaceAll('.00', '')}x',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.post.bookAuthorName != null) ...[
                          Text(
                            widget.post.bookAuthorName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),

                        // Timeline Seek Slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            activeTrackColor: theme.colorScheme.primary,
                            inactiveTrackColor:
                                theme.colorScheme.primary.withValues(alpha: 0.15),
                            thumbColor: theme.colorScheme.primary,
                            padding: EdgeInsets.zero,
                          ),
                          child: Slider(
                            value: position.inMilliseconds.toDouble(),
                            max: totalDuration.inMilliseconds.toDouble(),
                            onChanged: (val) {
                              _player.seek(Duration(milliseconds: val.toInt()));
                            },
                          ),
                        ),

                        // Time label + error state / play button row
                        Row(
                          children: [
                            Text(
                              '${_formatDuration(position)} / ${_formatDuration(totalDuration)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            if (_error != null)
                              Text(
                                _error!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              IconButton(
                                icon: _isLoading || isBuffering
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.primary,
                                        ),
                                      )
                                    : Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                      ),
                                iconSize: 22,
                                color: theme.colorScheme.primary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: _togglePlay,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
