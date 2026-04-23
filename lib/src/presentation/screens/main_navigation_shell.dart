import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_providers.dart';
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
                .updateFcmToken(user.id, token);
            debugPrint('FCM Token updated successfully');
          } catch (e) {
            debugPrint('Failed to update FCM Token: $e');
          }
        }
      }
    }
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
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
