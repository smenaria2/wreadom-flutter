import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/feed_post.dart';
import '../providers/auth_providers.dart';
import '../providers/feed_providers.dart';

void showCreatePostSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _CreatePostSheet(),
  );
}

class _CreatePostSheet extends ConsumerStatefulWidget {
  const _CreatePostSheet();

  @override
  ConsumerState<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<_CreatePostSheet> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  bool _isSubmitting = false;
  String _visibility = 'public';
  XFile? _pickedImage;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (image != null) {
        setState(() => _pickedImage = image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage() {
    setState(() => _pickedImage = null);
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.writeSomethingFirst)));
      return;
    }

    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.loginToPost)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        imageUrl = await ref
            .read(feedRepositoryProvider)
            .uploadPostImage(bytes, _pickedImage!.name);
      }

      final post = FeedPost(
        userId: user.id,
        username: user.username,
        displayName: user.displayName,
        penName: user.penName,
        userPhotoURL: user.photoURL,
        type: 'post',
        text: text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        likes: const [],
        visibility: _visibility,
        privacy: _visibility,
        imageUrl: imageUrl,
      );

      await ref.read(feedRepositoryProvider).createFeedPost(post);
      ref.invalidate(feedPostsProvider);
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.public));
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.following));
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.mine));
      ref.invalidate(pagedFeedPostsProvider(FeedFilter.public));
      ref.invalidate(pagedFeedPostsProvider(FeedFilter.following));
      ref.invalidate(pagedFeedPostsProvider(FeedFilter.mine));

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.postShared),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithDetails(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;
    final photoUrl = user?.photoURL;
    final name =
        user?.displayName ?? user?.penName ?? user?.username ?? 'Reader';
    final username = user?.username ?? 'reader';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 18 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                l10n.shareAnUpdate,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.close,
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.postBtn),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(photoUrl)
                          : null,
                      child: photoUrl == null || photoUrl.isEmpty
                          ? Text(
                              name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '@$username',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _VisibilitySelector(
                      value: _visibility,
                      onChanged: (val) => setState(() => _visibility = val!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _textController,
                  maxLines: 7,
                  minLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.postHint,
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                  ),
                ),
                if (_pickedImage != null) ...[
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: FutureBuilder<Uint8List>(
                          future: _pickedImage!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            }
                            return const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filledTonal(
                          onPressed: _removeImage,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          tooltip: l10n.removeImage,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 24),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      tooltip: l10n.addImage,
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pickedImage == null
                            ? l10n.addImage
                            : _pickedImage!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilitySelector extends StatelessWidget {
  const _VisibilitySelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          iconSize: 18,
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          items: [
            DropdownMenuItem(
              value: 'public',
              child: Text(AppLocalizations.of(context)!.public),
            ),
            DropdownMenuItem(
              value: 'followers',
              child: Text(AppLocalizations.of(context)!.followers),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
