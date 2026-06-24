import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:librebook_flutter/src/utils/app_haptics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../domain/models/book.dart';
import '../../localization/generated/app_localizations.dart';
import '../widgets/book_search_selector.dart';
import '../widgets/glass_surface.dart';

class AudioPostCreator extends StatefulWidget {
  const AudioPostCreator({
    super.key,
    required this.onAudioChanged,
    required this.onCoverChanged,
    required this.onBookReferred,
    this.onRecordingStateChanged,
  });

  final Function(String? path, int durationMs, int sizeBytes, String mimeType) onAudioChanged;
  final ValueChanged<XFile?> onCoverChanged;
  final ValueChanged<Book?> onBookReferred;
  final ValueChanged<bool>? onRecordingStateChanged;

  @override
  State<AudioPostCreator> createState() => AudioPostCreatorState();
}

class AudioPostCreatorState extends State<AudioPostCreator> {
  // Public methods to control from parent sheet
  Future<void> startRecording() => _startRecording();
  Future<void> cancelRecording() => _cancelRecording();
  Future<void> stopRecording() => _stopRecording();
  Future<void> pickAudioFile() => _pickAudioFile();
  bool get isRecording => _isRecording;
  String? get audioPath => _audioPath;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _previewPlayer = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();

  Timer? _recordingTimer;
  bool _isRecording = false;
  int _recordingDurationMs = 0;

  String? _audioPath;
  int _audioDurationMs = 0;
  int _audioSizeBytes = 0;
  String _audioMimeType = 'audio/m4a';

  XFile? _customCover;
  Book? _referredBook;
  bool _isPreviewPlaying = false;

