import 'package:flutter/material.dart';
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
    final selectedIndex = ref.watch(selectedTabProvider);

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            ref.read(selectedTabProvider.notifier).setTab(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Writer',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
