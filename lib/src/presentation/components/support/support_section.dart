import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../domain/models/author_support.dart';
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
    final visible = SupportClaim.visibleSorted(
      effective,
      forAuthor: widget.isSelf,
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
      expanded: _expanded,
      onToggleExpanded: () => setState(() => _expanded = !_expanded),
    );
  }
}

// ---------------------------------------------------------------------------
// Reader view
// ---------------------------------------------------------------------------

class _ReaderPanel extends StatelessWidget {
  const _ReaderPanel({
    required this.authorId,
    required this.authorName,
    required this.support,
    required this.visible,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final String authorId;
  final String authorName;
  final AuthorSupport? support;
  final List<SupportClaim> visible;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shown = expanded
        ? visible
        : visible.take(_SupportSectionState._collapsedCount).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GlassSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (support != null)
              _SupportHero(
                title: l10n.supportAuthorTitle(authorName),
                subtitle: l10n.supportTagline,
                message: support!.message,
                action: FilledButton.icon(
                  onPressed: () => showSupportAuthorSheet(
                    context,
                    authorId: authorId,
                    authorName: authorName,
                    support: support!,
                  ),
                  icon: const Icon(Icons.favorite_rounded),
                  label: Text(l10n.supportAuthor),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            if (visible.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.volunteer_activism_outlined,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.supportersTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          l10n.supportersCount(visible.length),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (final claim in shown) _SupporterRow(claim: claim),
                    if (visible.length > _SupportSectionState._collapsedCount)
                      TextButton(
                        onPressed: onToggleExpanded,
                        child: Text(expanded ? l10n.showLess : l10n.seeAll),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Author view
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
    final shownConfirmed = expanded
        ? confirmed
        : confirmed.take(_SupportSectionState._collapsedCount).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GlassSurface(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.supportYourSupporters,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _CountChip(
                    icon: Icons.check_circle,
                    color: Colors.green,
                    label: l10n.supportConfirmedCount(confirmed.length),
                  ),
                  if (pending.isNotEmpty)
                    _CountChip(
                      icon: Icons.schedule,
                      color: scheme.tertiary,
                      label: l10n.supportPendingCount(pending.length),
                    ),
                ],
              ),
            ),
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
                  onSelected: (_) => onStatus(claim, SupportClaim.statusHidden),
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
                onPressed: onToggleExpanded,
                child: Text(expanded ? l10n.showLess : l10n.seeAll),
              ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GlassSurface(
        padding: EdgeInsets.zero,
        child: _SupportHero(
          title: l10n.supportSetupTitle,
          subtitle: l10n.supportSetupBody,
          action: FilledButton.tonalIcon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.profileSettings),
            icon: const Icon(Icons.tune_rounded),
            label: Text(l10n.supportSetupAction),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _SupportHero extends StatelessWidget {
  const _SupportHero({
    required this.title,
    required this.subtitle,
    required this.action,
    this.message,
  });

  final String title;
  final String subtitle;
  final String? message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.85),
            scheme.tertiaryContainer.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.14),
                ),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((message ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '“$message”',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
          const SizedBox(height: 14),
          action,
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
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
  const _SupporterRow({required this.claim, this.trailing});

  final SupportClaim claim;
  final Widget? trailing;

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
