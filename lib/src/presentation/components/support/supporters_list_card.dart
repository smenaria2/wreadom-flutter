import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../domain/models/author_support.dart';
import '../../providers/support_providers.dart';
import '../../routing/app_routes.dart';
import '../../widgets/glass_surface.dart';

/// Supporters of an author: verified (green tick) first, then readers who
/// say they paid but are not yet confirmed. The author can confirm or hide
/// entries.
class SupportersListCard extends ConsumerStatefulWidget {
  const SupportersListCard({
    super.key,
    required this.authorId,
    required this.isSelf,
  });

  final String authorId;
  final bool isSelf;

  @override
  ConsumerState<SupportersListCard> createState() => _SupportersListCardState();
}

class _SupportersListCardState extends ConsumerState<SupportersListCard> {
  static const _collapsedCount = 8;
  bool _expanded = false;

  Future<void> _setStatus(SupportClaim claim, String status) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(supportRepositoryProvider).setClaimStatus(claim, status);
      ref.invalidate(supportClaimsProvider(widget.authorId));
      if (status == SupportClaim.statusVerified) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.supportConfirmed)));
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.supportClaimFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final claims = ref.watch(supportClaimsProvider(widget.authorId)).value;
    if (claims == null) return const SizedBox.shrink();
    final visible = SupportClaim.visibleSorted(
      claims,
      forAuthor: widget.isSelf,
    );
    if (visible.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shown = _expanded ? visible : visible.take(_collapsedCount).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GlassSurface(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 18, color: Colors.pink),
                  const SizedBox(width: 8),
                  Text(l10n.supportersTitle, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            for (final claim in shown)
              _SupporterTile(
                claim: claim,
                isSelf: widget.isSelf,
                onConfirm: () => _setStatus(claim, SupportClaim.statusVerified),
                onHide: () => _setStatus(claim, SupportClaim.statusHidden),
              ),
            if (visible.length > _collapsedCount)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? l10n.showLess : l10n.seeAll),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SupporterTile extends StatelessWidget {
  const _SupporterTile({
    required this.claim,
    required this.isSelf,
    required this.onConfirm,
    required this.onHide,
  });

  final SupportClaim claim;
  final bool isSelf;
  final VoidCallback onConfirm;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final photo = claim.supporterPhotoURL;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: claim.supporterId.isEmpty
          ? null
          : () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.publicProfile, arguments: claim.supporterId),
      leading: CircleAvatar(
        radius: 18,
        backgroundImage: photo != null && photo.isNotEmpty
            ? CachedNetworkImageProvider(photo)
            : null,
        child: photo != null && photo.isNotEmpty
            ? null
            : Text(claim.supporterName.characters.first.toUpperCase()),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              claim.supporterName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: claim.isVerified
                ? l10n.supporterVerified
                : l10n.supporterUnverified,
            child: Icon(
              claim.isVerified ? Icons.check_circle : Icons.schedule,
              size: 16,
              color: claim.isVerified
                  ? Colors.green
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      subtitle: isSelf && !claim.isVerified && claim.utr != null
          ? Text('UTR ${claim.utr}', style: theme.textTheme.bodySmall)
          : null,
      trailing: isSelf
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!claim.isVerified)
                  IconButton(
                    tooltip: l10n.supportConfirm,
                    icon: const Icon(Icons.check_circle_outline),
                    color: Colors.green,
                    onPressed: onConfirm,
                  ),
                IconButton(
                  tooltip: l10n.supportHide,
                  icon: const Icon(Icons.visibility_off_outlined),
                  onPressed: onHide,
                ),
              ],
            )
          : null,
    );
  }
}
