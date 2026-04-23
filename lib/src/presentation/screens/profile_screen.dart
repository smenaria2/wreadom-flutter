import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../domain/models/user_model.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_controller.dart';
import '../providers/book_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/notification_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/report_providers.dart';
import '../providers/theme_provider.dart';
import '../providers/writer_providers.dart';
import '../../utils/format_utils.dart';
import '../../utils/app_log_collector.dart';
import '../routing/app_routes.dart';
import '../components/profile/user_posts_tab.dart';
import '../components/profile/user_about_tab.dart';
import '../components/profile/user_history_tab.dart';
import '../components/profile/user_saved_tab.dart';
import '../components/profile/profile_share_card.dart';
import 'follow_list_screen.dart';
import '../../utils/app_link_helper.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(body: Center(child: Text(l10n.login)));
        }
        final worksCount = ref
            .watch(userBooksProvider(user.id))
            .maybeWhen(
              data: (books) => books.length,
              orElse: () => user.pinnedWorks?.length ?? 0,
            );

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            endDrawer: const _ProfileSideMenu(),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // ─── Collapsible profile header ──────────────────
                  SliverAppBar(
                    expandedHeight: 240,
                    pinned: true,
                    stretch: true,
                    elevation: 0,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    iconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      title: AnimatedOpacity(
                        opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          user.displayName ?? user.username,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      background: _ProfileHeader(user: user),
                    ),
                    actions: [
                      IconButton(
                        tooltip: l10n.shareProfile,
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () =>
                            _shareProfile(context, user, worksCount),
                      ),
                      _NotificationAction(),
                      Builder(
                        builder: (context) => IconButton(
                          tooltip: l10n.menu,
                          icon: const Icon(Icons.menu_rounded),
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                        ),
                      ),
                    ],
                  ),

                  // ─── Stats & Summary ───────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: l10n.followers,
                            value: FormatUtils.formatNumber(
                              user.followersCount ?? 0,
                            ),
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.followList,
                              arguments: FollowListArguments(
                                userId: user.id,
                                mode: FollowListMode.followers,
                                title: l10n.followers,
                              ),
                            ),
                          ),
                          _StatItem(
                            label: l10n.following,
                            value: FormatUtils.formatNumber(
                              user.followingCount ?? 0,
                            ),
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.followList,
                              arguments: FollowListArguments(
                                userId: user.id,
                                mode: FollowListMode.following,
                                title: l10n.following,
                              ),
                            ),
                          ),
                          _StatItem(
                            label: l10n.works,
                            value: FormatUtils.formatNumber(worksCount),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Tab Bar ───────────────────────────────────
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: [
                          Tab(text: l10n.about),
                          Tab(text: l10n.posts),
                          Tab(text: l10n.history),
                          Tab(text: l10n.saved),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  UserAboutTab(user: user),
                  UserPostsTab(userId: user.id),
                  const UserHistoryTab(),
                  const UserSavedTab(),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        body: Center(
          child: Text(l10n.failedToLoadTitle(l10n.profile, err.toString())),
        ),
      ),
    );
  }

  void _shareProfile(BuildContext context, UserModel user, int worksCount) {
    final name = user.displayName ?? user.username;
    shareUserProfileCard(
      context,
      user: user,
      worksCount: worksCount,
      fallbackText: AppLocalizations.of(
        context,
      )!.readWithUserOnWreadom(name, AppLinkHelper.user(user.id)),
    );
  }
}

class _NotificationAction extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    final l10n = AppLocalizations.of(context)!;
    final btn = IconButton(
      tooltip: l10n.notifications,
      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
      icon: const Icon(Icons.notifications_none_rounded),
    );
    if (unread <= 0) return btn;
    return Badge(label: Text(unread > 99 ? '99+' : '$unread'), child: btn);
  }
}

class _ProfileHeader extends ConsumerStatefulWidget {
  const _ProfileHeader({required this.user});

  final UserModel user;

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  final ImagePicker _picker = ImagePicker();
  bool _uploadingAvatar = false;
  bool _uploadingCover = false;

  Future<void> _changeProfilePicture() async {
    await _pickAndUpload(isCover: false);
  }

  Future<void> _changeCoverPicture() async {
    await _pickAndUpload(isCover: true);
  }

  Future<void> _pickAndUpload({required bool isCover}) async {
    final l10n = AppLocalizations.of(context)!;
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: isCover ? 1800 : 900,
      imageQuality: 86,
    );
    if (file == null) return;

    setState(() {
      if (isCover) {
        _uploadingCover = true;
      } else {
        _uploadingAvatar = true;
      }
    });

