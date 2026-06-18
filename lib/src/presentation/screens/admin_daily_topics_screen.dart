import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../data/services/cloudinary_upload_service.dart';
import '../../domain/models/homepage/homepage_metadata.dart';
import '../providers/admin_topic_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';

class AdminDailyTopicsScreen extends ConsumerStatefulWidget {
  const AdminDailyTopicsScreen({super.key});

  @override
  ConsumerState<AdminDailyTopicsScreen> createState() =>
      _AdminDailyTopicsScreenState();
}

class _AdminDailyTopicsScreenState
    extends ConsumerState<AdminDailyTopicsScreen> {
  final _imagePicker = ImagePicker();
  final _cloudinary = CloudinaryUploadService();
  bool _saving = false;
  bool _uploading = false;
  int _visibleTopicCount = 7;
  DailyTopic? _editing;

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(currentUserAdminClaimProvider);
    final l10n = AppLocalizations.of(context)!;
    return GlassScaffold(
      appBar: glassAppBar(title: Text(l10n.adminDailyTopicsTitle)),
      body: isAdminAsync.when(
        data: (isAdmin) {
          if (!isAdmin) return _AdminDenied(message: l10n.adminAccessRequired);
          return _AdminTopicBody(
            editing: _editing,
            saving: _saving,
            uploading: _uploading,
            visibleTopicCount: _visibleTopicCount,
            onCreate: () => setState(() => _editing = _emptyTopic()),
            onEdit: (topic) => setState(() => _editing = topic),
            onCancelEdit: () => setState(() => _editing = null),
            onLoadMore: () => setState(() => _visibleTopicCount += 7),
            onSave: _saveTopic,
            onDelete: _deleteTopic,
            onToggle: _toggleTopic,
            onPickCover: _pickCover,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  DailyTopic _emptyTopic() {
    return DailyTopic(timestamp: DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _saveTopic(DailyTopic topic) async {
    final l10n = AppLocalizations.of(context)!;
    if (_saving) return;
    if (topic.topicName.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.topicNameRequired)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(adminDailyTopicControllerProvider).saveTopic(topic);
      if (!mounted) return;
      setState(() => _editing = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.topicSaved)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleTopic(DailyTopic topic, bool enabled) async {
    await ref
        .read(adminDailyTopicControllerProvider)
        .setEnabled(topic, enabled);
  }

  Future<void> _deleteTopic(DailyTopic topic) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTopicTitle),
        content: Text(l10n.deleteTopicBody(topic.topicName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(adminDailyTopicControllerProvider).deleteTopic(topic);
    if (mounted && _editing?.id == topic.id) {
      setState(() => _editing = null);
    }
  }

  Future<void> _pickCover(DailyTopic topic) async {
    final l10n = AppLocalizations.of(context)!;
    if (_uploading) return;
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1600,
    );
    if (image == null) return;
    setState(() => _uploading = true);
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception(l10n.signInAgainToUploadImages);
      final url = await _cloudinary.uploadImage(
        file: image,
        folder: 'daily_topics',
        userId: user.id,
        deliveryTransform: 'f_auto,q_auto,w_1200,c_fill,ar_16:9',
      );
      if (!mounted) return;
      setState(() => _editing = topic.copyWith(coverImageUrl: url));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

class _AdminTopicBody extends ConsumerWidget {
  const _AdminTopicBody({
    required this.editing,
    required this.saving,
    required this.uploading,
    required this.visibleTopicCount,
    required this.onCreate,
    required this.onEdit,
    required this.onCancelEdit,
    required this.onLoadMore,
    required this.onSave,
    required this.onDelete,
    required this.onToggle,
    required this.onPickCover,
  });

  final DailyTopic? editing;
  final bool saving;
  final bool uploading;
  final int visibleTopicCount;
  final VoidCallback onCreate;
  final ValueChanged<DailyTopic> onEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onLoadMore;
  final ValueChanged<DailyTopic> onSave;
  final ValueChanged<DailyTopic> onDelete;
  final void Function(DailyTopic topic, bool enabled) onToggle;
  final ValueChanged<DailyTopic> onPickCover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final topicsAsync = ref.watch(adminDailyTopicsProvider);
    return topicsAsync.when(
      data: (topics) {
        final visibleTopics = topics.take(visibleTopicCount).toList();
        final hasMore = visibleTopicCount < topics.length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (editing == null)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.newTopic),
                ),
              )
            else
              _TopicEditor(
                topic: editing!,
                saving: saving,
                uploading: uploading,
                onCancel: onCancelEdit,
                onSave: onSave,
                onPickCover: onPickCover,
              ),
            const SizedBox(height: 14),
            if (topics.isEmpty)
              _EmptyTopics(message: l10n.noTopicsFound)
            else
              for (final topic in visibleTopics) ...[
                _TopicTile(
                  topic: topic,
                  onEdit: () => onEdit(topic),
                  onDelete: () => onDelete(topic),
                  onToggle: (enabled) => onToggle(topic, enabled),
                ),
                const SizedBox(height: 10),
              ],
            if (hasMore)
              Center(
                child: OutlinedButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.expand_more_rounded),
                  label: Text(l10n.loadMoreTopics),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

class _TopicEditor extends StatefulWidget {
  const _TopicEditor({
    required this.topic,
    required this.saving,
    required this.uploading,
    required this.onCancel,
    required this.onSave,
    required this.onPickCover,
  });

  final DailyTopic topic;
  final bool saving;
  final bool uploading;
  final VoidCallback onCancel;
  final ValueChanged<DailyTopic> onSave;
  final ValueChanged<DailyTopic> onPickCover;

  @override
  State<_TopicEditor> createState() => _TopicEditorState();
}

class _TopicEditorState extends State<_TopicEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _fullDescriptionController;
  late bool _isEnabled;
  late String _coverImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.topic.topicName);
    _descriptionController = TextEditingController(
      text: widget.topic.description,
    );
    _fullDescriptionController = TextEditingController(
      text: widget.topic.fullDescription,
    );
    _isEnabled = widget.topic.isEnabled;
    _coverImageUrl = widget.topic.coverImageUrl;
  }

  @override
  void didUpdateWidget(covariant _TopicEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topic != widget.topic) {
      _nameController.text = widget.topic.topicName;
      _descriptionController.text = widget.topic.description;
      _fullDescriptionController.text = widget.topic.fullDescription;
      _isEnabled = widget.topic.isEnabled;
      _coverImageUrl = widget.topic.coverImageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _fullDescriptionController.dispose();
    super.dispose();
  }

  DailyTopic get _value => widget.topic.copyWith(
    topicName: _nameController.text,
    description: _descriptionController.text,
    fullDescription: _fullDescriptionController.text,
    isEnabled: _isEnabled,
    coverImageUrl: _coverImageUrl,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return GlassSurface(
      strong: true,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.topic.id.isEmpty ? l10n.newTopic : l10n.editTopic,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.cancel,
                onPressed: widget.saving ? null : widget.onCancel,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.topicName,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.shortDescription,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _fullDescriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: l10n.fullDescription,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _isEnabled,
            onChanged: (value) => setState(() => _isEnabled = value),
            title: Text(l10n.enabled),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 10),
          _CoverPreview(
            imageUrl: _coverImageUrl,
            uploading: widget.uploading,
            onPick: () => widget.onPickCover(_value),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: widget.saving ? null : () => widget.onSave(_value),
            icon: widget.saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(widget.saving ? l10n.saving : l10n.saveTopic),
          ),
        ],
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({
    required this.imageUrl,
    required this.uploading,
    required this.onPick,
  });

  final String imageUrl;
  final bool uploading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.trim().isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: scheme.surfaceContainerHigh,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ColoredBox(
                color: scheme.surfaceContainerHigh,
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 36,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            Positioned(
              right: 10,
              bottom: 10,
              child: FilledButton.icon(
                onPressed: uploading ? null : onPick,
                icon: uploading
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_outlined),
                label: Text(uploading ? l10n.uploading : l10n.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.topic,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final DailyTopic topic;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return GlassSurface(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 48,
              child: topic.coverImageUrl.trim().isEmpty
                  ? ColoredBox(
                      color: theme.colorScheme.surfaceContainerHigh,
                      child: Icon(
                        Icons.image_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Image.network(
                      topic.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHigh,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.topicName.isEmpty
                      ? l10n.untitledTopic
                      : topic.topicName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  topic.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(value: topic.isEnabled, onChanged: onToggle),
          IconButton(
            tooltip: l10n.editTopic,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: l10n.delete,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _AdminDenied extends StatelessWidget {
  const _AdminDenied({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

class _EmptyTopics extends StatelessWidget {
  const _EmptyTopics({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(message)),
    );
  }
}
