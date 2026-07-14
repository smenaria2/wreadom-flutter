import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../domain/models/book_collection.dart';

String collectionHeroTag(String collectionId, [String scope = 'default']) =>
    'collection-cover-$scope-$collectionId';

class CollectionCoverCollage extends StatelessWidget {
  const CollectionCoverCollage({
    super.key,
    required this.collection,
    this.borderRadius = 24,
  });

  final BookCollection collection;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final urls = collection.coverBooks
        .map((cover) => cover.coverUrl)
        .where((url) => url.isNotEmpty)
        .take(4)
        .toList();

    Widget content;
    if (urls.isEmpty) {
      content = const Center(child: Icon(Icons.collections_bookmark, size: 48));
    } else if (urls.length == 1) {
      content = _CollageImage(url: urls[0]);
    } else if (urls.length == 2) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _CollageImage(url: urls[0])),
          const SizedBox(width: 2),
          Expanded(child: _CollageImage(url: urls[1])),
        ],
      );
    } else if (urls.length == 3) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _CollageImage(url: urls[0])),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _CollageImage(url: urls[1])),
                const SizedBox(height: 2),
                Expanded(child: _CollageImage(url: urls[2])),
              ],
            ),
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _CollageImage(url: urls[0])),
                const SizedBox(width: 2),
                Expanded(child: _CollageImage(url: urls[1])),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _CollageImage(url: urls[2])),
                const SizedBox(width: 2),
                Expanded(child: _CollageImage(url: urls[3])),
              ],
            ),
          ),
        ],
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      image: true,
      label:
          '${collection.title}, ${l10n.collectionBookCount(collection.bookCount)}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: content,
        ),
      ),
    );
  }
}

class _CollageImage extends StatelessWidget {
  const _CollageImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => const ColoredBox(color: Color(0x14000000)),
      errorWidget: (_, _, _) =>
          const Center(child: Icon(Icons.auto_stories_outlined, size: 20)),
    );
  }
}

class CollectionCard extends StatelessWidget {
  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
    this.heroScope = 'default',
  });

  final BookCollection collection;
  final VoidCallback onTap;
  final String heroScope;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final l10n = AppLocalizations.of(context)!;
    final cover = CollectionCoverCollage(collection: collection);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: reduceMotion
                  ? cover
                  : Hero(
                      tag: collectionHeroTag(collection.id, heroScope),
                      flightShuttleBuilder: (_, animation, _, from, _) =>
                          FadeTransition(
                            opacity: animation,
                            child: from.widget,
                          ),
                      child: cover,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(l10n.collectionBookCount(collection.bookCount)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
