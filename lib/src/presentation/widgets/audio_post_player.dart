import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:librebook_flutter/src/utils/app_haptics.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../domain/models/feed_post.dart';
import '../../utils/cloudflare_audio_resolver.dart';
import '../providers/audio_post_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import 'glass_surface.dart';

/// Provider to track the active playing audio URL across the feed.
/// Ensures that playing one audio post automatically pauses any other active post.
class ActiveAudioPostUrl extends Notifier<String?> {
  @override
  String? build() => null;

  void setActiveUrl(String? url, {bool showMiniPlayer = true}) {
    state = url;
    ref
        .read(audioPostMiniPlayerVisibleProvider.notifier)
        .setVisible(url != null && showMiniPlayer);
  }

  bool isActive(String url) => state == url;
}

final activeAudioPostUrlProvider =
    NotifierProvider<ActiveAudioPostUrl, String?>(ActiveAudioPostUrl.new);

class AudioPostMiniPlayerVisibility extends Notifier<bool> {
  @override
  bool build() => false;

  void setVisible(bool visible) => state = visible;
}

final audioPostMiniPlayerVisibleProvider =
    NotifierProvider<AudioPostMiniPlayerVisibility, bool>(
      AudioPostMiniPlayerVisibility.new,
    );

final audioPostPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer(useProxyForRequestHeaders: false);
  final errorSubscription = player.errorStream.listen((error) {
    if (_audioPostSourceLoadInProgress) {
      debugPrint(
        'Audio source load failed before retry: '
        '${sanitizeAudioPlaybackError(error)}',
      );
      return;
    }
    _audioPostRequestGeneration += 1;
    _loadedAudioPostIdentity = null;
    ref.read(activeAudioPostUrlProvider.notifier).setActiveUrl(null);
    debugPrint('Error playing app audio: ${sanitizeAudioPlaybackError(error)}');
  });
  ref.onDispose(() {
    unawaited(errorSubscription.cancel());
    unawaited(player.dispose());
  });
  return player;
});

String? audioPostIdentityFor(FeedPost post) {
  final objectKey = post.audioObjectKey?.trim();
  if (objectKey != null && objectKey.isNotEmpty) return objectKey;
  final audioUrl = post.audioUrl?.trim();
  if (audioUrl != null && audioUrl.isNotEmpty) return audioUrl;
  return null;
}

Future<CloudflareAudioRequest?> resolveAudioPostRequest(
  FeedPost post, {
  bool forceRefreshToken = false,
}) => resolveCloudflareAudioRequest(
  objectKey: post.audioObjectKey,
  url: post.audioUrl,
  forceRefreshToken: forceRefreshToken,
);

MediaItem audioPostMediaItemFor(FeedPost post, String audioIdentity) {
  final audioCoverUrl = post.audioCoverUrl;
  final bookCover = post.bookCover;
  return MediaItem(
    id: post.id ?? audioIdentity,
    album: post.bookTitle ?? 'Audio Post',
    title: post.text.trim().isEmpty ? 'Audio Post' : post.text.trim(),
    artUri: audioCoverUrl != null && audioCoverUrl.isNotEmpty
        ? Uri.tryParse(audioCoverUrl)
        : (bookCover != null && bookCover.isNotEmpty
              ? Uri.tryParse(bookCover)
              : null),
    extras: {
      if (post.id != null && post.id!.trim().isNotEmpty) 'postId': post.id,
    },
  );
}

enum AudioPostPlaybackAction { none, resume, restart, load }

AudioPostPlaybackAction audioPostPlaybackActionFor({
  required String? activeIdentity,
  required String? loadedIdentity,
  required String requestedIdentity,
  required bool isPlaying,
  required bool isCompleted,
}) {
  if (activeIdentity == requestedIdentity && isPlaying && !isCompleted) {
    return AudioPostPlaybackAction.none;
  }
  if (loadedIdentity != requestedIdentity) {
    return AudioPostPlaybackAction.load;
  }
  if (isCompleted) return AudioPostPlaybackAction.restart;
  return AudioPostPlaybackAction.resume;
}

Future<void> playAudioPost(WidgetRef ref, FeedPost post) async {
  final audioIdentity = audioPostIdentityFor(post);
  if (audioIdentity == null || audioIdentity.isEmpty) return;

  await toggleSharedNetworkAudio(
    ref,
    audioIdentity: audioIdentity,
    resolveRequest: (forceRefresh) =>
        resolveAudioPostRequest(post, forceRefreshToken: forceRefresh),
    createSource: (request) => createCloudflareAudioSource(
      request: request,
      mediaItem: audioPostMediaItemFor(post, audioIdentity),
    ),
  );
}

