import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/collection_providers.dart';
import '../../routing/app_router.dart';
import '../../routing/app_routes.dart';
import 'collection_form_sheet.dart';
import 'collection_widgets.dart';

class CollectionList extends ConsumerWidget {
  const CollectionList({
    super.key,
    required this.userId,
    this.canCreate = false,
  });

  final String userId;
  final bool canCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(userCollectionsProvider(userId));
    return collections.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canCreate)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: () => showCollectionFormSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('New collection'),
              ),
            ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No collections yet.')),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                childAspectRatio: .78,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (_, index) => CollectionCard(
                collection: items[index],
                heroScope: 'profile-$userId',
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.collectionDetail,
                  arguments: CollectionDetailArguments(
                    collectionId: items[index].id,
                    heroScope: 'profile-$userId',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
