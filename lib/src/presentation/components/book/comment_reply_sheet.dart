import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../data/services/audio_review_upload_service.dart';
import '../../../domain/models/comment.dart';
import '../../../utils/app_haptics.dart';
import '../../providers/auth_providers.dart';
import '../../providers/comment_providers.dart';

class CommentReplySheet extends ConsumerStatefulWidget {
  const CommentReplySheet({
    super.key,
    required this.comment,
    required this.bookId,
  });

  final Comment comment;
  final String bookId;

  @override
  ConsumerState<CommentReplySheet> createState() => _CommentReplySheetState();
}

class _CommentReplySheetState extends ConsumerState<CommentReplySheet>
    with RestorationMixin {
  final _controller = RestorableTextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _audioRecordingTimer;
  bool _submitting = false;
  bool _isRecording = false;
  String? _pendingAudioPath;
  int _pendingAudioDurationMs = 0;

  @override
  String? get restorationId =>
      'book_comment_reply_${widget.bookId}_${widget.comment.id ?? 'unknown'}';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_controller, 'reply_text');
  }

  @override
  void dispose() {
    _audioRecordingTimer?.cancel();
    unawaited(_audioRecorder.dispose());
    _controller.dispose();
    super.dispose();
  }

  bool get _hasPendingAudio => _pendingAudioPath != null || _isRecording;

  bool get _canSubmit =>
      _controller.value.text.trim().isNotEmpty || _hasPendingAudio;

  void _refreshComposer() {
    if (mounted) setState(() {});
  }

  Future<void> _startRecording() async {
    if (_isRecording || _submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      final status = await Permission.microphone.status;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Microphone permission is needed to record.'),
          action: status.isPermanentlyDenied
              ? SnackBarAction(label: l10n.settings, onPressed: openAppSettings)
              : null,
        ),
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/audio_reply_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 32000,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
      ),
      path: path,
    );

    _audioRecordingTimer?.cancel();
    _audioRecordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pendingAudioDurationMs += 1000;
      if (_pendingAudioDurationMs >= AudioReviewUploadService.maxDurationMs) {
        unawaited(_stopRecording());
      } else {
        _refreshComposer();
      }
    });

    setState(() {
      _isRecording = true;
      _pendingAudioPath = null;
      _pendingAudioDurationMs = 0;
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    final durationMs = _pendingAudioDurationMs;
    _audioRecordingTimer?.cancel();
    _audioRecordingTimer = null;
    final path = await _audioRecorder.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      if (path != null && durationMs > 0) {
        _pendingAudioPath = path;
        _pendingAudioDurationMs = durationMs.clamp(
          1000,
          AudioReviewUploadService.maxDurationMs,
        );
      } else {
        _pendingAudioPath = null;
        _pendingAudioDurationMs = 0;
      }
    });
  }

  Future<void> _removeRecording() async {
    _audioRecordingTimer?.cancel();
    _audioRecordingTimer = null;
    if (_isRecording) {
      await _audioRecorder.cancel();
    }
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _pendingAudioPath = null;
      _pendingAudioDurationMs = 0;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final text = _controller.value.text.trim();
    if (!_canSubmit) return;

    setState(() => _submitting = true);
    try {
      if (_isRecording) {
        await _stopRecording();
      }
      final user = await ref.read(currentUserProvider.future);
      if (user == null) return;
      AudioReviewUploadResult? uploadedAudio;
      if (_pendingAudioPath != null) {
        uploadedAudio = await ref
            .read(audioReviewUploadServiceProvider)
            .uploadAudioReview(
              filePath: _pendingAudioPath!,
              bookId: widget.bookId,
              userId: user.id,
              chapterId:
                  'reply_${widget.comment.id ?? widget.comment.timestamp}',
              durationMs: _pendingAudioDurationMs,
            );
      }

      await ref
          .read(commentRepositoryProvider)
          .addReply(
            widget.comment.id!,
            CommentReply(
              userId: user.id,
              username: user.username,
              displayName: user.displayName,
              penName: user.penName,
              text: text,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              userPhotoURL: user.photoURL,
              audioUrl: uploadedAudio?.audioUrl,
              audioObjectKey: uploadedAudio?.audioObjectKey,
              audioDurationMs: uploadedAudio?.audioDurationMs,
              audioMimeType: uploadedAudio?.audioMimeType,
              audioSizeBytes: uploadedAudio?.audioSizeBytes,
            ),
          );

      await AppHaptics.light();
      _controller.value.clear();
      await _removeRecording();
      ref.invalidate(liveBookCommentsProvider(widget.bookId));
      ref.invalidate(bookCommentsProvider(widget.bookId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToPostReply(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.replyingTo(
              widget.comment.displayName ?? widget.comment.username,
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller.value,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.addAReply,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _isRecording ? 'Stop recording' : 'Record audio',
                onPressed: _submitting
                    ? null
                    : () async {
                        if (_isRecording) {
                          await _stopRecording();
                        } else {
                          await _startRecording();
                        }
                      },
                icon: Icon(
                  _isRecording
                      ? Icons.stop_circle_outlined
                      : Icons.mic_none_rounded,
                  color: _isRecording ? Colors.red : null,
                ),
              ),
            ),
            onChanged: (_) => _refreshComposer(),
          ),
          if (_isRecording || _pendingAudioPath != null) ...[
            const SizedBox(height: 8),
            _ReplyAudioComposerChip(
              isRecording: _isRecording,
              durationMs: _pendingAudioDurationMs,
              onStop: _stopRecording,
              onDelete: _removeRecording,
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _submitting || !_canSubmit ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.reply),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyAudioComposerChip extends StatelessWidget {
  const _ReplyAudioComposerChip({
    required this.isRecording,
    required this.durationMs,
    required this.onStop,
    required this.onDelete,
  });

  final bool isRecording;
  final int durationMs;
  final VoidCallback onStop;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecording
              ? Colors.red.withValues(alpha: 0.55)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              isRecording ? Icons.mic_rounded : Icons.graphic_eq_rounded,
              color: isRecording ? Colors.red : theme.colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isRecording
                    ? 'Recording ${_formatReplyAudioDuration(durationMs)}'
                    : 'New audio ${_formatReplyAudioDuration(durationMs)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isRecording)
              IconButton(
                tooltip: 'Stop recording',
                visualDensity: VisualDensity.compact,
                onPressed: onStop,
                icon: const Icon(Icons.stop_circle_outlined),
              ),
            IconButton(
              tooltip: isRecording ? 'Cancel recording' : 'Delete audio',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatReplyAudioDuration(int durationMs) {
  final totalSeconds = (durationMs / 1000).ceil().clamp(0, 120).toInt();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
