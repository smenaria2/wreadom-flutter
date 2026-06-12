import 'package:flutter/material.dart';
import 'dart:async';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_update_provider.dart';
import '../providers/navigation_providers.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_surface.dart';
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
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          IndexedStack(index: selectedIndex, children: _screens),
        ],
      ),
      bottomNavigationBar: GlassSurface(
        strong: true,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.book_outlined,
                  Icons.book,
                  l10n.home,
                  selectedIndex,
                ),
                _buildNavItem(
                  1,
                  Icons.feed_outlined,
                  Icons.feed,
                  l10n.feed,
                  selectedIndex,
                ),
                _buildNavItem(
                  2,
                  Icons.edit_note_outlined,
                  Icons.edit_note,
                  l10n.writer,
                  selectedIndex,
                ),
                _buildNavItem(
                  3,
                  Icons.chat_bubble_outline,
                  Icons.chat_bubble,
                  l10n.messages,
                  selectedIndex,
                ),
                _buildNavItem(
                  4,
                  Icons.person_outline,
                  Icons.person,
                  l10n.profile,
                  selectedIndex,
                  badge: hasUpdate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
    int selectedIndex, {
    bool badge = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(selectedTabProvider.notifier).setTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isSelected ? 1.1 : 1.0,
                child: _UpdateBadgeIcon(
                  icon: isSelected ? selectedIcon : icon,
                  showBadge: badge,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: theme.textTheme.labelMedium!.copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 11,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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
            content: Text(AppLocalizations.of(context)!.appUpdateAvailable),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.updateAction,
              onPressed: () => unawaited(_openUpdateLink(availability)),
            ),
          ),
        );
    });
  }

  Future<void> _openUpdateLink(AppUpdateAvailability availability) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(availability.config.androidDownloadUrl);
    if (uri == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.invalidUpdateLink)));
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenUpdateLink)),
      );
    }
  }
}

class _UpdateBadgeIcon extends StatelessWidget {
  const _UpdateBadgeIcon({
    required this.icon,
    required this.showBadge,
    this.color,
  });

  final IconData icon;
  final bool showBadge;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return Icon(icon, color: color);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color),
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
