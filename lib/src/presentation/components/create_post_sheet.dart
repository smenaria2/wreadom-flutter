import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/services/analytics_service.dart';
import '../../domain/models/feed_post.dart';
import '../../utils/app_haptics.dart';
import '../providers/auth_providers.dart';
import '../providers/feed_providers.dart';
import '../widgets/auth_required_view.dart';
import '../widgets/glass_surface.dart';

void showCreatePostSheet(
  BuildContext context, {
  String? initialQuestion,
  bool lockQuestion = false,
  String? bookId,
  String? bookTitle,
  String? bookAuthorName,
  String? bookCover,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => GlassSurface(
      strong: true,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: _CreatePostSheet(
        initialQuestion: initialQuestion,
        lockQuestion: lockQuestion,
        bookId: bookId,
        bookTitle: bookTitle,
        bookAuthorName: bookAuthorName,
        bookCover: bookCover,
      ),
    ),
  );
}

class _CreatePostSheet extends ConsumerStatefulWidget {
  final String? initialQuestion;
  final bool lockQuestion;
  final String? bookId;
  final String? bookTitle;
  final String? bookAuthorName;
  final String? bookCover;
  const _CreatePostSheet({
    this.initialQuestion,
    this.lockQuestion = false,
    this.bookId,
    this.bookTitle,
    this.bookAuthorName,
    this.bookCover,
  });

  @override
  ConsumerState<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<_CreatePostSheet> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  bool _isSubmitting = false;
  String _visibility = 'public';
  XFile? _pickedImage;
  String? _currentQuestion;
  bool _isChangingQuestion = false;
  bool _isAnsweringQuestion = false;
  bool _isQuestionDynamic = false;

  @override
  void initState() {
    super.initState();
    _currentQuestion = widget.initialQuestion;
    _isAnsweringQuestion = widget.initialQuestion != null;
    _isQuestionDynamic = false;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _removeQuestion() {
    setState(() {
      _currentQuestion = null;
      _isAnsweringQuestion = false;
      _isQuestionDynamic = false;
    });
  }

  Future<void> _changeQuestion() async {
    if (_isChangingQuestion) return;
    setState(() => _isChangingQuestion = true);
    try {
      final questions = await ref.read(activeQuestionsProvider.future);
      if (questions.isNotEmpty) {
        final others = questions.where((q) => q != _currentQuestion).toList();
        final pool = others.isNotEmpty ? others : questions;
        pool.shuffle();
        if (mounted) setState(() => _currentQuestion = pool.first);
      }
    } catch (_) {
      // silently ignore
    } finally {
      if (mounted) setState(() => _isChangingQuestion = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (image != null) setState(() => _pickedImage = image);
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage() => setState(() => _pickedImage = null);

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.writeSomethingFirst),
        ),
      );
      return;
    }

    final user = await ref.read(currentUserProvider.future);
    if (!mounted) return;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loginToPost)),
      );
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
        question: _isAnsweringQuestion ? _currentQuestion : null,
        bookId: widget.bookId,
        bookTitle: widget.bookTitle,
        bookAuthorName: widget.bookAuthorName,
        bookCover: widget.bookCover,
      );

      await ref.read(feedRepositoryProvider).createFeedPost(post);
      AnalyticsService.logPostCreate();
      await AppHaptics.light();
      ref.invalidate(feedPostsProvider);
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.public));
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.following));
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.mine));
      ref.invalidate(pagedFeedPostsProvider(FeedFilter.public));
      ref.invalidate(pagedFeedPostsProvider(FeedFilter.following));
      ref.invalidate(pagedFeedPostsProvider(FeedFilter.mine));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.postShared),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorWithDetails(e.toString()),
            ),
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
    final currentUserAsync = ref.watch(currentUserProvider);
    final user = currentUserAsync.asData?.value;
    final photoUrl = user?.photoURL;
    final name =
        user?.displayName ?? user?.penName ?? user?.username ?? 'Reader';
    final username = user?.username ?? 'reader';

    // Loading state
    if (currentUserAsync.isLoading) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 18 + bottomInset),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Unauthenticated state
    if (user == null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 18 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DragHandle(),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  l10n.shareAnUpdate,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: l10n.close,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const AuthRequiredView(
              icon: Icons.edit_rounded,
              padding: EdgeInsets.fromLTRB(16, 24, 16, 32),
            ),
          ],
        ),
      );
    }

    // Main post creation UI
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            _DragHandle(),
            const SizedBox(height: 10),

            // Header row: title + close + post button
            Row(
              children: [
                Text(
                  l10n.shareAnUpdate,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: l10n.close,
                  visualDensity: VisualDensity.compact,
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                _GlassPostButton(
                  label: l10n.postBtn,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Main card
            GlassSurface(
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question prompt card
                  if (_isAnsweringQuestion && _currentQuestion != null) ...[
                    GlassSurface(
                      margin: const EdgeInsets.only(bottom: 8),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 3,
                                  height: 32,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _currentQuestion!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      height: 1.3,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_isQuestionDynamic) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _QuestionActionChip(
                                    icon: Icons.refresh_rounded,
                                    isLoading: _isChangingQuestion,
                                    label: 'Change',
                                    color: theme.colorScheme.primary,
                                    onTap: _isChangingQuestion
                                        ? null
                                        : _changeQuestion,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 10,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                  _QuestionActionChip(
                                    icon: Icons.close_rounded,
                                    label: 'Remove',
                                    color: theme.colorScheme.onSurfaceVariant,
                                    onTap: _removeQuestion,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  // User info row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(photoUrl)
                            : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? Text(
                                name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
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
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '@$username',
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
                      _VisibilitySelector(
                        value: _visibility,
                        onChanged: (val) => setState(() => _visibility = val!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Option to answer question (only when initialQuestion is null)
                  if (widget.initialQuestion == null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 18,
                          color: _isAnsweringQuestion
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.answerLeafQuestion,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isAnsweringQuestion
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            value: _isAnsweringQuestion,
                            onChanged: (val) async {
                              setState(() {
                                _isAnsweringQuestion = val;
                                _isQuestionDynamic = val;
                              });
                              if (_isAnsweringQuestion) {
                                if (_currentQuestion == null) {
                                  await _changeQuestion();
                                }
                              } else {
                                setState(() {
                                  _currentQuestion = null;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Text input
                  TextField(
                    controller: _textController,
                    maxLines: 6,
                    minLines: 3,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _isAnsweringQuestion
                          ? l10n.answerQuestionHint
                          : l10n.postHint,
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),

                  // Image preview
                  if (_pickedImage != null) ...[
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: FutureBuilder<Uint8List>(
                            future: _pickedImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              }
                              return const SizedBox(
                                height: 160,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: IconButton.filledTonal(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            tooltip: l10n.removeImage,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(28, 28),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Divider + image picker
                  const Divider(height: 18),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _pickImage,
                        icon: Icon(
                          Icons.image_outlined,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        tooltip: l10n.addImage,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      const SizedBox(width: 6),
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
      ),
    );
  }
}

/// Compact pill-shaped action chip for question actions.
class _QuestionActionChip extends StatelessWidget {
  const _QuestionActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
            )
          else if (icon != null)
            Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small drag handle indicator at the top of the sheet.
class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
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
    return GlassSurface(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          iconSize: 16,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          iconEnabledColor: theme.colorScheme.primary,
          dropdownColor: theme.colorScheme.surfaceContainerHighest,
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

class _GlassPostButton extends StatelessWidget {
  const _GlassPostButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.58,
      child: GlassSurface(
        strong: true,
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        semanticButton: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 52, minHeight: 20),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
