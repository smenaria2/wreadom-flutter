import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_controller.dart';
import '../providers/notification_providers.dart';
import '../providers/report_providers.dart';
import '../providers/theme_provider.dart';
import '../../utils/format_utils.dart';
import '../../utils/app_log_collector.dart';
import '../routing/app_routes.dart';
import '../components/profile/user_posts_tab.dart';
import '../components/profile/user_about_tab.dart';
import '../components/profile/user_history_tab.dart';
import '../components/profile/user_saved_tab.dart';
import 'follow_list_screen.dart';
import '../../utils/app_link_helper.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Please log in')));
        }

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
                      background: Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        child: SafeArea(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                backgroundImage: user.photoURL != null
                                    ? CachedNetworkImageProvider(user.photoURL!)
                                    : null,
                                child: user.photoURL == null
                                    ? Text(
                                        (user.displayName ?? user.username)[0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                user.displayName ?? user.username,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '@${user.username}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Share Profile',
                        icon: const Icon(Icons.ios_share_rounded),
                        onPressed: () => _shareProfile(
                          user.id,
                          user.displayName ?? user.username,
                        ),
                      ),
                      _NotificationAction(),
                      Builder(
                        builder: (context) => IconButton(
                          tooltip: 'Menu',
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
                            label: 'Followers',
                            value: FormatUtils.formatNumber(
                              user.followersCount ?? 0,
                            ),
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.followList,
                              arguments: FollowListArguments(
                                userId: user.id,
                                mode: FollowListMode.followers,
                                title: 'Followers',
                              ),
                            ),
                          ),
                          _StatItem(
                            label: 'Following',
                            value: FormatUtils.formatNumber(
                              user.followingCount ?? 0,
                            ),
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.followList,
                              arguments: FollowListArguments(
                                userId: user.id,
                                mode: FollowListMode.following,
                                title: 'Following',
                              ),
                            ),
                          ),
                          _StatItem(
                            label: 'Points',
                            value: FormatUtils.formatNumber(
                              user.totalPoints ?? 0,
                            ),
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
                        tabs: const [
                          Tab(text: 'About'),
                          Tab(text: 'Posts'),
                          Tab(text: 'History'),
                          Tab(text: 'Saved'),
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
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  void _shareProfile(String userId, String name) {
    Share.share(
      'Read with $name on Wreadom\n${AppLinkHelper.user(userId)}',
      subject: '$name on Wreadom',
    );
  }
}

class _NotificationAction extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    final btn = IconButton(
      tooltip: 'Notifications',
      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
      icon: const Icon(Icons.notifications_none_rounded),
    );
    if (unread <= 0) return btn;
    return Badge(label: Text(unread > 99 ? '99+' : '$unread'), child: btn);
  }
}

class _ProfileSideMenu extends ConsumerWidget {
  const _ProfileSideMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(appThemeControllerProvider);

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
                    title: 'Edit Profile',
                    onTap: () => _go(context, AppRoutes.profileSettings),
                  ),
                  _MenuTile(
                    icon: Icons.brightness_6_outlined,
                    title: 'Theme',
                    subtitle: themeMode == ThemeMode.dark ? 'Dark' : 'Light',
                    onTap: () => _showThemePicker(context, ref),
                  ),
                  const Divider(),
                  _MenuTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Submit Error',
                    onTap: () => _showErrorReportDialog(context, ref),
                  ),
                  _MenuTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help',
                    onTap: () => _go(context, AppRoutes.help),
                  ),
                  _MenuTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _go(context, AppRoutes.privacy),
                  ),
                  _MenuTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Use',
                    onTap: () => _go(context, AppRoutes.terms),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _MenuTile(
              icon: Icons.logout,
              title: 'Logout',
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
        return SimpleDialog(
          title: const Text('Theme'),
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: const Text('Light'),
              trailing: current == ThemeMode.light
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.of(context).pop(ThemeMode.light),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark'),
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
    return AlertDialog(
      title: const Text('Submit Error'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Error type',
                border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: 'What went wrong?',
                hintText: 'Describe the error and what you were doing.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Device info and recent app logs will be included.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'View collected logs',
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  void _showCollectedLogs() {
    final logs = AppLogCollector.formattedLogs();
    final logText = logs.isEmpty
        ? 'No app logs have been collected yet.'
        : logs.join('\n\n');

    showDialog<void>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return AlertDialog(
          title: const Text('Collected Logs'),
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
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    final issue = _detailsController.text.trim();
    if (issue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the error.')),
      );
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit errors.'),
        ),
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
      ).showSnackBar(const SnackBar(content: Text('Error report submitted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit error report: $error')),
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
