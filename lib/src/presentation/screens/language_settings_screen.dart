import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeControllerProvider);

    return GlassScaffold(
      appBar: glassAppBar(title: Text(l10n.language)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LanguageTile(
            title: l10n.english,
            subtitle: 'English',
            isSelected: currentLocale.languageCode == 'en',
            onTap: () => ref
                .read(localeControllerProvider.notifier)
                .setLocale(const Locale('en')),
          ),
          const SizedBox(height: 12),
          _LanguageTile(
            title: l10n.hindi,
            subtitle: 'हिंदी',
            isSelected: currentLocale.languageCode == 'hi',
            onTap: () => ref
                .read(localeControllerProvider.notifier)
                .setLocale(const Locale('hi')),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassSurface(
      strong: isSelected,
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      semanticButton: true,
      child: ListTile(
        leading: Icon(
          Icons.translate_rounded,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
            : null,
      ),
    );
  }
}
