import 'package:flutter/material.dart';
import 'dart:async';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_update_provider.dart';
import '../providers/navigation_providers.dart';
import '../providers/theme_provider.dart';
import 'messages_screen.dart';
import 'home_feed_screen.dart';
import 'home_books_screen.dart';
import 'writer_dashboard_screen.dart';
import 'profile_screen.dart';
import '../providers/auth_providers.dart';
import '../../data/services/notification_service.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  StreamSubscription<String>? _tokenRefreshSubscription;
  final Set<int> _checkedUpdateNoticeBuilds = <int>{};

  static const String _updateNoticePrefix = 'wreadom_update_notice_shown_';

  @override
  void initState() {
    super.initState();
    // Use future to ensure provider is updated after initial build if needed,
    // but better yet, set it directly if it's the first time.
    Future.microtask(() {
      ref.read(selectedTabProvider.notifier).setTab(widget.initialIndex);
      _setupNotifications();
    });
  }

  Future<void> _setupNotifications() async {
    final notificationService = NotificationService.instance;
    final hasPermission = await notificationService.requestPermission();

    if (hasPermission) {
      final token = await notificationService.getFcmToken();
      if (token != null) {
        final user = await ref.read(currentUserProvider.future);
        if (user != null) {
          try {
            await ref
                .read(authRepositoryProvider)
                .claimFcmToken(user.id, token);
            debugPrint('FCM Token updated successfully');
          } catch (e) {
            debugPrint('Failed to update FCM Token: $e');
          }
        }
      }
    }

    _tokenRefreshSubscription ??= notificationService.onTokenRefresh.listen((
      token,
    ) async {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) return;
      try {
        await ref.read(authRepositoryProvider).claimFcmToken(user.id, token);
        debugPrint('Refreshed FCM token updated successfully');
      } catch (e) {
        debugPrint('Failed to update refreshed FCM token: $e');
      }
    });
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }

  List<Widget> get _screens => [
    const HomeBooksScreen(),
    HomeFeedScreen(),
    const WriterDashboardScreen(),
    const MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedIndex = ref.watch(selectedTabProvider);
    final updateAvailability = ref
        .watch(appUpdateAvailabilityProvider)
        .maybeWhen(data: (availability) => availability, orElse: () => null);
    final hasUpdate = updateAvailability != null;
    if (updateAvailability != null) {
      _queueUpdateNotice(updateAvailability);
    }

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            ref.read(selectedTabProvider.notifier).setTab(index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.feed_outlined),
            selectedIcon: const Icon(Icons.feed),
            label: l10n.feed,
          ),
          NavigationDestination(
            icon: const Icon(Icons.edit_note_outlined),
            selectedIcon: const Icon(Icons.edit_note),
            label: l10n.writer,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: l10n.messages,
          ),
          NavigationDestination(
            icon: _UpdateBadgeIcon(
              icon: Icons.person_outline,
              showBadge: hasUpdate,
            ),
            selectedIcon: _UpdateBadgeIcon(
              icon: Icons.person,
              showBadge: hasUpdate,
            ),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }

  void _queueUpdateNotice(AppUpdateAvailability availability) {
    final buildNumber = availability.config.androidBuildNumber;
    if (!_checkedUpdateNoticeBuilds.add(buildNumber)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefs = ref.read(sharedPreferencesProvider);
      final key = '$_updateNoticePrefix$buildNumber';
      if (prefs.getBool(key) ?? false) return;
      await prefs.setBool(key, true);
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: const Text('A new Wreadom update is available.'),
            action: SnackBarAction(
              label: 'Update',
              onPressed: () => unawaited(_openUpdateLink(availability)),
            ),
          ),
        );
    });
  }

  Future<void> _openUpdateLink(AppUpdateAvailability availability) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(availability.config.androidDownloadUrl);
    if (uri == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Update link is not valid.')),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open update link.')),
      );
    }
  }
}

class _UpdateBadgeIcon extends StatelessWidget {
  const _UpdateBadgeIcon({required this.icon, required this.showBadge});

  final IconData icon;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return Icon(icon);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        const Positioned(top: -2, right: -4, child: _UpdateRedDot(size: 9)),
      ],
    );
  }
}

class _UpdateRedDot extends StatelessWidget {
  const _UpdateRedDot({this.size = 8});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: Theme.of(context).colorScheme.surface, width: 1.5),
        ),
      ),
      child: SizedBox.square(dimension: size),
    );
  }
}
