import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/services/audio_review_upload_service.dart';
import '../../../data/services/cloudinary_upload_service.dart';
import '../../../domain/models/book.dart';
import '../../../domain/models/leaf_attachment.dart';
import '../../../utils/app_haptics.dart';
import '../../components/create_post_sheet.dart';
import '../../providers/auth_providers.dart';
import '../../providers/book_providers.dart';
import '../../providers/comment_providers.dart';
import '../../utils/writer_html_codec.dart';
import '../../utils/writer_media_utils.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/in_app_media_web_view.dart';
import '../../widgets/secure_audio_player.dart';
import 'certificate_leaf_viewer.dart';

const int maxBookLeaves = 4;
const int maxNoteLeafCharacters = 1500;
const int maxQuestionLeafCharacters = 500;
const List<LeafType> manualLeafTypes = [
  LeafType.text,
  LeafType.question,
  LeafType.image,
  LeafType.link,
  LeafType.audio,
];

class LeafStrip extends StatelessWidget {
  const LeafStrip({super.key, required this.book, required this.canManage});

  final Book book;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final leaves = book.leaves ?? const <LeafAttachment>[];
    if (leaves.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 94,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < leaves.length; index++) ...[
                    if (index > 0) const SizedBox(width: 10),
                    _LeafIconChip(
                      leaf: leaves[index],
                      canManage: canManage,
                      onTap: () => showLeafViewer(
                        context,
                        book: book,
                        leaf: leaves[index],
                      ),
                      onDelete: () =>
                          _confirmDeleteLeaf(context, book.id, leaves[index]),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class LeafTargetLauncher extends StatefulWidget {
  const LeafTargetLauncher({
    super.key,
    required this.book,
    required this.targetLeafId,
  });

  final Book book;
  final String? targetLeafId;

  @override
  State<LeafTargetLauncher> createState() => _LeafTargetLauncherState();
}

class _LeafTargetLauncherState extends State<LeafTargetLauncher> {
  String? _openedLeafId;

  @override
  Widget build(BuildContext context) {
    final target = widget.targetLeafId?.trim();
    if (target != null && target.isNotEmpty && _openedLeafId != target) {
      final leaves = widget.book.leaves ?? const <LeafAttachment>[];
      final leaf = leaves.cast<LeafAttachment?>().firstWhere(
        (leaf) => leaf?.id == target,
        orElse: () => null,
      );
      if (leaf != null) {
        _openedLeafId = target;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showLeafViewer(context, book: widget.book, leaf: leaf);
        });
      }
    }
    return const SizedBox.shrink();
  }
}

Future<void> showAddLeafSheet(BuildContext context, {required Book book}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GlassSurface(
      strong: true,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: _AddLeafSheet(book: book),
    ),
  );
}

Future<void> showLeafViewer(
  BuildContext context, {
  required Book book,
  required LeafAttachment leaf,
}) async {
  unawaited(AppHaptics.selection());
  switch (leaf.type) {
    case LeafType.text:
      return _showNoteLeaf(context, leaf);
    case LeafType.image:
      return _showImageLeaf(context, leaf);
    case LeafType.audio:
      return _showAudioLeaf(context, leaf);
    case LeafType.link:
      return _showLinkLeaf(context, leaf);
    case LeafType.question:
      return _showQuestionLeaf(context, book, leaf);
    case LeafType.certificate:
      return showCertificateLeaf(context, book: book, leaf: leaf);
  }
}

class _LeafIconChip extends StatefulWidget {
  const _LeafIconChip({
    required this.leaf,
    required this.canManage,
    required this.onTap,
    required this.onDelete,
  });

  final LeafAttachment leaf;
  final bool canManage;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  State<_LeafIconChip> createState() => _LeafIconChipState();
}

