import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../localization/generated/app_localizations.dart';
import '../../utils/book_collaboration_utils.dart';
import '../components/generated_book_cover.dart';
import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../providers/writer_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../utils/error_message_utils.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';
import '../widgets/section_error.dart';

class CollaborationRequestScreen extends ConsumerStatefulWidget {
  const CollaborationRequestScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<CollaborationRequestScreen> createState() =>
      _CollaborationRequestScreenState();
}

class _CollaborationRequestScreenState
    extends ConsumerState<CollaborationRequestScreen> {
  bool _isResponding = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookAsync = ref.watch(bookDetailProvider(widget.bookId));
    final user = ref.watch(currentUserProvider).asData?.value;

    return GlassScaffold(
      appBar: glassAppBar(title: Text(l10n.collaborationRequestTitle)),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          logUiError('Collaboration request load failed', error, stackTrace);
          return SectionError(title: l10n.collaborationRequestTitle);
        },
        data: (book) {
          if (book == null) {
            return Center(child: Text(l10n.collaborationRequestUnavailable));
          }
          final isRecipient = user != null && book.collaboratorId == user.id;
          final canRespond = isRecipient && isPendingCollaboration(book);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassSurface(
                strong: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 150,
                        height: 225,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: book.coverUrl?.isNotEmpty == true
                              ? CachedNetworkImage(
                                  imageUrl: book.coverUrl!,
                                  fit: BoxFit.cover,
                                )
                              : GeneratedBookCover(
                                  title: book.title,
                                  author: book.authors.firstOrNull?.name,
                                  seed: book.id,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      book.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.collaborationRequestMessage(
                        book.authors.firstOrNull?.name ?? l10n.unknownAuthor,
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (book.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 18),
                      Text(book.description!.trim()),
                    ],
                    if ((book.chapters ?? const []).isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        l10n.draftPreview,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      for (final chapter in book.chapters!.take(5))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(chapter.title),
                          subtitle: Text(
                            chapter.content.replaceAll(RegExp(r'<[^>]+>'), ' '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (canRespond)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isResponding
                            ? null
                            : () => _respond(accept: false),
                        child: Text(l10n.decline),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isResponding
                            ? null
                            : () => _respond(accept: true),
                        child: _isResponding
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.accept),
                      ),
                    ),
                  ],
                )
              else
                FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(
                    AppRoutes.bookDetail,
                    arguments: BookDetailArguments(bookId: book.id, book: book),
                  ),
                  child: Text(l10n.openBook),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _respond({required bool accept}) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    setState(() => _isResponding = true);
    try {
      await ref
          .read(writerRepositoryProvider)
          .respondToCollaborationRequest(
            bookId: widget.bookId,
            userId: user.id,
            accept: accept,
          );
      ref.invalidate(bookDetailProvider(widget.bookId));
      ref.invalidate(myBooksProvider);
      ref.invalidate(filteredMyBooksProvider);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept ? l10n.collaborationAccepted : l10n.collaborationDeclined,
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      if (!mounted) return;
      logUiError('Collaboration response failed', error, stackTrace);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotUpdateCollaborationRequest)),
      );
      setState(() => _isResponding = false);
    }
  }
}