    try {
      final url = await ref
          .read(cloudinaryUploadServiceProvider)
          .uploadImage(
            file: file,
            folder: isCover ? 'profile_covers' : 'profile_photos',
            userId: widget.user.id,
          );
      if (isCover) {
        await ref
            .read(profileRepositoryProvider)
            .updateCoverPhoto(widget.user.id, url);
      } else {
        await ref
            .read(authRepositoryProvider)
            .updateUserProfile(widget.user.id, photoURL: url);
      }
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCover ? l10n.coverPictureUpdated : l10n.profilePictureUpdated,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotUpdatePicture(error.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (isCover) {
            _uploadingCover = false;
          } else {
            _uploadingAvatar = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final user = widget.user;
    final coverUrl = user.coverPhotoURL;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;
    final displayName = user.displayName ?? user.username;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasCover)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover),
          )
        else
          ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
          ),
        if (hasCover)
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.62),
            ),
          ),
        Positioned(
          right: 16,
          top: MediaQuery.of(context).padding.top + 12,
          child: IconButton.filledTonal(
            tooltip: l10n.changeCoverPicture,
            onPressed: _uploadingCover ? null : _changeCoverPicture,
            icon: _uploadingCover
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_camera_outlined),
          ),
        ),
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: theme.colorScheme.surface,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      backgroundImage: user.photoURL != null
                          ? CachedNetworkImageProvider(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? Text(
                              displayName.characters.first.toUpperCase(),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: -8,
                    bottom: -4,
                    child: IconButton.filled(
                      tooltip: l10n.changeProfilePicture,
                      onPressed: _uploadingAvatar
                          ? null
                          : _changeProfilePicture,
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: _uploadingAvatar
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_camera_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                displayName,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: hasCover
                      ? [
                          Shadow(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.8,
                            ),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileSideMenu extends ConsumerWidget {
  const _ProfileSideMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(appThemeControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeControllerProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Wreadom',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _MenuTile(
                    icon: Icons.manage_accounts_outlined,
                    title: l10n.editProfile,
                    onTap: () => _go(context, AppRoutes.profileSettings),
                  ),
                  _MenuTile(
                    icon: Icons.language_outlined,
                    title: l10n.language,
                    subtitle: currentLocale.languageCode == 'hi'
                        ? 'हिंदी'
                        : 'English',
                    onTap: () => _go(context, AppRoutes.languageSettings),
                  ),
                  _MenuTile(
                    icon: Icons.brightness_6_outlined,
                    title: l10n.theme,
                    subtitle: themeMode == ThemeMode.dark
                        ? l10n.dark
                        : l10n.light,
                    onTap: () => _showThemePicker(context, ref),
                  ),
                  const Divider(),
                  _MenuTile(
                    icon: Icons.bug_report_outlined,
                    title: l10n.submitError,
                    onTap: () => _showErrorReportDialog(context, ref),
                  ),
                  _MenuTile(
                    icon: Icons.help_outline_rounded,
                    title: l10n.help,
                    onTap: () => _go(context, AppRoutes.help),
                  ),
                  _MenuTile(
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.privacyPolicy,
                    onTap: () => _go(context, AppRoutes.privacy),
                  ),
                  _MenuTile(
                    icon: Icons.description_outlined,
                    title: l10n.termsOfUse,
                    onTap: () => _go(context, AppRoutes.terms),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _MenuTile(
              icon: Icons.logout,
              title: l10n.logout,
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _showErrorReportDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    Navigator.of(context).pop();
    await showDialog<void>(
      context: context,
      builder: (context) => const _SubmitErrorDialog(),
    );
  }

  Future<void> _showThemePicker(BuildContext context, WidgetRef ref) async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) {
        final current = ref.read(appThemeControllerProvider);
        final l10n = AppLocalizations.of(context)!;
        return SimpleDialog(
          title: Text(l10n.themeDialogTitle),
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: Text(l10n.light),
              trailing: current == ThemeMode.light
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.of(context).pop(ThemeMode.light),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: Text(l10n.dark),
              trailing: current == ThemeMode.dark
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.of(context).pop(ThemeMode.dark),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      await ref
          .read(appThemeControllerProvider.notifier)
          .setThemeMode(selected);
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _SubmitErrorDialog extends ConsumerStatefulWidget {
  const _SubmitErrorDialog();

  @override
  ConsumerState<_SubmitErrorDialog> createState() => _SubmitErrorDialogState();
}

class _SubmitErrorDialogState extends ConsumerState<_SubmitErrorDialog> {
  final TextEditingController _detailsController = TextEditingController();
  String _type = 'bug';
  bool _submitting = false;

  static const List<String> _types = ['bug', 'crash', 'performance', 'other'];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.submitError),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: l10n.errorType,
                border: const OutlineInputBorder(),
              ),
              items: _types
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_titleCase(type)),
                    ),
                  )
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _detailsController,
              minLines: 5,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: l10n.whatWentWrong,
                hintText: l10n.describeIssueHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    l10n.deviceLogsIncluded,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.viewCollectedLogs,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: _showCollectedLogs,
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.submit),
        ),
      ],
    );
  }

  void _showCollectedLogs() {
    final logs = AppLogCollector.formattedLogs();
    final l10n = AppLocalizations.of(context)!;
    final logText = logs.isEmpty ? l10n.noAppLogsYet : logs.join('\n\n');

    showDialog<void>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return AlertDialog(
          title: Text(l10n.collectedLogs),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 420),
            child: SingleChildScrollView(
              child: SelectableText(
                logText,
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    final issue = _detailsController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (issue.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseDescribeIssue)));
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mustBeLoggedInToSubmitIssues)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      final mediaQuery = MediaQuery.of(context);
      final routeName = ModalRoute.of(context)?.settings.name;

      await ref.read(reportRepositoryProvider).submitErrorReport({
        'type': _type,
        'title': 'User Reported ${_titleCase(_type)}',
        'issue': issue,
        'currentRoute': routeName ?? 'profile',
        'deviceInfo': {
          'platform': defaultTargetPlatform.name,
          'isWeb': kIsWeb,
          'locale': Localizations.localeOf(context).toLanguageTag(),
          'screenSize':
              '${mediaQuery.size.width.toStringAsFixed(0)}x${mediaQuery.size.height.toStringAsFixed(0)}',
          'devicePixelRatio': mediaQuery.devicePixelRatio,
          'appVersion': packageInfo.version,
          'buildNumber': packageInfo.buildNumber,
          'packageName': packageInfo.packageName,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'reporterId': user.id,
        'reporterEmail': user.email,
        'consoleLogs': AppLogCollector.formattedLogs(),
        'status': 'pending',
        'occurrenceCount': 1,
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.issueReportSubmitted)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToSubmitIssueReport(error.toString())),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String _titleCase(String value) {
    return value
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _StatItem({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
