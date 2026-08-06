import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../data/repositories/firebase_collection_repository.dart';
import '../../../domain/models/book_collection.dart';
import '../../providers/collection_providers.dart';

Future<String?> showCollectionFormSheet(
  BuildContext context, {
  BookCollection? collection,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => CollectionFormSheet(collection: collection),
);

class CollectionFormSheet extends ConsumerStatefulWidget {
  const CollectionFormSheet({super.key, this.collection});

  final BookCollection? collection;

  @override
  ConsumerState<CollectionFormSheet> createState() =>
      _CollectionFormSheetState();
}

class _CollectionFormSheetState extends ConsumerState<CollectionFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.collection?.title ?? '');
    _description = TextEditingController(
      text: widget.collection?.description ?? '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    final title = _title.text.trim();
    final description = _description.text.trim();
    if (title.isEmpty ||
        title.length > FirebaseCollectionRepository.maxTitleLength) {
      setState(() => _error = l10n.collectionNameError);
      return;
    }
    if (description.length >
        FirebaseCollectionRepository.maxDescriptionLength) {
      setState(() => _error = l10n.collectionDescriptionError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(collectionRepositoryProvider);
      final id = widget.collection == null
          ? await repo.createCollection(title: title, description: description)
          : widget.collection!.id;
      if (widget.collection != null) {
        await repo.updateCollection(id, title: title, description: description);
        ref.invalidate(collectionDetailProvider(id));
      }
      ref.invalidate(userCollectionsProvider);
      ref.invalidate(currentUserCollectionsProvider);
      if (mounted) Navigator.pop(context, id);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedPadding(
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 180),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.collection == null
                      ? l10n.createCollection
                      : l10n.editCollection,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: l10n.close,
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _title,
            maxLength: FirebaseCollectionRepository.maxTitleLength,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.collectionName),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLength: FirebaseCollectionRepository.maxDescriptionLength,
            maxLines: 4,
            decoration: InputDecoration(labelText: l10n.descriptionOptional),
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              widget.collection == null ? l10n.create : l10n.saveChanges,
            ),
          ),
        ],
      ),
    );
  }
}
