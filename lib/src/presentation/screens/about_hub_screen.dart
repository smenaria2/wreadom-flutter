import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/routing/app_router.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';
import 'package:librebook_flutter/src/presentation/screens/attributions_screen.dart';
import 'package:librebook_flutter/src/presentation/widgets/app_background.dart';
import 'package:librebook_flutter/src/presentation/widgets/glass_surface.dart';

class AboutHubScreen extends StatelessWidget {
  const AboutHubScreen({super.key});

  void _openCreatorProfile(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.publicProfile,
      arguments: const PublicProfileArguments(
        userId: '3eOsWQIlW6c7XWCw8cnMIxed71R2',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutWreadomTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              children: [
                const SizedBox(height: 12),
                // Wreadom Logo Header
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        semanticLabel: l10n.appTitle,
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: theme.colorScheme.primary,
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    l10n.appTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Description Box & Creator Link
                GlassSurface(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        l10n.aboutDescription,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      InkWell(
                        key: const Key('about_creator_profile_link'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _openCreatorProfile(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.aboutCreatedBy,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Policy & Attributions Menu Items
                GlassSurface(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HubTile(
                        key: const Key('about_hub_row_terms_of_use'),
                        icon: Icons.description_outlined,
                        title: l10n.termsOfUse,
                        subtitle: 'Read terms of service',
                        onTap: () => AppRouter.openExternalPolicy(
                          context,
                          AppRoutes.terms,
                        ),
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      _HubTile(
                        key: const Key('about_hub_row_privacy_policy'),
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.privacyPolicy,
                        subtitle: 'Read privacy policy',
                        onTap: () => AppRouter.openExternalPolicy(
                          context,
                          AppRoutes.privacy,
                        ),
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      _HubTile(
                        key: const Key('about_hub_row_attributions'),
                        icon: Icons.favorite_border_rounded,
                        title: l10n.attributionsTitle,
                        subtitle: 'Third-party tools & licenses',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AttributionsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
