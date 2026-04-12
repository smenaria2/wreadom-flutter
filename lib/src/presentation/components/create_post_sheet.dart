import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/feed_post.dart';
import '../providers/auth_providers.dart';
import '../providers/feed_providers.dart';

enum _PostType { post, quote, review, testimony }

extension _PostTypeExt on _PostType {
  String get label {
    switch (this) {
      case _PostType.post:
        return 'Post';
      case _PostType.quote:
        return 'Quote';
      case _PostType.review:
        return 'Review';
      case _PostType.testimony:
        return 'Testimony';
    }
  }

  IconData get icon {
    switch (this) {
      case _PostType.post:
        return Icons.edit_note_rounded;
      case _PostType.quote:
        return Icons.format_quote_rounded;
      case _PostType.review:
        return Icons.star_rounded;
      case _PostType.testimony:
        return Icons.favorite_rounded;
    }
  }

  String get hint {
    switch (this) {
      case _PostType.post:
        return 'Share your thoughts with the community…';
      case _PostType.quote:
        return 'Share an inspiring quote from a book…';
      case _PostType.review:
        return 'Write your review…';
      case _PostType.testimony:
        return 'Share how a book changed your life…';
    }
  }
}

/// Shows a draggable bottom sheet for creating feed posts.
void showCreatePostSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
  _PostType _selectedType = _PostType.post;
  int _rating = 0;
  bool _isSubmitting = false;
  String _visibility = 'public';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first')),
      );
      return;
    }

    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to post')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final post = FeedPost(
        userId: user.id,
        username: user.username,
        displayName: user.displayName,
        penName: user.penName,
        userPhotoURL: user.photoURL,
        type: _selectedType.name,
        text: text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        likes: const [],
        visibility: _visibility,
        privacy: _visibility,
        rating: _selectedType == _PostType.review && _rating > 0 ? _rating : null,
      );

      await ref.read(feedRepositoryProvider).createFeedPost(post);
      ref.invalidate(feedPostsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post shared! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header row
          Row(
            children: [
              Text(
                'Create ${_selectedType.label}',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Post'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Post type selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _PostType.values.map((type) {
                final selected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(type.icon,
                        size: 16,
                        color: selected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary),
                    label: Text(type.label),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedType = type),
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : null,
                      fontWeight: selected ? FontWeight.bold : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Star rating (only for review)
          if (_selectedType == _PostType.review) ...[
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                );
              }),
            ),
            const SizedBox(height: 8),
          ],

          DropdownButtonFormField<String>(
            value: _visibility,
            decoration: const InputDecoration(labelText: 'Visibility'),
            items: const [
              DropdownMenuItem(value: 'public', child: Text('Public')),
              DropdownMenuItem(value: 'followers', child: Text('Followers')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _visibility = value);
              }
            },
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _textController,
            maxLines: 5,
            minLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: _selectedType.hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}
