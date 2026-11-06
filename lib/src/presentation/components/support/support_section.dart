import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../domain/models/author_support.dart';
import '../../providers/auth_providers.dart';
import '../../providers/support_providers.dart';
import '../../routing/app_routes.dart';
import '../../widgets/glass_surface.dart';
import 'support_author_sheet.dart';

/// The whole "support the author" area of a profile.
///
/// Readers see a themed call-to-action plus the supporters list. The author
/// sees their supporters with clear Received / Not received controls for
/// payments that still need confirming.
class SupportSection extends ConsumerStatefulWidget {
  const SupportSection({
    super.key,
    required this.authorId,
    required this.authorName,
    required this.isSelf,
  });

  final String authorId;
  final String authorName;
  final bool isSelf;

  @override
  ConsumerState<SupportSection> createState() => _SupportSectionState();
}

class _SupportSectionState extends ConsumerState<SupportSection> {
  static const _collapsedCount = 5;

  /// Optimistic status changes so the UI reacts instantly.
  final Map<String, String> _overrides = {};
  bool _expanded = false;

  Future<void> _setStatus(
    SupportClaim claim,
    String status, {
    bool offerUndo = true,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final previous = claim.status;
    setState(() => _overrides[claim.id] = status);
    try {
      await ref.read(supportRepositoryProvider).setClaimStatus(claim, status);
      ref.invalidate(supportClaimsProvider(widget.authorId));
      if (!offerUndo) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              status == SupportClaim.statusVerified
                  ? l10n.supportConfirmed
                  : l10n.supportMarkedNotReceived,
            ),
            action: SnackBarAction(
              label: l10n.supportUndo,
              onPressed: () =>
                  _setStatus(claim.withStatus(status), previous, offerUndo: false),
            ),
          ),
        );
    } catch (error) {
      if (mounted) setState(() => _overrides.remove(claim.id));
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.supportActionFailed(_shortError(error)))),
      );
    }
  }

  String _shortError(Object error) {
    final text = error.toString();
    final match = RegExp(r'\[[^\]]+\]').firstMatch(text);
    return match?.group(0) ?? text;
  }

  @override
  Widget build(BuildContext context) {
    final support = ref.watch(authorSupportProvider(widget.authorId)).value;
    final claims = ref.watch(supportClaimsProvider(widget.authorId)).value;
    final active = support?.isActive ?? false;

    final effective = (claims ?? const <SupportClaim>[])
        .map(
          (claim) => _overrides.containsKey(claim.id)
              ? claim.withStatus(_overrides[claim.id]!)
              : claim,
        )
        .toList();
    final viewerId = ref.watch(currentUserProvider).value?.id;
    final visible = SupportClaim.visibleSorted(
      effective,
      forAuthor: widget.isSelf,
      viewerId: viewerId,
    );

    if (widget.isSelf) {
      if (!active && visible.isEmpty) return const _SetupCard();
      return _AuthorPanel(
        visible: visible,
        onStatus: _setStatus,
        expanded: _expanded,
        onToggleExpanded: () => setState(() => _expanded = !_expanded),
      );
    }

    if (!active && visible.isEmpty) return const SizedBox.shrink();
    return _ReaderPanel(
      authorId: widget.authorId,
      authorName: widget.authorName,
      support: active ? support : null,
      visible: visible,
    );
  }
}


// ---------------------------------------------------------------------------
// Reader view: one compact strip so the profile content stays near the top.
// ---------------------------------------------------------------------------

class _ReaderPanel extends StatelessWidget {
  const _ReaderPanel({
    required this.authorId,
    required this.authorName,
    required this.support,
    required this.visible,
  });

  final String authorId;
  final String authorName;
  final AuthorSupport? support;
  final List<SupportClaim> visible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlassSurface(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (support != null)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.supportStripTitle(authorName),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => showSupportAuthorSheet(
                      context,
                      authorId: authorId,
                      authorName: authorName,
                      support: support!,
                    ),
                    icon: const Icon(Icons.favorite_rounded, size: 18),
                    label: Text(l10n.supportAuthor),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ],
              ),
            if (visible.isNotEmpty)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showSupportersSheet(context, visible),
                child: Padding(
                  padding: EdgeInsets.only(top: support != null ? 10 : 0),
                  child: Row(
                    children: [
                      _AvatarStack(claims: visible),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.supportersCount(visible.length),
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showSupportersSheet(
  BuildContext context,
  List<SupportClaim> claims,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      final theme = Theme.of(sheetContext);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.supportersTitle} · ${l10n.supportersCount(claims.length)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
            for (final claim in claims)
              _SupporterRow(claim: claim, privateToViewer: !claim.isVerified),
          ],
        ),
      );
    },
  );
}

