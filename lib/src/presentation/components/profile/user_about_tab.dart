import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../domain/models/user_model.dart';
import '../../routing/app_routes.dart';
import '../../widgets/instagram_profile_link.dart';
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
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.bio,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton.outlined(
              tooltip: l10n.editProfile,
              visualDensity: VisualDensity.compact,
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.profileSettings),
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
          ],
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
        if ((user.instagramHandle ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          InstagramProfileLink(handle: user.instagramHandle!),
        ],
        const SizedBox(height: 20),
        AuthorStatsPanel(user: user),
      ],
    );
  }
}
