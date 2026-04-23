import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../providers/locale_provider.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
      ),
      body: ListView(
        children: [
          _LanguageTile(
            title: l10n.english,
            subtitle: 'English',
            isSelected: currentLocale.languageCode == 'en',
            onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('en')),
          ),
          _LanguageTile(
            title: l10n.hindi,
            subtitle: 'हिंदी',
            isSelected: currentLocale.languageCode == 'hi',
            onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('hi')),
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
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}
