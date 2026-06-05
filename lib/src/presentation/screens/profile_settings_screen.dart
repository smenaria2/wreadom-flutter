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
                _NotificationPreferencesSection(
                  specs: _notificationToggleSpecs(l10n),
                  values: _notificationAppValues,
                  onChanged: (key, value) {
                    setState(() {
                      _notificationAppValues = {
                        ..._notificationAppValues,
                        key: value,
                      };
                    });
                  },
                ),
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
    _NotificationToggleSpec(
      'messages',
      l10n.notificationMessages,
      Icons.mail_outline_rounded,
      _NotificationPreferenceGroup.conversations,
    ),
    _NotificationToggleSpec(
      'groupMessages',
      l10n.notificationGroupMessages,
      Icons.groups_2_outlined,
      _NotificationPreferenceGroup.conversations,
    ),
    _NotificationToggleSpec(
      'comments',
      l10n.notificationComments,
      Icons.rate_review_outlined,
      _NotificationPreferenceGroup.responses,
    ),
    _NotificationToggleSpec(
      'replies',
      l10n.notificationReplies,
      Icons.forum_outlined,
      _NotificationPreferenceGroup.responses,
    ),
    _NotificationToggleSpec(
      'followers',
      l10n.notificationFollowers,
      Icons.person_add_alt_1_outlined,
      _NotificationPreferenceGroup.community,
    ),
    _NotificationToggleSpec(
      'testimonials',
      l10n.notificationTestimonials,
      Icons.workspace_premium_outlined,
      _NotificationPreferenceGroup.community,
    ),
    _NotificationToggleSpec(
      'likes',
      l10n.notificationLikes,
      Icons.favorite_border_rounded,
      _NotificationPreferenceGroup.community,
    ),
    _NotificationToggleSpec(
      'followedAuthorPosts',
      l10n.notificationFollowedAuthorPosts,
      Icons.dynamic_feed_outlined,
      _NotificationPreferenceGroup.creations,
    ),
    _NotificationToggleSpec(
      'newCreations',
      l10n.notificationNewCreations,
      Icons.auto_stories_outlined,
      _NotificationPreferenceGroup.creations,
    ),
  ];
}

class _NotificationToggleSpec {
  const _NotificationToggleSpec(this.key, this.label, this.icon, this.group);

  final String key;
  final String label;
  final IconData icon;
  final _NotificationPreferenceGroup group;
}

enum _NotificationPreferenceGroup {
  conversations,
  responses,
  community,
  creations,
}

class _NotificationPreferencesSection extends StatefulWidget {
  const _NotificationPreferencesSection({
    required this.specs,
    required this.values,
    required this.onChanged,
  });

  final List<_NotificationToggleSpec> specs;
  final Map<String, bool> values;
  final void Function(String key, bool value) onChanged;

  @override
  State<_NotificationPreferencesSection> createState() =>
      _NotificationPreferencesSectionState();
}

class _NotificationPreferencesSectionState
    extends State<_NotificationPreferencesSection> {
  var _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final enabledCount = widget.specs
        .where((spec) => widget.values[spec.key] ?? true)
        .length;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        leading: Icon(
          _isExpanded
              ? Icons.notifications_active_rounded
              : Icons.notifications_active_outlined,
          color: colorScheme.primary,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                l10n.notificationPreferences,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  '$enabledCount/${widget.specs.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        children: [
          for (var i = 0; i < widget.specs.length; i++) ...[
            if (i == 0 || widget.specs[i].group != widget.specs[i - 1].group)
              _NotificationGroupLabel(
                label: _groupLabel(l10n, widget.specs[i].group),
              ),
            _NotificationPreferenceRow(
              spec: widget.specs[i],
              value: widget.values[widget.specs[i].key] ?? true,
              onChanged: (value) =>
                  widget.onChanged(widget.specs[i].key, value),
            ),
            if (i != widget.specs.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
          ],
        ],
      ),
    );
  }

  String _groupLabel(
    AppLocalizations l10n,
    _NotificationPreferenceGroup group,
  ) {
    return switch (group) {
      _NotificationPreferenceGroup.conversations =>
        l10n.notificationGroupConversations,
      _NotificationPreferenceGroup.responses => l10n.notificationGroupResponses,
      _NotificationPreferenceGroup.community => l10n.notificationGroupCommunity,
      _NotificationPreferenceGroup.creations => l10n.notificationGroupCreations,
    };
  }
}

class _NotificationGroupLabel extends StatelessWidget {
  const _NotificationGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _NotificationPreferenceRow extends StatelessWidget {
  const _NotificationPreferenceRow({
    required this.spec,
    required this.value,
    required this.onChanged,
  });

  final _NotificationToggleSpec spec;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      minLeadingWidth: 32,
      leading: DecoratedBox(
        decoration: BoxDecoration(
          color: value
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox.square(
          dimension: 36,
          child: Icon(
            spec.icon,
            size: 20,
            color: value
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      title: Text(
        spec.label,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}
