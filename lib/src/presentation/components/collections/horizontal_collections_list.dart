import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../providers/collection_providers.dart';
import '../../routing/app_router.dart';
import '../../routing/app_routes.dart';
import '../../widgets/glass_surface.dart';
import 'collection_form_sheet.dart';
import 'rounded_collection_card.dart';

class HorizontalCollectionsList extends ConsumerWidget {
  const HorizontalCollectionsList({
    super.key,
    required this.userId,
    this.canCreate = false,
  });

  final String userId;
  final bool canCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(userCollectionsProvider(userId));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return collectionsAsync.when(
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => const SizedBox.shrink(),
      data: (collections) {
        if (collections.isEmpty && !canCreate) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.collections,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(
              height: 146,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                scrollDirection: Axis.horizontal,
                itemCount: collections.length + (canCreate ? 1 : 0),
                itemBuilder: (context, index) {
                  if (canCreate && index == 0) {
                    return _CreateCollectionButton(
                      onTap: () => showCollectionFormSheet(context),
                    );
                  }
                  final collectionIndex = canCreate ? index - 1 : index;
                  final collection = collections[collectionIndex];
                  return RoundedCollectionCard(
                    collection: collection,
                    heroScope: 'profile-$userId',
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.collectionDetail,
                      arguments: CollectionDetailArguments(
                        collectionId: collection.id,
                        heroScope: 'profile-$userId',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _CreateCollectionButton extends StatelessWidget {
  const _CreateCollectionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: GlassSurface(
              borderRadius: BorderRadius.circular(40),
              onTap: onTap,
              semanticButton: true,
              child: Center(
                child: Icon(
                  Icons.add,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 84,
            child: Text(
              l10n.newCollection,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.collection,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