  @override
  void initState() {
    super.initState();
    _previewPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPreviewPlaying = state.playing &&
              state.processingState != ProcessingState.completed;
        });
      }
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  // Recording audio
  Future<void> _startRecording() async {
    if (_isRecording) return;
    final l10n = AppLocalizations.of(context)!;
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      final status = await Permission.microphone.status;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Microphone permission is needed to record.'),
          action: status.isPermanentlyDenied
              ? SnackBarAction(
                  label: l10n.settings,
                  onPressed: openAppSettings,
                )
              : null,
        ),
      );
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/audio_post_${DateTime.now().millisecondsSinceEpoch}.m4a';

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

      _recordingTimer?.cancel();
      _recordingDurationMs = 0;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDurationMs += 1000;
          });
        }
      });

      setState(() {
        _isRecording = true;
        _audioPath = null;
      });
      widget.onRecordingStateChanged?.call(true);
      AppHaptics.medium();
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    _recordingTimer = null;

    final path = await _audioRecorder.stop();
    if (path == null) {
      setState(() => _isRecording = false);
      widget.onRecordingStateChanged?.call(false);
      return;
    }

    final file = File(path);
    final size = await file.length();
    
    setState(() {
      _isRecording = false;
      _audioPath = path;
      _audioDurationMs = _recordingDurationMs;
      _audioSizeBytes = size;
      _audioMimeType = 'audio/m4a';
    });

    widget.onRecordingStateChanged?.call(false);
    widget.onAudioChanged(_audioPath, _audioDurationMs, _audioSizeBytes, _audioMimeType);
    AppHaptics.medium();
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    await _audioRecorder.cancel();
    setState(() {
      _isRecording = false;
    });
    widget.onRecordingStateChanged?.call(false);
    AppHaptics.light();
  }

  // Picking audio file
  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowCompression: true,
      );

      if (result == null || result.files.single.path == null) return;

      final pickedFile = result.files.single;
      final path = pickedFile.path!;
      final size = pickedFile.size;

      // Enforce 10MB limit
      const maxLimit = 10 * 1024 * 1024;
      if (size > maxLimit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio file must be 10MB or smaller.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      int durationMs = 0;
      try {
        final duration = await _previewPlayer.setUrl(path);
        durationMs = duration?.inMilliseconds ?? 0;
      } catch (e) {
        debugPrint('Could not read audio duration, fallback to 0: $e');
      }

      // Guess MIME type from extension
      String mime = 'audio/mpeg';
      if (path.endsWith('.m4a')) {
        mime = 'audio/m4a';
      } else if (path.endsWith('.mp4')) {
        mime = 'audio/mp4';
      } else if (path.endsWith('.wav')) {
        mime = 'audio/wav';
      } else if (path.endsWith('.aac')) {
        mime = 'audio/aac';
      }

      setState(() {
        _audioPath = path;
        _audioDurationMs = durationMs;
        _audioSizeBytes = size;
        _audioMimeType = mime;
      });

      widget.onAudioChanged(_audioPath, _audioDurationMs, _audioSizeBytes, _audioMimeType);
      AppHaptics.medium();
    } catch (e) {
      debugPrint('Error picking audio file: $e');
    }
  }

  void _removeAudio() {
    _previewPlayer.stop();
    setState(() {
      _audioPath = null;
      _audioDurationMs = 0;
      _audioSizeBytes = 0;
      _customCover = null;
      _referredBook = null;
    });
    widget.onAudioChanged(null, 0, 0, '');
    widget.onCoverChanged(null);
    widget.onBookReferred(null);
    AppHaptics.light();
  }

  // Previewing attached audio
  Future<void> _togglePreview() async {
    if (_audioPath == null) return;
    if (_previewPlayer.playing) {
      await _previewPlayer.pause();
    } else {
      await _previewPlayer.setUrl(_audioPath!);
      await _previewPlayer.play();
    }
  }

  // Cover image / book reference options
  Future<void> _pickCustomCover() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 600,
      );
      if (image != null) {
        setState(() {
          _customCover = image;
          _referredBook = null; // Overwrite referred book cover
        });
        widget.onCoverChanged(_customCover);
        widget.onBookReferred(null);
        AppHaptics.light();
      }
    } catch (e) {
      debugPrint('Error picking custom cover: $e');
    }
  }

  Future<void> _referBook() async {
    final book = await showBookSearchSelector(context);
    if (book != null) {
      setState(() {
        _referredBook = book;
        _customCover = null; // Overwrite custom cover
      });
      widget.onBookReferred(_referredBook);
      widget.onCoverChanged(null);
      AppHaptics.light();
    }
  }

  void _removeCover() {
    setState(() {
      _customCover = null;
      _referredBook = null;
    });
    widget.onCoverChanged(null);
    widget.onBookReferred(null);
    AppHaptics.light();
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. RECORDING STATE
    if (_isRecording) {
      return GlassSurface(
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.mic_rounded, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Recording voice note... ${_formatDuration(_recordingDurationMs)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const Spacer(),
                // Bouncing active dot
                _BouncingDot(),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _cancelRecording,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. NO AUDIO ATTACHED STATE
    if (_audioPath == null) {
      return const SizedBox.shrink();
    }

    // 3. AUDIO ATTACHED STATE
    final coverPreviewUrl = _referredBook?.coverUrl;

    return GlassSurface(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audio info row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.audiotrack_rounded, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audio Clip Attached',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    Text(
                      'Duration: ${_formatDuration(_audioDurationMs)} • Size: ${_formatSize(_audioSizeBytes)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Play preview button
              IconButton(
                icon: Icon(
                  _isPreviewPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                onPressed: _togglePreview,
                color: theme.colorScheme.primary,
                tooltip: 'Preview',
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _removeAudio,
                color: theme.colorScheme.error,
                tooltip: 'Remove',
              ),
            ],
          ),
          const Divider(height: 16),

          // Cover options header
          Text(
            'Audio Cover Art',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Cover selection buttons
          Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.book_rounded, size: 14),
                label: const Text('Refer Book', style: TextStyle(fontSize: 11)),
                onPressed: _referBook,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.image_rounded, size: 14),
                label: const Text('Custom Cover', style: TextStyle(fontSize: 11)),
                onPressed: _pickCustomCover,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          // Visual cover art preview
          if (_referredBook != null || _customCover != null) ...[
            const SizedBox(height: 12),
            GlassSurface(
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _referredBook != null
                        ? (coverPreviewUrl != null && coverPreviewUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: coverPreviewUrl,
                                width: 40,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                width: 40,
                                height: 56,
                                child: const Icon(Icons.book, size: 18),
                              ))
                        : Image.file(
                            File(_customCover!.path),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _referredBook != null ? _referredBook!.title : 'Custom Cover Art',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        Text(
                          _referredBook != null
                              ? 'Using book cover'
                              : 'Custom uploaded image',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: _removeCover,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BouncingDot extends StatefulWidget {
  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
        ),
      ),
    );
  }
}
