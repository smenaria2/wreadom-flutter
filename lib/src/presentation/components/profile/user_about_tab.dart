import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../domain/models/user_model.dart';
import 'author_stats_panel.dart';

class UserAboutTab extends StatelessWidget {
  const UserAboutTab({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        Text(
          l10n.bio,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          user.bio ?? l10n.noBioYet,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        AuthorStatsPanel(user: user),
      ],
    );
  }
}