Future<void> ensureAudioPostPlaying(WidgetRef ref, FeedPost post) async {
  final audioIdentity = audioPostIdentityFor(post);
  if (audioIdentity == null || audioIdentity.isEmpty) return;

  await ensureSharedNetworkAudioPlaying(
    ref,
    audioIdentity: audioIdentity,
    resolveRequest: (forceRefresh) =>
        resolveAudioPostRequest(post, forceRefreshToken: forceRefresh),
    createSource: (request) => createCloudflareAudioSource(
      request: request,
      mediaItem: audioPostMediaItemFor(post, audioIdentity),
    ),
  );
}

/// Toggles a remote source on the app's single background-enabled player.
///
/// `just_audio_background` supports one [AudioPlayer] instance, so every
/// background-capable audio surface must use this coordinator on Android.
Future<void> toggleSharedNetworkAudio(
  WidgetRef ref, {
  required String audioIdentity,
  bool showInMiniPlayer = true,
  required Future<CloudflareAudioRequest?> Function(bool forceRefresh)
  resolveRequest,
  required AudioSource Function(CloudflareAudioRequest request) createSource,
}) async {
  final player = ref.read(audioPostPlayerProvider);
  final activeAudio = ref.read(activeAudioPostUrlProvider.notifier);
  if (activeAudio.isActive(audioIdentity) && player.playing) {
    _audioPostRequestGeneration += 1;
    await player.pause();
    return;
  }

  await ensureSharedNetworkAudioPlaying(
    ref,
    audioIdentity: audioIdentity,
    showInMiniPlayer: showInMiniPlayer,
    resolveRequest: resolveRequest,
    createSource: createSource,
  );
}

/// Loads and starts a source through the serialized, retry-safe post path.
Future<void> ensureSharedNetworkAudioPlaying(
  WidgetRef ref, {
  required String audioIdentity,
  bool showInMiniPlayer = true,
  required Future<CloudflareAudioRequest?> Function(bool forceRefresh)
  resolveRequest,
  required AudioSource Function(CloudflareAudioRequest request) createSource,
}) async {
  if (audioIdentity.trim().isEmpty) return;

  final player = ref.read(audioPostPlayerProvider);
  final activeAudio = ref.read(activeAudioPostUrlProvider.notifier);
  final action = audioPostPlaybackActionFor(
    activeIdentity: ref.read(activeAudioPostUrlProvider),
    loadedIdentity: _loadedAudioPostIdentity,
    requestedIdentity: audioIdentity,
    isPlaying: player.playing,
    isCompleted: player.processingState == ProcessingState.completed,
  );
  if (action == AudioPostPlaybackAction.none) return;

  final requestGeneration = ++_audioPostRequestGeneration;
  activeAudio.setActiveUrl(audioIdentity, showMiniPlayer: showInMiniPlayer);

  if (action == AudioPostPlaybackAction.load) {
    if (!_isLatestAudioPostRequest(
      activeAudio,
      audioIdentity,
      requestGeneration,
    )) {
      return;
    }

    final previousLoad = _audioPostLoadQueue;
    final load = previousLoad.catchError((_) {}).then((_) async {
      if (!_isLatestAudioPostRequest(
        activeAudio,
        audioIdentity,
        requestGeneration,
      )) {
        return;
      }
      _audioPostSourceLoadInProgress = true;
      try {
        await setCloudflareAudioSourceWithRetry(
          resolveRequest: resolveRequest,
          setAudioSource: player.setAudioSource,
          createSource: createSource,
        );
      } finally {
        _audioPostSourceLoadInProgress = false;
      }
      if (_isLatestAudioPostRequest(
        activeAudio,
        audioIdentity,
        requestGeneration,
      )) {
        _loadedAudioPostIdentity = audioIdentity;
      }
    });
    _audioPostLoadQueue = load;
    await load;
  } else if (action == AudioPostPlaybackAction.restart) {
    await player.seek(Duration.zero);
  }

  if (!_isLatestAudioPostRequest(
    activeAudio,
    audioIdentity,
    requestGeneration,
  )) {
    return;
  }
  await player.play();
}

bool _isLatestAudioPostRequest(
  ActiveAudioPostUrl activeAudio,
  String audioIdentity,
  int requestGeneration,
) {
  return requestGeneration == _audioPostRequestGeneration &&
      activeAudio.isActive(audioIdentity);
}

String? _loadedAudioPostIdentity;
int _audioPostRequestGeneration = 0;
bool _audioPostSourceLoadInProgress = false;
Future<void> _audioPostLoadQueue = Future<void>.value();

