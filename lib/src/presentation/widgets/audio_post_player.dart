import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:librebook_flutter/src/utils/app_haptics.dart';

import '../../domain/models/feed_post.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import 'glass_surface.dart';

/// Provider to track the active playing audio URL across the feed.
/// Ensures that playing one audio post automatically pauses any other active post.
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
  double _lastDragAngle = 0.0;
  double _hapticAccumulator = 0.0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // Slow, smooth vinyl spin
    );

    // Sync player speed
    _player.setSpeed(_playbackSpeed);

    // Coordinate rotation with playing state
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

  /// Resolves the pre-signed Backblaze B2 download GET URL.
  Future<String> _getAudioUrl() async {
    final objectKey = widget.post.audioObjectKey?.trim();
    if (objectKey == null || objectKey.isEmpty) {
      return widget.post.audioUrl ?? '';
    }

    try {
      final response = await FirebaseFunctions.instance
          .httpsCallable('createAudioPostDownloadUrl')
          .call<Map<String, dynamic>>({'objectKey': objectKey});
      
      final downloadUrl = response.data['downloadUrl']?.toString();
      return downloadUrl ?? widget.post.audioUrl ?? '';
    } catch (e) {
      debugPrint('Error getting pre-signed audio download URL: $e');
      return widget.post.audioUrl ?? '';
    }
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

      // Update active player in the feed to mute others
      ref.read(activeAudioPostUrlProvider.notifier).setActiveUrl(audioUrl);

      if (!_isLoaded) {
        final resolvedUrl = await _getAudioUrl();
        await _player.setUrl(resolvedUrl);
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

  Future<void> _seekRelative(int seconds) async {
    final currentPos = _player.position;
    final totalDuration = _player.duration ?? Duration(milliseconds: widget.post.audioDurationMs ?? 0);
    final targetPos = currentPos + Duration(seconds: seconds);
    final clampedPos = targetPos < Duration.zero
        ? Duration.zero
        : (targetPos > totalDuration ? totalDuration : targetPos);
    await _player.seek(clampedPos);
    AppHaptics.light();
  }

  // DJ Turntable circular seeks logic
  void _onPanStart(DragStartDetails details, Duration totalDuration) {
    if (totalDuration == Duration.zero) return;
    
    _wasPlayingBeforeDrag = _player.playing;
    if (_wasPlayingBeforeDrag) {
      _player.pause();
    }

    // Determine touch offset angle relative to center of a 204x204 container
    final double dx = details.localPosition.dx - 102.0;
    final double dy = details.localPosition.dy - 102.0;
    
    _lastDragAngle = math.atan2(dy, dx);
    _dragStartValue = _player.position.inMilliseconds.toDouble();
    _dragCurrentValue = _dragStartValue;
    _hapticAccumulator = 0.0;
  }

  void _onPanUpdate(DragUpdateDetails details, Duration totalDuration) {
    if (totalDuration == Duration.zero) return;

    final double dx = details.localPosition.dx - 102.0;
    final double dy = details.localPosition.dy - 102.0;
    final double currentAngle = math.atan2(dy, dx);

    // Calculate angular difference and handle wrap-around
    double deltaAngle = currentAngle - _lastDragAngle;
    if (deltaAngle > math.pi) {
      deltaAngle -= 2 * math.pi;
    } else if (deltaAngle < -math.pi) {
      deltaAngle += 2 * math.pi;
    }

    _lastDragAngle = currentAngle;

    // 1 full turn (2*pi radians) seeks by 30 seconds of audio
    final double deltaMs = (deltaAngle / (2 * math.pi)) * 30000.0;
    final double maxMs = totalDuration.inMilliseconds.toDouble();

    _dragCurrentValue = (_dragCurrentValue + deltaMs).clamp(0.0, maxMs);

    // Visually rotate turntable disc
    _rotationController.value = (_rotationController.value + (deltaAngle / (2 * math.pi))) % 1.0;

    // Tactile notches feedback: tick every 15 degrees (~0.26 radians)
    _hapticAccumulator += deltaAngle.abs();
    if (_hapticAccumulator >= 0.26) {
      AppHaptics.light();
      _hapticAccumulator = 0.0;
    }

    // Interactively seek player
    _player.seek(Duration(milliseconds: _dragCurrentValue.toInt()));
  }

  void _onPanEnd(DragEndDetails details) {
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

    // Auto-pause if another feed card starts playing
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
        
        final double progress = totalDuration.inMilliseconds > 0
            ? (position.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return StreamBuilder<PlayerState>(
          stream: _player.playerStateStream,
          builder: (context, stateSnapshot) {
            final playerState = stateSnapshot.data;
            final isPlaying = playerState?.playing ?? false;
            final isBuffering = playerState?.processingState == ProcessingState.buffering ||
                playerState?.processingState == ProcessingState.loading;

            return GlassSurface(
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  // 1. PREMIUM REFERRED BOOK HEADER
                  if (isBookReferred) ...[
                    GestureDetector(
                      onTap: () => _navigateToBook(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: coverUrl != null && coverUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: coverUrl,
                                      width: 36,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      width: 36,
                                      height: 50,
                                      child: const Icon(Icons.book_rounded, size: 18),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.post.bookTitle ?? 'Book Reference',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.post.bookAuthorName ?? 'Unknown Author',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: theme.colorScheme.primary.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // 2. LARGE TURNTABLE DISC WITH CIRCULAR PROGRESS
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Custom Painted Circular Progress Ring
                        CustomPaint(
                          size: const Size(204, 204),
                          painter: CircularProgressPainter(
                            progress: progress,
                            trackColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                            progressColor: theme.colorScheme.primary,
                          ),
                        ),

                        // Vinyl turntable disc
                        GestureDetector(
                          onPanStart: (details) => _onPanStart(details, totalDuration),
                          onPanUpdate: (details) => _onPanUpdate(details, totalDuration),
                          onPanEnd: _onPanEnd,
                          child: RotationTransition(
                            turns: _rotationController,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFF333333),
                                    Color(0xFF1C1C1C),
                                    Color(0xFF070707),
                                    Color(0xFF000000),
                                  ],
                                  stops: [0.0, 0.5, 0.85, 1.0],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Vinyl Grooves
                                  for (double r in [160.0, 140.0, 120.0, 100.0, 80.0])
                                    Container(
                                      width: r,
                                      height: r,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.04),
                                          width: 0.8,
                                        ),
                                      ),
                                    ),
                                  
                                  // Cover image clipped circular in the center
                                  ClipOval(
                                    child: coverUrl != null && coverUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: coverUrl,
                                            width: 78,
                                            height: 78,
                                            fit: BoxFit.cover,
                                            placeholder: (_, _) => Container(
                                              color: Colors.grey.shade900,
                                              child: const Icon(Icons.music_note_rounded,
                                                  color: Colors.white30, size: 32),
                                            ),
                                            errorWidget: (_, _, _) => Container(
                                              color: Colors.grey.shade900,
                                              child: const Icon(Icons.music_note_rounded,
                                                  color: Colors.white30, size: 32),
                                            ),
                                          )
                                        : Container(
                                            color: theme.colorScheme.primaryContainer,
                                            width: 78,
                                            height: 78,
                                            child: Icon(
                                              Icons.music_note_rounded,
                                              color: theme.colorScheme.onPrimaryContainer,
                                              size: 32,
                                            ),
                                          ),
                                  ),

                                  // Center spindle hole
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.colorScheme.surface,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black45,
                                          blurRadius: 1.5,
                                          spreadRadius: 0.5,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. TIME INDICATORS BELOW THE TURNTABLE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _formatDuration(totalDuration),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. MULTIMEDIA MEDIA CONTROLS ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Speed indicator (on the left)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: _cycleSpeed,
                            child: Container(
                              margin: const EdgeInsets.only(left: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_playbackSpeed.toStringAsFixed(2).replaceAll('.00', '')}x',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Skip Backward 10s
                      IconButton(
                        icon: const Icon(Icons.replay_10_rounded),
                        iconSize: 28,
                        color: theme.colorScheme.primary.withValues(alpha: 0.8),
                        onPressed: () => _seekRelative(-10),
                      ),
                      const SizedBox(width: 8),

                      // Circular glowing play/pause button
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isLoading || isBuffering
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : Icon(
                                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 32,
                                  color: theme.colorScheme.primary,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Skip Forward 10s
                      IconButton(
                        icon: const Icon(Icons.forward_10_rounded),
                        iconSize: 28,
                        color: theme.colorScheme.primary.withValues(alpha: 0.8),
                        onPressed: () => _seekRelative(10),
                      ),

                      // Empty balancing space (on the right)
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),

                  // Display Load Errors
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Painter to draw a circular progress ring.
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 5.0;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    // Draw background track
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc
    if (progress > 0.0) {
      final Paint progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start at the top center
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
