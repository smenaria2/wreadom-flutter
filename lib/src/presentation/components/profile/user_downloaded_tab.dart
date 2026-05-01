import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../data/services/offline_service.dart';
import '../../../utils/format_utils.dart';
import '../../providers/book_providers.dart';
import '../../providers/homepage_providers.dart';
import '../../routing/app_router.dart';
import '../../routing/app_routes.dart';
import '../../utils/book_author_utils.dart';

class UserDownloadedTab extends ConsumerWidget {
  const UserDownloadedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(downloadedBookEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Text(
                l10n.noDownloadedBooksYet,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _DownloadedBookTile(
            entry: entries[index],
            onOpen: () => Navigator.of(context).pushNamed(
              AppRoutes.bookDetail,
              arguments: BookDetailArguments(
                bookId: entries[index].book.id,
                book: entries[index].book,
              ),
            ),
            onRemove: () => _removeDownloadedBook(context, ref, entries[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.failedToLoadDownloadedBooks(err.toString())),
        ),
      ),
    );
  }

  Future<void> _removeDownloadedBook(
    BuildContext context,
    WidgetRef ref,
    OfflineBookEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeDownloadedBookTitle),
        content: Text(l10n.removeDownloadedBookBody(entry.book.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(offlineServiceProvider).deleteBook(entry.book.id);
    ref.invalidate(downloadedBookEntriesProvider);
    ref.invalidate(downloadedBooksProvider);
    ref.invalidate(savedBooksProvider);
    ref.invalidate(homepageDownloadedBooksProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.downloadRemoved)));
  }
}

class _DownloadedBookTile extends StatelessWidget {
  const _DownloadedBookTile({
    required this.entry,
    required this.onOpen,
    required this.onRemove,
  });

  final OfflineBookEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final book = entry.book;
    final author = bookAuthorName(book);
    final downloadedAt = entry.downloadedAt == null
        ? ''
        : FormatUtils.formatDate(entry.downloadedAt);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: book.coverUrl == null || book.coverUrl!.isEmpty
                  ? Container(
                      width: 48,
                      height: 68,
                      color: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      width: 48,
                      height: 68,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (author.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _MetaChip(
                        icon: Icons.sd_storage_outlined,
                        label: _formatBytes(entry.sizeBytes),
                      ),
                      if (downloadedAt.isNotEmpty)
                        _MetaChip(
                          icon: Icons.download_done_rounded,
                          label: l10n.downloadedOn(downloadedAt),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.open,
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
                IconButton(
                  tooltip: l10n.remove,
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / kb).ceil()} KB';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
