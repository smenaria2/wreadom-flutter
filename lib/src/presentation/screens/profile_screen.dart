import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_controller.dart';
import '../providers/notification_providers.dart';
import '../../utils/maintenance_utils.dart';
import '../routing/app_routes.dart';
import '../components/profile/user_posts_tab.dart';
import '../components/profile/user_about_tab.dart';
import '../components/profile/user_history_tab.dart';
import '../components/profile/user_saved_tab.dart';

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
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        child: SafeArea(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                backgroundImage: user.photoURL != null
                                    ? NetworkImage(user.photoURL!)
                                    : null,
                                child: user.photoURL == null
                                    ? Text(
                                        (user.displayName ?? user.username)[0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                user.displayName ?? user.username,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '@${user.username}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      _NotificationAction(),
                      _ProfileMenu(ref: ref),
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
                            value: _fmt(user.followersCount ?? 0),
                          ),
                          _StatItem(
                            label: 'Following',
                            value: _fmt(user.followingCount ?? 0),
                          ),
                          _StatItem(
                            label: 'Points',
                            value: _fmt(user.totalPoints ?? 0),
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
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _NotificationAction extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    final btn = IconButton(
      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
      icon: const Icon(Icons.notifications_none_rounded),
    );
    if (unread <= 0) return btn;
    return Badge(
      label: Text(unread > 99 ? '99+' : '$unread'),
      child: btn,
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final WidgetRef ref;
  const _ProfileMenu({required this.ref});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (val) async {
        if (val == 'logout') {
          await ref.read(authControllerProvider.notifier).logout();
        } else if (val == 'settings') {
          Navigator.of(context).pushNamed(AppRoutes.profileSettings);
        } else if (val == 'writer') {
          Navigator.of(context).pushNamed(AppRoutes.writerDashboard);
        } else if (val == 'migrate') {
          await migrateComments();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Migration complete!')),
            );
          }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings, size: 18),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'writer',
          child: Row(
            children: [
              Icon(Icons.edit_note, size: 18),
              SizedBox(width: 8),
              Text('Writer Dashboard'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'migrate',
          child: Row(
            children: [
              Icon(Icons.storage, size: 18),
              SizedBox(width: 8),
              Text('Migrate Comments'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
