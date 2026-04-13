import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'messages_screen.dart';
import 'home_feed_screen.dart';
import 'home_books_screen.dart';
import 'writer_dashboard_screen.dart';
import 'profile_screen.dart';

/// Provides a way for child screens to switch the root tab.
class TabSwitchNotifier extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void switchTo(int i) {
    _index = i;
    notifyListeners();
  }
}

class MainNavigationShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  late int _selectedIndex;
  final TabSwitchNotifier _tabNotifier = TabSwitchNotifier();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _tabNotifier.addListener(_onTabSwitch);
  }

  void _onTabSwitch() {
    setState(() => _selectedIndex = _tabNotifier.index);
  }

  @override
  void dispose() {
    _tabNotifier.removeListener(_onTabSwitch);
    _tabNotifier.dispose();
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
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
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
