import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:librebook_flutter/src/data/utils/firestore_utils.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';
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
  NotificationSettings? _notificationSettings;
  Map<String, bool> _notificationAppValues = const {};
  String? _populatedUserId;

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
          if (_populatedUserId != user.id) {
            _bioController.text = user.bio ?? '';
            _penNameController.text = user.penName ?? '';
            _displayNameController.text = user.displayName ?? '';
            _privacy = user.privacyLevel ?? 'public';
            _notificationSettings =
                user.notificationSettings ??
                NotificationSettings.fromJson(defaultNotificationSettingsMap());
            _notificationAppValues = _notificationAppValuesFromSettings(
              _notificationSettings!,
            );
            _populatedUserId = user.id;
          }
          final notificationSettings = _notificationSettings;

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
              if (notificationSettings != null) ...[
                Text(
                  l10n.notificationPreferences,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._notificationToggleSpecs(l10n).map((spec) {
                  return SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(spec.label),
                    value: _notificationAppValues[spec.key] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _notificationAppValues = {
                          ..._notificationAppValues,
                          spec.key: value,
                        };
                      });
                    },
                  );
                }),
                const SizedBox(height: 20),
              ],
              FilledButton(
                onPressed: () async {
                  final repository = ref.read(profileRepositoryProvider);
                  await repository.updateProfileDetails(
                    userId: user.id,
                    bio: _bioController.text.trim(),
                    penName: _blankToNull(_penNameController.text),
                    displayName: _blankToNull(_displayNameController.text),
                  );
                  await repository.updatePrivacyLevel(user.id, _privacy);
                  if (_notificationSettings != null) {
                    await repository.updateNotificationSettings(
                      user.id,
                      _settingsWithAppValues(
                        _notificationSettings!,
                        _notificationAppValues,
                      ),
                    );
                  }
                  ref.invalidate(currentUserProvider);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text(l10n.saveSettings),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(child: Text(l10n.failedToLoadProfileSettings));
        },
      ),
    );
  }
}

String? _blankToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, bool> _notificationAppValuesFromSettings(
  NotificationSettings settings,
) {
  return {
    'messages': settings.messages.app,
    'groupMessages': settings.groupMessages.app,
    'comments': settings.comments.app,
    'replies': settings.replies.app,
    'followers': settings.followers.app,
    'testimonials': settings.testimonials.app,
    'likes': settings.likes.app,
    'followedAuthorPosts': settings.followedAuthorPosts.app,
    'newCreations': settings.newCreations.app,
  };
}

NotificationSettings _settingsWithAppValues(
  NotificationSettings settings,
  Map<String, bool> appValues,
) {
  NotificationPreference withApp(String key, NotificationPreference value) {
    return value.copyWith(app: appValues[key] ?? value.app);
  }

  return settings.copyWith(
    messages: withApp('messages', settings.messages),
    groupMessages: withApp('groupMessages', settings.groupMessages),
    comments: withApp('comments', settings.comments),
    replies: withApp('replies', settings.replies),
    followers: withApp('followers', settings.followers),
    testimonials: withApp('testimonials', settings.testimonials),
    likes: withApp('likes', settings.likes),
    followedAuthorPosts: withApp(
      'followedAuthorPosts',
      settings.followedAuthorPosts,
    ),
    newCreations: withApp('newCreations', settings.newCreations),
  );
}

List<_NotificationToggleSpec> _notificationToggleSpecs(AppLocalizations l10n) {
  return [
    _NotificationToggleSpec('messages', l10n.notificationMessages),
    _NotificationToggleSpec('groupMessages', l10n.notificationGroupMessages),
    _NotificationToggleSpec('comments', l10n.notificationComments),
    _NotificationToggleSpec('replies', l10n.notificationReplies),
    _NotificationToggleSpec('followers', l10n.notificationFollowers),
    _NotificationToggleSpec('testimonials', l10n.notificationTestimonials),
    _NotificationToggleSpec('likes', l10n.notificationLikes),
    _NotificationToggleSpec(
      'followedAuthorPosts',
      l10n.notificationFollowedAuthorPosts,
    ),
    _NotificationToggleSpec('newCreations', l10n.notificationNewCreations),
  ];
}

class _NotificationToggleSpec {
  const _NotificationToggleSpec(this.key, this.label);

  final String key;
  final String label;
}
