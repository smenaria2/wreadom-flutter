import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../domain/models/book.dart';
import '../../../utils/app_haptics.dart';
import '../../providers/collection_providers.dart';
import 'collection_form_sheet.dart';

import '../../providers/navigation_providers.dart';

Future<void> showAddToCollectionSheet(BuildContext context, Book book) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddToCollectionSheet(book: book),
    );

class AddToCollectionSheet extends ConsumerStatefulWidget {
  const AddToCollectionSheet({super.key, required this.book});

  final Book book;

  @override
  ConsumerState<AddToCollectionSheet> createState() =>
      _AddToCollectionSheetState();
}

class _AddToCollectionSheetState extends ConsumerState<AddToCollectionSheet> {
  Set<String>? _selected;
  Set<String> _initial = const {};
  bool _saving = false;
  String? _error;

  void _initialize(Set<String> memberships) {
    if (_selected != null) return;
    _initial = Set.of(memberships);
    _selected = Set.of(memberships);
  }

  Future<void> _save() async {
    if (_saving || _selected == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repository = ref.read(collectionRepositoryProvider);
    final additions = _selected!.difference(_initial);
    final removals = _initial.difference(_selected!);
    try {
      for (final collectionId in additions) {
        await repository.addBooks(collectionId, [widget.book.id]);
      }
      for (final collectionId in removals) {
        await repository.removeBook(collectionId, widget.book.id);
      }
      ref.invalidate(bookCollectionMembershipsProvider(widget.book.id));
      await AppHaptics.selection();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final collections = ref.watch(currentUserCollectionsProvider);
    final memberships = ref.watch(
      bookCollectionMembershipsProvider(widget.book.id),
    );
    memberships.whenData(_initialize);
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.addToCollection,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    ref.read(selectedTabProvider.notifier).setTab(4);
                    ref.read(profileTabIndexProvider.notifier).setIndex(1);
                  },
                  label: Text(l10n.collections),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: l10n.close,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: memberships.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : collections.when(
                      data: (items) => items.isEmpty
                          ? Center(child: Text(l10n.noCollectionsYet))
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (_, index) {
                                final collection = items[index];
                                final selected =
                                    _selected?.contains(collection.id) ?? false;
                                return CheckboxListTile(
                                  value: selected,
                                  title: Text(collection.title),
                                  subtitle: Text(
                                    l10n.collectionBookCount(
                                      collection.bookCount,
                                    ),
                                  ),
                                  onChanged: _saving
                                      ? null
                                      : (value) {
                                          setState(() {
                                            final next = Set<String>.of(
                                              _selected ?? const {},
                                            );
                                            value == true
                                                ? next.add(collection.id)
                                                : next.remove(collection.id);
                                            _selected = next;
                                          });
                                          AppHaptics.selection();
                                        },
                                );
                              },
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) =>
                          Center(child: Text(error.toString())),
                    ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final id = await showCollectionFormSheet(context);
                      if (id == null) return;
                      await ref.read(collectionRepositoryProvider).addBooks(
                        id,
                        [widget.book.id],
                      );
                      ref.invalidate(
                        bookCollectionMembershipsProvider(widget.book.id),
                      );
                      if (mounted) navigator.pop();
                    },
              icon: const Icon(Icons.add),
              label: Text(l10n.createNewCollection),
            ),
            FilledButton(
              onPressed: _saving || _selected == null ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.saveSelection),
            ),
          ],
        ),
      ),
    );
  }
}
