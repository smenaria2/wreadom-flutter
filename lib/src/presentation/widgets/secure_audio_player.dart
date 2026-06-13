import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SecureAudioPlayer extends StatefulWidget {
  const SecureAudioPlayer({
    super.key,
    required this.url,
    this.objectKey,
    this.durationMs,
    this.label = 'Audio',
    this.textColor,
    this.metadataColor,
  });

  final String url;
  final String? objectKey;
  final int? durationMs;
  final String label;
  final Color? textColor;
  final Color? metadataColor;

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
        _resolvedUrl ??= await _audioUrl();
        await _player.setUrl(_resolvedUrl!);
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final state = snapshot.data;
              final playing = state?.playing == true;
              final buffering =
                  state?.processingState == ProcessingState.loading ||
                  state?.processingState == ProcessingState.buffering;
              return IconButton(
                tooltip: playing ? 'Pause audio' : 'Play audio',
                visualDensity: VisualDensity.compact,
                onPressed: _loading ? null : _toggle,
                icon: _loading || buffering
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
        ],
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
