import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SecureAudioPlayer extends StatefulWidget {
  const SecureAudioPlayer({
    super.key,
    required this.url,
    this.localPath,
    this.objectKey,
    this.durationMs,
    this.label = 'Audio',
    this.textColor,
    this.metadataColor,
    this.onClose,
    this.compact = true,
  });

  final String url;
  final String? localPath;
  final String? objectKey;
  final int? durationMs;
  final String label;
  final Color? textColor;
  final Color? metadataColor;
  final VoidCallback? onClose;
  final bool compact;

  @override
  State<SecureAudioPlayer> createState() => _SecureAudioPlayerState();
}

class _SecureAudioPlayerState extends State<SecureAudioPlayer> {
  late final AudioPlayer _player;
  bool _loaded = false;
  bool _loading = false;
  String? _error;
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
  }

  @override
  void didUpdateWidget(covariant SecureAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.localPath != widget.localPath ||
        oldWidget.objectKey != widget.objectKey) {
      _loaded = false;
      _error = null;
      _resolvedUrl = null;
      _player.stop();
    }
  }

  Future<String> _audioUrl() async {
    final objectKey = widget.objectKey?.trim();
    if (objectKey == null || objectKey.isEmpty) return widget.url;
    final response = await FirebaseFunctions.instance
        .httpsCallable('createAudioReviewDownloadUrl')
        .call<Map<String, dynamic>>({'objectKey': objectKey});
    final downloadUrl = response.data['downloadUrl']?.toString();
    if (downloadUrl == null || downloadUrl.isEmpty) return widget.url;
    return downloadUrl;
  }

  Future<void> _toggle() async {
    if (_player.playing) {
      await _player.pause();
      return;
    }
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      if (!_loaded) {
        final localPath = widget.localPath?.trim();
        if (localPath != null && localPath.isNotEmpty) {
          if (kIsWeb) {
            await _player.setUrl(localPath);
          } else {
            await _player.setFilePath(localPath);
          }
        } else {
          _resolvedUrl ??= await _audioUrl();
          await _player.setUrl(_resolvedUrl!);
        }
        _loaded = true;
      }
      unawaited(_player.play());
    } catch (_) {
      _error = 'Could not play audio';
      if (mounted) setState(() => _loading = false);
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  Future<void> _replay() async {
    try {
      if (!_loaded) {
        await _toggle();
        return;
      }
      await _player.seek(Duration.zero);
      unawaited(_player.play());
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not replay audio');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = Duration(milliseconds: widget.durationMs ?? 0);
    final foreground = widget.textColor ?? theme.colorScheme.onSurface;
    final padding = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.fromLTRB(14, 12, 14, 12);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.compact ? 8 : 16),
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PlayerButton(player: _player, loading: _loading, onToggle: _toggle),
          IconButton(
            tooltip: 'Replay audio',
            visualDensity: VisualDensity.compact,
            onPressed: _loading ? null : _replay,
            icon: const Icon(Icons.replay_rounded),
            color: theme.colorScheme.primary,
          ),
          Flexible(
            child: StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = _player.duration ?? fallback;
                final label = duration.inMilliseconds > 0
                    ? '${_formatAudioTime(position)} / ${_formatAudioTime(duration)}'
                    : widget.label;
                return Text(
                  _error ?? label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _error == null
                        ? widget.metadataColor ?? foreground
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              tooltip: 'Close audio',
              visualDensity: VisualDensity.compact,
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded),
              color: widget.metadataColor ?? foreground,
            ),
        ],
      ),
    );
  }
}

class _PlayerButton extends StatelessWidget {
  const _PlayerButton({
    required this.player,
    required this.loading,
    required this.onToggle,
  });

  final AudioPlayer player;
  final bool loading;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final state = snapshot.data;
        final playing = state?.playing == true;
        final buffering =
            state?.processingState == ProcessingState.loading ||
            state?.processingState == ProcessingState.buffering;
        return IconButton(
          tooltip: playing ? 'Pause audio' : 'Play audio',
          visualDensity: VisualDensity.compact,
          onPressed: loading ? null : onToggle,
          icon: loading || buffering
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  playing
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                ),
          color: theme.colorScheme.primary,
        );
      },
    );
  }
}

String _formatAudioTime(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 120).toInt();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