class _LeafIconChipState extends State<_LeafIconChip> {
  bool _deleting = false;

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      await widget.onDelete();
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 76,
      height: 88,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: GlassSurface(
              borderRadius: BorderRadius.circular(18),
              onTap: _deleting ? null : widget.onTap,
              semanticButton: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 12, 9, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _leafIcon(widget.leaf),
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _leafLabel(widget.leaf),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                ),
              ),
              child: Icon(
                Icons.eco_rounded,
                size: 12,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          if (widget.canManage)
            Positioned(
              right: 5,
              top: 5,
              child: Material(
                shape: const CircleBorder(),
                color: theme.colorScheme.errorContainer,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _deleting ? null : _delete,
                  child: SizedBox.square(
                    dimension: 22,
                    child: Center(
                      child: _deleting
                          ? SizedBox.square(
                              dimension: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            )
                          : Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeafTypeButton extends StatelessWidget {
  const _LeafTypeButton({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final LeafType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: _leafTypeLabel(type),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.82)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.58)
                  : scheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _leafTypeIcon(type),
                size: 16,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Text(
                _leafTypeLabel(type),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddLeafSheet extends ConsumerStatefulWidget {
  const _AddLeafSheet({required this.book});

  final Book book;

  @override
  ConsumerState<_AddLeafSheet> createState() => _AddLeafSheetState();
}

class _AddLeafSheetState extends ConsumerState<_AddLeafSheet> {
  final _questionController = TextEditingController();
  final _linkController = TextEditingController();
  final _imagePicker = image_picker.ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _noteController = QuillController.basic();
  final _cloudinary = CloudinaryUploadService();
  Timer? _audioTimer;
  LeafType _type = LeafType.text;
  image_picker.XFile? _image;
  String? _audioPath;
  int _audioDurationMs = 0;
  bool _isRecording = false;
  bool _isSubmitting = false;
  final ValueNotifier<int> _noteCharacterCount = ValueNotifier<int>(0);
  WriterMediaInfo _linkInfo = classifyWriterMediaUrl(null);

  @override
  void initState() {
    super.initState();
    _noteController.addListener(_handleNoteChanged);
    _linkController.addListener(_handleLinkChanged);
  }

  @override
  void dispose() {
    _noteController.removeListener(_handleNoteChanged);
    _linkController.removeListener(_handleLinkChanged);
    _questionController.dispose();
    _linkController.dispose();
    _noteController.dispose();
    _noteCharacterCount.dispose();
    _audioTimer?.cancel();
    unawaited(_audioRecorder.dispose());
    super.dispose();
  }

  void _handleNoteChanged() {
    final count = _notePlainText.length;
    if (count != _noteCharacterCount.value) _noteCharacterCount.value = count;
  }

  void _handleLinkChanged() {
    final next = classifyWriterMediaUrl(_linkController.text);
    if (next.type != _linkInfo.type ||
        next.originalUrl != _linkInfo.originalUrl) {
      setState(() => _linkInfo = next);
    }
  }

  String get _notePlainText =>
      _noteController.document.toPlainText().replaceAll(RegExp(r'\n+$'), '');

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      if (_isRecording) await _stopRecording();
      final payload = await _payload(user.id);
      await ref
          .read(leafControllerProvider)
          .createLeaf(bookId: widget.book.id, leaf: payload);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Leaf added.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<Map<String, dynamic>> _payload(String userId) async {
    switch (_type) {
      case LeafType.text:
        final html = htmlFromDocument(_noteController.document);
        final plain = plainTextFromHtml(html);
        if (plain.isEmpty) {
          throw const LeafInputException('Write a note first.');
        }
        if (plain.length > maxNoteLeafCharacters) {
          throw const LeafInputException(
            'Note Leaf must be 1500 characters or fewer.',
          );
        }
        return {'type': 'text', 'textHtml': html, 'textPlain': plain};
      case LeafType.question:
        final question = _questionController.text.trim();
        if (question.isEmpty) {
          throw const LeafInputException('Write a question first.');
        }
        if (question.length > maxQuestionLeafCharacters) {
          throw const LeafInputException(
            'Question Leaf must be 500 characters or fewer.',
          );
        }
        return {'type': 'question', 'question': question};
      case LeafType.image:
        final image = _image;
        if (image == null) throw const LeafInputException('Choose an image.');
        final imageUrl = await _cloudinary.uploadImage(
          file: image,
          folder: 'leaf-images',
          userId: userId,
        );
        return {'type': 'image', 'imageUrl': imageUrl};
      case LeafType.link:
        final info = classifyWriterMediaUrl(_linkController.text);
        if (!info.isSupported ||
            info.type == WriterMediaType.unsupported ||
            info.type == WriterMediaType.amazon &&
                !info.originalUrl.contains('amazon') &&
                !info.originalUrl.contains('amzn.to')) {
          throw const LeafInputException('This Leaf link is not supported.');
        }
        return {
          'type': 'link',
          'url': info.originalUrl,
          'linkType': info.type.name,
          'title': info.label,
        };
      case LeafType.audio:
        final path = _audioPath;
        if (path == null || _audioDurationMs <= 0) {
          throw const LeafInputException('Record audio first.');
        }
        final result = await ref
            .read(audioReviewUploadServiceProvider)
            .uploadAudioReview(
              filePath: path,
              bookId: widget.book.id,
              userId: userId,
              chapterId: 'leaf',
              durationMs: _audioDurationMs,
            );
        return {
          'type': 'audio',
          'audioUrl': result.audioUrl,
          'audioObjectKey': result.audioObjectKey,
          'audioDurationMs': result.audioDurationMs,
          'audioMimeType': result.audioMimeType,
          'audioSizeBytes': result.audioSizeBytes,
        };
      case LeafType.certificate:
        throw const LeafInputException(
          'Certificate Leaves are created by the app.',
        );
    }
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: image_picker.ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1600,
    );
    if (image != null) setState(() => _image = image);
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      final status = await Permission.microphone.status;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Microphone permission is needed to record.'),
          action: status.isPermanentlyDenied
              ? SnackBarAction(label: 'Settings', onPressed: openAppSettings)
              : null,
        ),
      );
      return;
    }

    final path = kIsWeb
        ? 'leaf_${DateTime.now().millisecondsSinceEpoch}.m4a'
        : '${(await getTemporaryDirectory()).path}/leaf_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
    _audioTimer?.cancel();
    _audioTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _audioDurationMs += 1000;
      if (_audioDurationMs >= AudioReviewUploadService.maxDurationMs) {
        unawaited(_stopRecording());
      } else if (mounted) {
        setState(() {});
      }
    });
    setState(() {
      _isRecording = true;
      _audioPath = null;
      _audioDurationMs = 0;
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    final durationMs = _audioDurationMs;
    _audioTimer?.cancel();
    _audioTimer = null;
    final path = await _audioRecorder.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      if (path != null && durationMs > 0) {
        _audioPath = path;
        _audioDurationMs = durationMs.clamp(
          1000,
          AudioReviewUploadService.maxDurationMs,
        );
      } else {
        _audioPath = null;
        _audioDurationMs = 0;
      }
    });
  }

  Future<void> _removeRecording() async {
    _audioTimer?.cancel();
    _audioTimer = null;
    if (_isRecording) await _audioRecorder.cancel();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _audioPath = null;
      _audioDurationMs = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 14 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Add Leaf',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                ),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.eco_rounded, size: 16),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTypeSelector(),
            const SizedBox(height: 14),
            _buildEditor(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return GlassSurface(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final type in manualLeafTypes) ...[
              _LeafTypeButton(
                type: type,
                selected: _type == type,
                onTap: () => setState(() => _type = type),
              ),
              if (type != manualLeafTypes.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(ThemeData theme) {
    switch (_type) {
      case LeafType.text:
        return GlassSurface(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: SizedBox(
            height: 176,
            child: Stack(
              children: [
                Positioned.fill(
                  bottom: 24,
                  child: QuillEditor.basic(
                    controller: _noteController,
                    config: const QuillEditorConfig(
                      placeholder: 'Write a note...',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _noteCharacterCount,
                    builder: (context, count, _) {
                      final isOverLimit = count > maxNoteLeafCharacters;
                      return Text(
                        '$count/$maxNoteLeafCharacters',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isOverLimit
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      case LeafType.question:
        return TextField(
          controller: _questionController,
          maxLines: 4,
          maxLength: maxQuestionLeafCharacters,
          decoration: const InputDecoration(
            labelText: 'Question',
            border: OutlineInputBorder(),
          ),
        );
      case LeafType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassSurface(
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(_image == null ? 'Choose image' : _image!.name),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Max 10MB',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder(
                  future: _image!.readAsBytes(),
                  builder: (context, snapshot) => snapshot.hasData
                      ? Image.memory(
                          snapshot.data!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                ),
              ),
          ],
        );
      case LeafType.link:
        return TextField(
          controller: _linkController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'Link',
            helperText: 'YouTube, Spotify, Instagram, Amazon, or Wikipedia',
            border: const OutlineInputBorder(),
            suffixIcon: _linkInfo.isSupported
                ? Tooltip(
                    message: _linkInfo.label,
                    child: Icon(
                      _writerMediaIcon(_linkInfo.type),
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null,
            suffixIconColor: theme.colorScheme.primary,
          ),
        );
      case LeafType.audio:
        return GlassSurface(
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    _isRecording ? Icons.mic_rounded : Icons.graphic_eq_rounded,
                    color: _isRecording
                        ? Colors.red
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isRecording
                          ? 'Recording ${_formatDuration(_audioDurationMs)}'
                          : _audioPath == null
                          ? 'No audio recorded'
                          : 'Recorded ${_formatDuration(_audioDurationMs)}',
                    ),
                  ),
                  if (_isRecording)
                    IconButton(
                      tooltip: 'Stop recording',
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop_circle_outlined),
                    )
                  else
                    IconButton(
                      tooltip: 'Record audio',
                      onPressed: _startRecording,
                      icon: const Icon(Icons.mic_none_rounded),
                    ),
                  if (_isRecording || _audioPath != null)
                    IconButton(
                      tooltip: 'Delete audio',
                      onPressed: _removeRecording,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ),
              if (_audioPath != null && !_isRecording) ...[
                const SizedBox(height: 10),
                SecureAudioPlayer(
                  url: '',
                  localPath: _audioPath,
                  durationMs: _audioDurationMs,
                  label: 'Recorded audio',
                ),
              ],
            ],
          ),
        );
      case LeafType.certificate:
        return const SizedBox.shrink();
    }
  }
}

Future<void> _confirmDeleteLeaf(
  BuildContext context,
  String bookId,
  LeafAttachment leaf,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Leaf?'),
      content: const Text('This removes the Leaf from the book.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final container = ProviderScope.containerOf(context);
  try {
    await container
        .read(leafControllerProvider)
        .deleteLeaf(bookId: bookId, leafId: leaf.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Leaf deleted.')));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
    );
  }
}

void _showNoteLeaf(BuildContext context, LeafAttachment leaf) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GlassSurface(
      strong: true,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: SingleChildScrollView(
          child: HtmlWidget(sanitizeWriterHtml(leaf.textHtml ?? '')),
        ),
      ),
    ),
  );
}

void _showImageLeaf(BuildContext context, LeafAttachment leaf) {
  final url = leaf.imageUrl?.trim();
  if (url == null || url.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
        ),
      ),
    ),
  );
}

void _showAudioLeaf(BuildContext context, LeafAttachment leaf) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassSurface(
          strong: true,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Audio Leaf',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SecureAudioPlayer(
                  url: leaf.audioUrl?.trim() ?? '',
                  objectKey: leaf.audioObjectKey,
                  durationMs: leaf.audioDurationMs,
                  label: 'Audio Leaf',
                  compact: false,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _showLinkLeaf(BuildContext context, LeafAttachment leaf) async {
  final url = leaf.url?.trim();
  if (url == null || url.isEmpty) return;
  final linkType = leaf.linkType;
  if (linkType == LeafLinkType.amazon || linkType == LeafLinkType.wikipedia) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GlassSurface(
      strong: true,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: InAppMediaWebView(url: url),
        ),
      ),
    ),
  );
}

void _showQuestionLeaf(BuildContext context, Book book, LeafAttachment leaf) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GlassSurface(
      strong: true,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (book.coverUrl?.trim().isNotEmpty == true)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      width: 48,
                      height: 68,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              leaf.question ?? leaf.textPlain ?? '',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showCreatePostSheet(
                    context,
                    initialQuestion: leaf.question ?? leaf.textPlain,
                    lockQuestion: true,
                    bookId: book.id,
                    bookTitle: book.title,
                    bookAuthorName: book.authors.isNotEmpty
                        ? book.authors.first.name
                        : null,
                    bookCover: book.coverUrl,
                  );
                },
                icon: const Icon(Icons.reply_rounded),
                label: const Text('Reply'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

IconData _leafIcon(LeafAttachment leaf) => _leafTypeIcon(leaf.type);

IconData _leafTypeIcon(LeafType type) {
  return switch (type) {
    LeafType.text => Icons.sticky_note_2_outlined,
    LeafType.image => Icons.image_outlined,
    LeafType.link => Icons.link_rounded,
    LeafType.audio => Icons.graphic_eq_rounded,
    LeafType.question => Icons.help_outline_rounded,
    LeafType.certificate => Icons.card_membership_outlined,
  };
}

IconData _writerMediaIcon(WriterMediaType type) {
  return switch (type) {
    WriterMediaType.youtube => Icons.smart_display_outlined,
    WriterMediaType.instagram => Icons.photo_camera_outlined,
    WriterMediaType.spotify => Icons.album_outlined,
    WriterMediaType.amazon => Icons.shopping_bag_outlined,
    WriterMediaType.wikipedia => Icons.menu_book_outlined,
    WriterMediaType.unsupported => Icons.link_rounded,
  };
}

String _leafLabel(LeafAttachment leaf) {
  if (leaf.type == LeafType.link && leaf.linkType != null) {
    return switch (leaf.linkType!) {
      LeafLinkType.youtube => 'YouTube',
      LeafLinkType.spotify => 'Spotify',
      LeafLinkType.instagram => 'Instagram',
      LeafLinkType.amazon => 'Amazon',
      LeafLinkType.wikipedia => 'Wikipedia',
    };
  }
  return _leafTypeLabel(leaf.type);
}

String _leafTypeLabel(LeafType type) {
  return switch (type) {
    LeafType.text => 'Note',
    LeafType.image => 'Image',
    LeafType.link => 'Link',
    LeafType.audio => 'Audio',
    LeafType.question => 'Question',
    LeafType.certificate => 'Certificate',
  };
}

String _formatDuration(int durationMs) {
  final totalSeconds = (durationMs ~/ 1000).clamp(0, 120);
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class LeafInputException implements Exception {
  const LeafInputException(this.message);

  final String message;

  @override
  String toString() => message;
}
