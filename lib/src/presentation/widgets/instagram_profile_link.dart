import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../localization/generated/app_localizations.dart';
import '../../utils/instagram_profile_utils.dart';

class InstagramProfileLink extends StatelessWidget {
  const InstagramProfileLink({super.key, required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      key: const Key('instagram_profile_link'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.camera_alt_outlined),
      title: Text(l10n.instagram),
      subtitle: Text('@$handle'),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      onTap: () => _openProfile(context),
    );
  }

  Future<void> _openProfile(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(instagramProfileUrl(handle)),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.couldNotOpenInstagram),
        ),
      );
    }
  }
}