/// Up to three overlapping avatars.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.claims});

  final List<SupportClaim> claims;

  @override
  Widget build(BuildContext context) {
    final shown = claims.take(3).toList();
    const radius = 12.0;
    const step = 16.0;
    return SizedBox(
      width: radius * 2 + 3 + step * (shown.length - 1),
      height: radius * 2 + 3,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: CircleAvatar(
                radius: radius + 1.5,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: _Avatar(claim: shown[i], radius: radius),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Author view: collapsed summary row, expands to the confirm controls.
// ---------------------------------------------------------------------------

class _AuthorPanel extends StatelessWidget {
  const _AuthorPanel({
    required this.visible,
    required this.onStatus,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final List<SupportClaim> visible;
  final Future<void> Function(SupportClaim claim, String status) onStatus;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pending = visible.where((c) => !c.isVerified).toList();
    final confirmed = visible.where((c) => c.isVerified).toList();
    final shownConfirmed = confirmed
        .take(_SupportSectionState._collapsedCount)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlassSurface(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onToggleExpanded,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.supportYourSupporters,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            [
                              l10n.supportConfirmedCount(confirmed.length),
                              if (pending.isNotEmpty)
                                l10n.supportPendingCount(pending.length),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pending.isNotEmpty)
                      Badge(
                        label: Text('${pending.length}'),
                        backgroundColor: scheme.tertiary,
                        textColor: scheme.onTertiary,
                      ),
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                    IconButton(
                      tooltip: l10n.supportSettingsTitle,
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.profileSettings),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              if (pending.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 4, top: 4),
                  child: Text(
                    l10n.supportPendingTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final claim in pending)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: _PendingCard(claim: claim, onStatus: onStatus),
                  ),
              ],
              for (final claim in shownConfirmed)
                _SupporterRow(
                  claim: claim,
                  trailing: PopupMenuButton<String>(
                    tooltip: l10n.supportRemoveFromList,
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (_) =>
                        onStatus(claim, SupportClaim.statusHidden),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(l10n.supportRemoveFromList),
                      ),
                    ],
                  ),
                ),
              if (confirmed.length > _SupportSectionState._collapsedCount)
                TextButton(
                  onPressed: () => _showSupportersSheet(context, confirmed),
                  child: Text(l10n.supportMoreSupporters),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.claim, required this.onStatus});

  final SupportClaim claim;
  final Future<void> Function(SupportClaim claim, String status) onStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final details = <String>[
      if (claim.amount != null) '₹${claim.amount}',
      if (claim.utr != null) 'UTR ${claim.utr}',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(claim: claim, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.supporterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      details.isEmpty
                          ? l10n.supportSaysPaid
                          : '${l10n.supportSaysPaid} · ${details.join(' · ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onStatus(claim, SupportClaim.statusHidden),
                  child: Text(l10n.supportNotReceived),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onStatus(claim, SupportClaim.statusVerified),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(l10n.supportReceived),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _SetupCard extends StatelessWidget {
  const _SetupCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlassSurface(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Icon(Icons.volunteer_activism_rounded, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.supportSetupTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.supportSetupBody,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.profileSettings),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: Text(l10n.supportSetupAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.claim, this.radius = 16});

  final SupportClaim claim;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photo = claim.supporterPhotoURL;
    final hasPhoto = photo != null && photo.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundImage: hasPhoto ? CachedNetworkImageProvider(photo) : null,
      child: hasPhoto
          ? null
          : Text(claim.supporterName.characters.first.toUpperCase()),
    );
  }
}

class _SupporterRow extends StatelessWidget {
  const _SupporterRow({
    required this.claim,
    this.trailing,
    this.privateToViewer = false,
  });

  final SupportClaim claim;
  final Widget? trailing;

  /// True for the viewer's own unconfirmed claim (only they can see it).
  final bool privateToViewer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: claim.supporterId.isEmpty
          ? null
          : () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.publicProfile, arguments: claim.supporterId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _Avatar(claim: claim),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                claim.supporterName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: claim.isVerified
                      ? null
                      : scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            if (!claim.isVerified && privateToViewer)
              IconButton(
                tooltip: l10n.supportOnlyYouInfo,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
                onPressed: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(l10n.supportOnlyYouInfo)),
                  ),
              )
            else
              Tooltip(
                message: claim.isVerified
                    ? l10n.supporterVerified
                    : l10n.supporterUnverified,
                child: Icon(
                  claim.isVerified ? Icons.check_circle : Icons.schedule,
                  size: 18,
                  color: claim.isVerified
                      ? Colors.green
                      : scheme.onSurfaceVariant,
                ),
              ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
