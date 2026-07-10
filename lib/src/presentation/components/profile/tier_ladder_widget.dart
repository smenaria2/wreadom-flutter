import 'package:flutter/material.dart';
import '../../../utils/tier_utils.dart';
import '../../../localization/generated/app_localizations.dart';
import '../../widgets/glass_surface.dart';
import '../../theme/app_theme.dart';

class TierLadderWidget extends StatefulWidget {
  final int readerPoints;
  final int authorPoints;

  const TierLadderWidget({
    super.key,
    required this.readerPoints,
    required this.authorPoints,
  });

  @override
  State<TierLadderWidget> createState() => _TierLadderWidgetState();
}

class _TierLadderWidgetState extends State<TierLadderWidget> {
  String _activeTrack = 'author'; // Default to author / writer track
  int _selectedTierIndex = 0;

  final List<Map<String, dynamic>> _tierDefs = [
    {'tier': 1, 'range': '0 - 499', 'icon': '🌱'},
    {'tier': 2, 'range': '500 - 4.9K', 'icon': '📚'},
    {'tier': 3, 'range': '5K - 24.9K', 'icon': '⭐'},
    {'tier': 4, 'range': '25K - 49.9K', 'icon': '🔥'},
    {'tier': 5, 'range': '50K - 99.9K', 'icon': '💎'},
    {'tier': 6, 'range': '100K - 499.9K', 'icon': '👑'},
    {'tier': 7, 'range': '500K - 999.9K', 'icon': '🌟'},
    {'tier': 8, 'range': '1M+', 'icon': '✨'},
  ];

  @override
  void initState() {
    super.initState();
    _updateSelectedTier();
  }

  void _updateSelectedTier() {
    final points = _activeTrack == 'author' ? widget.authorPoints : widget.readerPoints;
    final currentTierInfo = getTierInfo(points, _activeTrack);
    setState(() {
      _selectedTierIndex = (currentTierInfo.tier - 1).clamp(0, 7);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final tokens = theme.extension<GlassTokens>() ?? GlassTokens.light;

    final userPoints = _activeTrack == 'author' ? widget.authorPoints : widget.readerPoints;
    final userTierInfo = getTierInfo(userPoints, _activeTrack);
    final userTierIdx = userTierInfo.tier - 1;

    final selectedTierNum = _selectedTierIndex + 1;
    final selectedTierTitle = getLocalizedTierTitle(context, selectedTierNum, _activeTrack);
    final selectedTierDef = _tierDefs[_selectedTierIndex];
    final selectedTierInfo = getTierInfo(
      _activeTrack == 'author'
          ? (selectedTierNum == 1 ? 0 : selectedTierNum == 2 ? 500 : selectedTierNum == 3 ? 5000 : selectedTierNum == 4 ? 25000 : selectedTierNum == 5 ? 50000 : selectedTierNum == 6 ? 100000 : selectedTierNum == 7 ? 500000 : 1000000)
          : (selectedTierNum == 1 ? 0 : selectedTierNum == 2 ? 500 : selectedTierNum == 3 ? 5000 : selectedTierNum == 4 ? 25000 : selectedTierNum == 5 ? 50000 : selectedTierNum == 6 ? 100000 : selectedTierNum == 7 ? 500000 : 1000000),
      _activeTrack,
    );

    return Column(
      children: [
        // Track switcher
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: tokens.borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TrackTab(
                  label: l10n.authors,
                  icon: Icons.history_edu_rounded,
                  isActive: _activeTrack == 'author',
                  onTap: () {
                    setState(() {
                      _activeTrack = 'author';
                      _updateSelectedTier();
                    });
                  },
                ),
              ),
              Expanded(
                child: _TrackTab(
                  label: l10n.readers,
                  icon: Icons.menu_book_rounded,
                  isActive: _activeTrack == 'reader',
                  onTap: () {
                    setState(() {
                      _activeTrack = 'reader';
                      _updateSelectedTier();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Visual interactive ladder chart
        Column(
          children: List.generate(_tierDefs.length, (index) {
            final def = _tierDefs[index];
            final isCurrent = index == userTierIdx;
            final isSelected = index == _selectedTierIndex;
            final tierNum = index + 1;
            final title = getLocalizedTierTitle(context, tierNum, _activeTrack);
            final stepTierInfo = getTierInfo(
              tierNum == 1 ? 0 : tierNum == 2 ? 500 : tierNum == 3 ? 5000 : tierNum == 4 ? 25000 : tierNum == 5 ? 50000 : tierNum == 6 ? 100000 : tierNum == 7 ? 500000 : 1000000,
              _activeTrack,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: Timeline step graphics (node + vertical line segments)
                  SizedBox(
                    width: 50,
                    height: 64, // Fixed height to keep it clean and compact
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Vertical line segments
                        Positioned(
                          top: index == 0 ? 32 : 0,
                          bottom: index == 7 ? 32 : 0,
                          child: Container(
                            width: 4,
                            color: scheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        // Glowing line segment for completed/active path
                        if (index < userTierIdx)
                          Positioned(
                            top: index == 0 ? 32 : 0,
                            bottom: 0,
                            child: Container(
                              width: 4,
                              color: scheme.primary.withValues(alpha: 0.6),
                            ),
                          ),
                        if (index == userTierIdx && index > 0)
                          Positioned(
                            top: 0,
                            bottom: 32,
                            child: Container(
                              width: 4,
                              color: scheme.primary.withValues(alpha: 0.6),
                            ),
                          ),

                        // Circle node
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTierIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isSelected ? stepTierInfo.gradient : null,
                              color: isSelected
                                  ? null
                                  : isCurrent
                                      ? scheme.primary.withValues(alpha: 0.2)
                                      : scheme.surfaceContainerHigh,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : isCurrent
                                        ? scheme.primary
                                        : scheme.outlineVariant,
                                width: isSelected || isCurrent ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: stepTierInfo.gradient.colors.first.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                def['icon'] as String,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Right: Interactive card details
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTierIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.primaryContainer.withValues(alpha: 0.25)
                              : isCurrent
                                  ? scheme.secondaryContainer.withValues(alpha: 0.15)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? scheme.primary.withValues(alpha: 0.3)
                                : isCurrent
                                    ? scheme.secondary.withValues(alpha: 0.2)
                                    : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Tier $tierNum',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: isSelected
                                              ? scheme.primary
                                              : scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: scheme.primary,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            l10n.you.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected || isCurrent ? FontWeight.bold : FontWeight.normal,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              def['range'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // Selected Tier Details Panel
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: GlassSurface(
            key: ValueKey('detail_card_${_activeTrack}_$_selectedTierIndex'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: tokens.borderColor),
                gradient: LinearGradient(
                  colors: [
                    selectedTierInfo.gradient.colors.first.withValues(alpha: 0.1),
                    selectedTierInfo.gradient.colors.last.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(selectedTierDef['icon'] as String, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tier $selectedTierNum: $selectedTierTitle',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                            Text(
                              '${selectedTierDef['range']} PTS REQUIRED',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedTierIndex == userTierIdx) ...[
                    Text(
                      'You are currently at this tier!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (userTierInfo.pointsToNext != null)
                      Text(
                        l10n.ptsToNextTier(userTierInfo.pointsToNext!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Text(
                        l10n.maxLevelReached,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ] else if (_selectedTierIndex < userTierIdx)
                    Text(
                      'Completed tier. You have passed this rank!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      'Locked tier. Keep earning points to unlock this rank!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TrackTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? scheme.primaryContainer.withValues(alpha: 0.85) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(color: scheme.primary.withValues(alpha: 0.24))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
