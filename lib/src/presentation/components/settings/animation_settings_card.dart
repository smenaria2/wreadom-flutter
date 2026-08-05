import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/animation_settings_provider.dart';

class AnimationSettingsCard extends ConsumerWidget {
  const AnimationSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disableAnimations = ref.watch(disableAnimationsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Performance & Animations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disable Animations (Low Power Mode)'),
              subtitle: const Text(
                'Reduces transitions, effects, and animations for older or low-power devices.',
              ),
              trailing: Switch.adaptive(
                value: disableAnimations,
                onChanged: (value) {
                  ref.read(disableAnimationsProvider.notifier).setDisabled(value);
                },
              ),
              onTap: () {
                ref
                    .read(disableAnimationsProvider.notifier)
                    .setDisabled(!disableAnimations);
              },
            ),
          ],
        ),
      ),
    );
  }
}
