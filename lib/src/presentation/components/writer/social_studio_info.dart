import 'package:flutter/material.dart';

import '../../../localization/generated/app_localizations.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/instagram_brand_icon.dart';

class SocialStudioInfo extends StatelessWidget {
  const SocialStudioInfo({super.key, required this.onOpenStudio});

  final VoidCallback onOpenStudio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassSurface(
            strong: true,
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(17),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.verified_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.socialStudioEligibilityTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        l10n.socialStudioEligibilityBody,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _SectionTitle(text: l10n.socialStudioWhatYouCanCreate),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 620;
              final width = twoColumns
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _CapabilityCard(
                    width: width,
                    icon: Icons.movie_creation_outlined,
                    title: l10n.socialStudioReelsTitle,
                    body: l10n.socialStudioReelsBody,
                  ),
                  _CapabilityCard(
                    width: width,
                    icon: Icons.view_carousel_outlined,
                    title: l10n.socialStudioCarouselTitle,
                    body: l10n.socialStudioCarouselBody,
                  ),
                  _CapabilityCard(
                    width: width,
                    icon: Icons.tag_rounded,
                    title: l10n.socialStudioCaptionTitle,
                    body: l10n.socialStudioCaptionBody,
                  ),
                  _CapabilityCard(
                    width: width,
                    icon: Icons.description_outlined,
                    title: l10n.socialStudioPrintTitle,
                    body: l10n.socialStudioPrintBody,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          _SectionTitle(text: l10n.socialStudioHowItWorks),
          const SizedBox(height: 12),
          GlassSurface(
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(17),
            child: Column(
              children: [
                _WorkflowStep(
                  number: 1,
                  title: l10n.socialStudioStep1Title,
                  body: l10n.socialStudioStep1Body,
                ),
                const _StepDivider(),
                _WorkflowStep(
                  number: 2,
                  title: l10n.socialStudioStep2Title,
                  body: l10n.socialStudioStep2Body,
                ),
                const _StepDivider(),
                _WorkflowStep(
                  number: 3,
                  title: l10n.socialStudioStep3Title,
                  body: l10n.socialStudioStep3Body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassSurface(
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(17),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InstagramBrandIcon(size: 42),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.socialStudioInstagramTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        l10n.socialStudioInstagramBody,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('open_social_studio_button'),
              onPressed: onOpenStudio,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(l10n.openSocialStudio),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.body,
  });

  final double width;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(
                  alpha: 0.72,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 21,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
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

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.number,
    required this.title,
    required this.body,
  });

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 7, 0, 7),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 2,
          height: 18,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
