import 'package:flutter/material.dart';

import '../../../localization/generated/app_localizations.dart';
import '../../../utils/tier_utils.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_surface.dart';

class TierLadderWidget extends StatefulWidget {
  const TierLadderWidget({
    super.key,
    required this.readerPoints,
    required this.authorPoints,
    this.initialTrack = RankTrack.author,
  });

  final int readerPoints;
  final int authorPoints;
  final RankTrack initialTrack;

  @override
  State<TierLadderWidget> createState() => _TierLadderWidgetState();
}

class _TierLadderWidgetState extends State<TierLadderWidget> {
  late RankTrack _activeTrack;
  late int _selectedTierIndex;

  int get _points => _activeTrack == RankTrack.author
      ? widget.authorPoints
      : widget.readerPoints;

  @override
  void initState() {
    super.initState();
    _activeTrack = widget.initialTrack;
    _selectedTierIndex = tierInfoFor(_points, _activeTrack).tier - 1;
  }

  void _selectTrack(RankTrack track) {
    if (track == _activeTrack) return;
    setState(() {
      _activeTrack = track;
      _selectedTierIndex = tierInfoFor(_points, track).tier - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final info = tierInfoFor(_points, _activeTrack);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TrackSwitcher(active: _activeTrack, onChanged: _selectTrack),
        const SizedBox(height: 16),
        GlassSurface(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  info.gradient.colors.first.withValues(alpha: 0.16),
                  info.gradient.colors.last.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(info.icon, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.tierLabel} ${info.tier} · ${localizedTierTitle(context, info.tier, _activeTrack)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${formatRankPoints(context, info.points)} ${l10n.pointsLabel}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${info.progressPercent.round()}%',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: info.progressPercent / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.65,
                  ),
                  valueColor: AlwaysStoppedAnimation(
                    info.gradient.colors.first,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  info.pointsToNext == null
                      ? l10n.maxLevelReached
                      : l10n.ptsToNextTier(info.pointsToNext!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(tierDefinitions.length, (index) {
          final definition = tierDefinitions[index];
          final currentIndex = info.tier - 1;
          final selected = index == _selectedTierIndex;
          final current = index == currentIndex;
          final complete = index < currentIndex;
          final title = localizedTierTitle(
            context,
            definition.tier,
            _activeTrack,
          );
          final gradient = definition.gradientFor(_activeTrack);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              selected: selected,
              button: true,
              label:
                  '${l10n.tierLabel} ${definition.tier}, $title, ${tierRangeLabel(context, definition)}',
              child: InkWell(
                onTap: () => setState(() => _selectedTierIndex = index),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: selected ? 14 : 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: selected
                        ? gradient.colors.first.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: current
                          ? scheme.primary
                          : selected
                          ? gradient.colors.first.withValues(alpha: 0.45)
                          : scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: selected ? gradient : null,
                          color: selected
                              ? null
                              : scheme.surfaceContainerHighest,
                        ),
                        child: Text(
                          definition.iconFor(_activeTrack),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${l10n.tierLabel} ${definition.tier} · $title',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (current)
                                  _StatusChip(label: l10n.you)
                                else if (complete)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                    color: scheme.tertiary,
                                  )
                                else
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 17,
                                    color: scheme.onSurfaceVariant,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tierRangeLabel(context, definition),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(height: 8),
                              Text(
                                current
                                    ? l10n.currentTierMessage
                                    : complete
                                    ? l10n.completedTierMessage
                                    : l10n.lockedTierMessage,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: current
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TrackSwitcher extends StatelessWidget {
  const _TrackSwitcher({required this.active, required this.onChanged});

  final RankTrack active;
  final ValueChanged<RankTrack> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens =
        Theme.of(context).extension<GlassTokens>() ?? GlassTokens.light;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.borderColor),
      ),
      child: SegmentedButton<RankTrack>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: RankTrack.author,
            icon: const Icon(Icons.history_edu_rounded),
            label: Text(l10n.authors),
          ),
          ButtonSegment(
            value: RankTrack.reader,
            icon: const Icon(Icons.menu_book_rounded),
            label: Text(l10n.readers),
          ),
        ],
        selected: {active},
        onSelectionChanged: (value) => onChanged(value.first),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