class AudioPostPlayer extends ConsumerStatefulWidget {
  const AudioPostPlayer({super.key, required this.post, this.autoPlay = false});

  final FeedPost post;
  final bool autoPlay;

  @override
  ConsumerState<AudioPostPlayer> createState() => _AudioPostPlayerState();
}

class _AudioPostPlayerState extends ConsumerState<AudioPostPlayer>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  late final AnimationController _rotationController;
  late final StreamSubscription<PlayerState> _playerStateSubscription;

  bool _isLoading = false;
  String? _error;
  bool _autoPlayAttempted = false;

  double _playbackSpeed = 1.0;
  bool _wasPlayingBeforeDrag = false;
  double _dragStartValue = 0.0;
  double _dragCurrentValue = 0.0;
  double _lastDragAngle = 0.0;
  double _hapticAccumulator = 0.0;

  @override
  void initState() {
    super.initState();
    _player = ref.read(audioPostPlayerProvider);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // Slow, smooth vinyl spin
    );

    // Sync player speed
    _player.setSpeed(_playbackSpeed);

    // Coordinate rotation with playing state
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final isCurrent = ref.read(activeAudioPostUrlProvider) == _audioIdentity;
      final disableAnimations = MediaQuery.of(context).disableAnimations;
      if (isCurrent &&
          state.playing &&
          state.processingState != ProcessingState.completed &&
          !disableAnimations) {
        if (!_rotationController.isAnimating) {
          _rotationController.repeat();
        }
      } else {
        _rotationController.stop();
      }
      if (isCurrent && state.processingState == ProcessingState.completed) {
        final activeUrl = ref.read(activeAudioPostUrlProvider);
        if (activeUrl == _audioIdentity) {
          ref.read(activeAudioPostUrlProvider.notifier).setActiveUrl(null);
        }
      }
    });
    _scheduleAutoPlay();
  }

  String? get _audioIdentity => audioPostIdentityFor(widget.post);

  @override
  void didUpdateWidget(covariant AudioPostPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final identityChanged =
        audioPostIdentityFor(oldWidget.post) !=
        audioPostIdentityFor(widget.post);
    if (identityChanged || (!oldWidget.autoPlay && widget.autoPlay)) {
      _autoPlayAttempted = false;
    }
    _scheduleAutoPlay();
  }

  void _scheduleAutoPlay() {
    if (!widget.autoPlay || _autoPlayAttempted) return;
    _autoPlayAttempted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.autoPlay) return;
      unawaited(_autoPlay());
    });
  }

  Future<void> _autoPlay() async {
    if (_audioIdentity == null) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      await ensureAudioPostPlaying(ref, widget.post);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Could not load audio';
        });
      }
      debugPrint('Error autoplaying feed post audio: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_playerStateSubscription.cancel());
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final audioIdentity = _audioIdentity;
    if (audioIdentity == null || audioIdentity.isEmpty) return;

    final activeIdentity = ref.read(activeAudioPostUrlProvider);
    final isCurrent = activeIdentity == audioIdentity;

    if (isCurrent && _player.playing) {
      _audioPostRequestGeneration += 1;
      await _player.pause();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await playAudioPost(ref, widget.post);
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
    if (ref.read(activeAudioPostUrlProvider) != _audioIdentity) return;
    final speeds = [1.0, 1.25, 1.5, 2.0];
    final nextIndex = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    setState(() {
      _playbackSpeed = speeds[nextIndex];
    });
    _player.setSpeed(_playbackSpeed);
    AppHaptics.light();
  }

  Future<void> _seekRelative(int seconds) async {
    if (ref.read(activeAudioPostUrlProvider) != _audioIdentity) return;
    final currentPos = _player.position;
    final totalDuration =
        _player.duration ??
        Duration(milliseconds: widget.post.audioDurationMs ?? 0);
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
    if (ref.read(activeAudioPostUrlProvider) != _audioIdentity) return;

    // Lock scroll/swipe in parent views during turntable jog seeking
    ref.read(lockScrollProvider.notifier).setLock(true);

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
    _rotationController.value =
        (_rotationController.value + (deltaAngle / (2 * math.pi))) % 1.0;

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
    ref.read(lockScrollProvider.notifier).setLock(false);
  }

  void _onPanCancel() {
    if (_wasPlayingBeforeDrag) {
      _player.play();
    }
    ref.read(lockScrollProvider.notifier).setLock(false);
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
    final l10n = AppLocalizations.of(context)!;
    final audioIdentity = _audioIdentity;

    if (audioIdentity == null || audioIdentity.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeIdentity = ref.watch(activeAudioPostUrlProvider);
    final isCurrent = activeIdentity == audioIdentity;

    // Auto-pause if another feed card starts playing
    ref.listen<String?>(activeAudioPostUrlProvider, (previous, next) {
      if (next != audioIdentity && _player.playing) {
        _player.pause();
      }
    });

    final coverUrl = widget.post.audioCoverUrl ?? widget.post.bookCover;
    final isBookReferred = widget.post.bookId != null;
    final defaultDuration = Duration(
      milliseconds: widget.post.audioDurationMs ?? 0,
    );

    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, posSnapshot) {
        final position = isCurrent
            ? (posSnapshot.data ?? Duration.zero)
            : Duration.zero;
        final totalDuration = isCurrent
            ? (_player.duration ?? defaultDuration)
            : defaultDuration;

        final double progress = totalDuration.inMilliseconds > 0
            ? (position.inMilliseconds / totalDuration.inMilliseconds).clamp(
                0.0,
                1.0,
              )
            : 0.0;

        return StreamBuilder<PlayerState>(
          stream: _player.playerStateStream,
          builder: (context, stateSnapshot) {
            final playerState = stateSnapshot.data;
            final isPlaying = isCurrent && (playerState?.playing ?? false);
            final isBuffering =
                isCurrent &&
                (playerState?.processingState == ProcessingState.buffering ||
                    playerState?.processingState == ProcessingState.loading);

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.05,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
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
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      width: 36,
                                      height: 50,
                                      child: const Icon(
                                        Icons.book_rounded,
                                        size: 18,
                                      ),
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
                                    widget.post.bookAuthorName ??
                                        'Unknown Author',
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
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.7,
                              ),
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
                            trackColor: theme.colorScheme.primary.withValues(
                              alpha: 0.08,
                            ),
                            progressColor: theme.colorScheme.primary,
                          ),
                        ),

                        // Vinyl turntable disc
                        GestureDetector(
                          onPanStart: (details) =>
                              _onPanStart(details, totalDuration),
                          onPanUpdate: (details) =>
                              _onPanUpdate(details, totalDuration),
                          onPanEnd: _onPanEnd,
                          onPanCancel: _onPanCancel,
                          behavior: HitTestBehavior.translucent,
                          child: SizedBox(
                            width: 204,
                            height: 204,
                            child: Center(
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
                                        color: Colors.black.withValues(
                                          alpha: 0.35,
                                        ),
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
                                      for (double r in [
                                        160.0,
                                        140.0,
                                        120.0,
                                        100.0,
                                        80.0,
                                      ])
                                        Container(
                                          width: r,
                                          height: r,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.04,
                                              ),
                                              width: 0.8,
                                            ),
                                          ),
                                        ),

                                      // Cover image clipped circular in the center
                                      ClipOval(
                                        child:
                                            coverUrl != null &&
                                                coverUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: coverUrl,
                                                width: 78,
                                                height: 78,
                                                fit: BoxFit.cover,
                                                placeholder: (_, _) =>
                                                    Container(
                                                      color:
                                                          Colors.grey.shade900,
                                                      child: const Icon(
                                                        Icons
                                                            .music_note_rounded,
                                                        color: Colors.white30,
                                                        size: 32,
                                                      ),
                                                    ),
                                                errorWidget: (_, _, _) =>
                                                    Container(
                                                      color:
                                                          Colors.grey.shade900,
                                                      child: const Icon(
                                                        Icons
                                                            .music_note_rounded,
                                                        color: Colors.white30,
                                                        size: 32,
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                color: theme
                                                    .colorScheme
                                                    .primaryContainer,
                                                width: 78,
                                                height: 78,
                                                child: Icon(
                                                  Icons.music_note_rounded,
                                                  color: theme
                                                      .colorScheme
                                                      .onPrimaryContainer,
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
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rotate_left_rounded,
                        size: 15,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.dragRecordToSeek,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.rotate_right_rounded,
                        size: 15,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.08,
                                ),
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
                        tooltip: 'Rewind 10 seconds',
                        color: theme.colorScheme.primary.withValues(alpha: 0.8),
                        onPressed: () => _seekRelative(-10),
                      ),
                      const SizedBox(width: 8),

                      // Circular glowing play/pause button
                      Semantics(
                        button: true,
                        label: isPlaying ? l10n.pause : l10n.play,
                        child: GestureDetector(
                          onTap: _togglePlay,
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.35,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: (_isLoading || isBuffering) && !isPlaying
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 32,
                                    color: theme.colorScheme.primary,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Skip Forward 10s
                      IconButton(
                        icon: const Icon(Icons.forward_10_rounded),
                        iconSize: 28,
                        tooltip: 'Fast forward 10 seconds',
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
