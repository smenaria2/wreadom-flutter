import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _bioController = TextEditingController();
  final _penNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  String _privacy = 'public';

  @override
  void dispose() {
    _bioController.dispose();
    _penNameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileSettings)),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.pleaseSignIn));
          }
          _bioController.text = _bioController.text.isEmpty
              ? user.bio ?? ''
              : _bioController.text;
          _penNameController.text = _penNameController.text.isEmpty
              ? user.penName ?? ''
              : _penNameController.text;
          _displayNameController.text = _displayNameController.text.isEmpty
              ? user.displayName ?? ''
              : _displayNameController.text;
          _privacy = user.privacyLevel ?? _privacy;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(labelText: l10n.displayName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _penNameController,
                decoration: InputDecoration(labelText: l10n.penName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioController,
                maxLines: 4,
                decoration: InputDecoration(labelText: l10n.bio),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _privacy,
                decoration: InputDecoration(labelText: l10n.privacy),
                items: [
                  DropdownMenuItem(value: 'public', child: Text(l10n.public)),
                  DropdownMenuItem(
                    value: 'followers',
                    child: Text(l10n.followersOnly),
                  ),
                  DropdownMenuItem(value: 'private', child: Text(l10n.private)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _privacy = value);
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(profileRepositoryProvider)
                      .updateProfileDetails(
                        userId: user.id,
                        bio: _bioController.text.trim(),
                        penName: _penNameController.text.trim(),
                        displayName: _displayNameController.text.trim(),
                      );
                  await ref
                      .read(profileRepositoryProvider)
                      .updatePrivacyLevel(user.id, _privacy);
                  ref.invalidate(currentUserProvider);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text(l10n.saveSettings),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.failedToLoadWithError(error.toString()))),
      ),
    );
  }
}
