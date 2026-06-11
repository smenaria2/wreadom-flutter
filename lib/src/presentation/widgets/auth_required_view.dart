import 'package:flutter/material.dart';

import '../../localization/generated/app_localizations.dart';
import '../routing/app_routes.dart';
import 'glass_surface.dart';

class AuthRequiredView extends StatelessWidget {
  const AuthRequiredView({
    super.key,
    this.icon = Icons.lock_outline_rounded,
    this.padding = const EdgeInsets.all(24),
  });

  final IconData icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: padding,
        child: GlassSurface(
          strong: true,
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.signInToContinueAction,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.login),
                icon: const Icon(Icons.login_rounded),
                label: Text(l10n.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
