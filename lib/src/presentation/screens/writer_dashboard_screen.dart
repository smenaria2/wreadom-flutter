import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/book_collaboration_utils.dart';
import '../components/writer/writer_book_card.dart';
import '../components/writer/writer_dashboard_header.dart';
import '../components/writer/social_studio_info.dart';
import '../providers/auth_providers.dart';
import '../providers/writer_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../routing/writer_pad_mode.dart';
import '../widgets/auth_required_view.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';
import '../widgets/themed_empty_state.dart';

class WriterDashboardScreen extends ConsumerWidget {
  const WriterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final activeTab = ref.watch(writerDashboardTabProvider);
    final booksAsync = ref.watch(filteredMyBooksProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.asData?.value;

    if (currentUserAsync.isLoading) {
      return GlassScaffold(
        appBar: glassAppBar(title: Text(l10n.writerDashboard)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUser == null) {
      return GlassScaffold(
        appBar: glassAppBar(title: Text(l10n.writerDashboard)),
        body: const AuthRequiredView(icon: Icons.edit_note_outlined),
      );
    }

    return GlassScaffold(
      body: RefreshIndicator(
        onRefresh: activeTab == 'social'
            ? () async {}
            : () => ref.refresh(filteredMyBooksProvider.future),
        child: CustomScrollView(
          slivers: [
            glassSliverAppBar(
              title: Text(
                l10n.writerDashboard,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              floating: true,
              pinned: true,
            ),
            if (activeTab == 'social')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: GlassSurface(
                    strong: true,
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => _openSocialStudio(context),
                    semanticButton: true,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -36,
                            top: -48,
                            child: Container(
                              width: 148,
                              height: 148,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.10,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 44,
                            bottom: -54,
                            child: Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.tertiary.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(17),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            theme.colorScheme.primary,
                                            theme.colorScheme.tertiary,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.22),
                                            blurRadius: 18,
                                            offset: const Offset(0, 7),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Colors.white,
                                        size: 27,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.socialStudioEyebrow,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.15,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.socialStudio,
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.35,
                                                ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            l10n.socialStudioDescription,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  height: 1.35,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 17),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SocialStudioFeature(
                                        icon: Icons.movie_creation_outlined,
                                        label: l10n.socialStudioReels,
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: _SocialStudioFeature(
                                        icon: Icons.menu_book_outlined,
                                        label: l10n.socialStudioManuscript,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.colorScheme.primary,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: theme.colorScheme.onPrimary,
                                        size: 21,
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
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: WriterDashboardHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Column(
                  children: [
                    GlassControlSurface(
                      borderRadius: BorderRadius.circular(26),
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'published',
                            label: Text(l10n.published),
                            icon: const Icon(Icons.public_rounded),
                          ),
                          ButtonSegment(
                            value: 'draft',
                            label: Text(l10n.drafts),
                            icon: const Icon(Icons.edit_note_rounded),
                          ),
                          ButtonSegment(
                            value: 'social',
                            label: Text(l10n.socialStudio),
                            icon: const Icon(Icons.auto_awesome_rounded),
                          ),
                        ],
                        selected: {activeTab},
                        showSelectedIcon: false,
                        expandedInsets: EdgeInsets.zero,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                          ),
                          textStyle: WidgetStatePropertyAll(
                            TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        onSelectionChanged: (selection) {
                          ref
                              .read(writerDashboardTabProvider.notifier)
                              .setTab(selection.first);
                        },
                      ),
                    ),
                    if (activeTab != 'social') ...[
                      const SizedBox(height: 12),
                      GlassSurface(
                        strong: true,
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.writerPad,
                            arguments: const WriterPadArguments(),
                          );
                        },
                        semanticButton: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.createContent,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (activeTab == 'social')
              SliverToBoxAdapter(
                child: SocialStudioInfo(
                  onOpenStudio: () => _openSocialStudio(context),
                ),
              )
            else
              booksAsync.when(
                data: (books) {
                  if (books.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: ThemedEmptyState(
                        icon: Icons.auto_stories_outlined,
                        iconSize: 64,
                        message: activeTab == 'published'
                            ? l10n.noPublishedStoriesYet
                            : l10n.noDraftsYet,
                        textStyle: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 132),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final book = books[index];
                        final isPublished = book.status == 'published';
                        void openEditor() async {
                          await Navigator.of(context).pushNamed(
                            AppRoutes.writerPad,
                            arguments: WriterPadArguments(book: book),
                          );
                          if (context.mounted) {
                            ref.invalidate(filteredMyBooksProvider);
                          }
                        }

                        void openStoryPage() {
                          Navigator.of(context).pushNamed(
                            AppRoutes.bookDetail,
                            arguments: BookDetailArguments(
                              bookId: book.id,
                              book: book,
                            ),
                          );
                        }

                        return WriterBookCard(
                          book: book,
                          onTap: isPublished ? openStoryPage : openEditor,
                          onEditStory: isPublished ? openEditor : null,
                          onDeleteDraft:
                              isPublished ||
                                  !canDeleteCollaborativeBook(
                                    book,
                                    currentUser.id,
                                  )
                              ? null
                              : () =>
                                    _confirmDeleteDraft(context, ref, book.id),
                          onDeleteBlocked:
                              !isPublished &&
                                  isAcceptedCollaboration(book) &&
                                  book.authorId?.trim() == currentUser.id
                              ? () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.removeCollabBeforeDelete,
                                        ),
                                      ),
                                    )
                              : null,
                        );
                      }, childCount: books.length),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: Center(
                    child: Text(l10n.failedToLoadWithError(error.toString())),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSocialStudio(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse('https://publish.wreadom.in'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.couldNotOpenSocialStudio),
        ),
      );
    }
  }

  Future<void> _confirmDeleteDraft(
    BuildContext context,
    WidgetRef ref,
    String bookId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDraftTitle),
        content: Text(l10n.deleteDraftBody),
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
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(writerRepositoryProvider).deleteBook(bookId);
      ref.invalidate(myBooksProvider);
      ref.invalidate(filteredMyBooksProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.draftDeleted)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotDeleteDraft(error.toString()))),
      );
    }
  }
}

class _SocialStudioFeature extends StatelessWidget {
  const _SocialStudioFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: theme.colorScheme.primary),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
