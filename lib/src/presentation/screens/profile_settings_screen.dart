import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please sign in'));
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
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _penNameController,
                decoration: const InputDecoration(labelText: 'Pen name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _privacy,
                decoration: const InputDecoration(labelText: 'Privacy'),
                items: const [
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                  DropdownMenuItem(
                    value: 'followers',
                    child: Text('Followers only'),
                  ),
                  DropdownMenuItem(value: 'private', child: Text('Private')),
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
                child: const Text('Save Settings'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
      ),
    );
  }
}
