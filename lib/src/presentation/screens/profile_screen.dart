import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/user_model.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_controller.dart';
import '../providers/app_update_provider.dart';
import '../providers/book_providers.dart';
import '../providers/haptics_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/notification_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/report_providers.dart';
import '../providers/shake_report_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/writer_providers.dart';
import '../widgets/auth_required_view.dart';
import '../widgets/glass_surface.dart';
import '../widgets/share_app_dialog.dart';
import '../widgets/social_links_menu.dart';
import '../../utils/format_utils.dart';
import '../../utils/app_log_collector.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../components/profile/user_posts_tab.dart';
import '../components/profile/user_about_tab.dart';
import '../components/profile/user_history_tab.dart';
import '../components/profile/user_saved_tab.dart';
import '../components/profile/user_downloaded_tab.dart';
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
          return Scaffold(
            appBar: AppBar(title: Text(l10n.profile)),
            body: const AuthRequiredView(icon: Icons.account_circle_outlined),
          );
        }
        final worksCount = ref
            .watch(userBooksProvider(user.id))
            .maybeWhen(
              data: (books) => books.length,
              orElse: () => user.pinnedWorks?.length ?? 0,
            );

        return DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: Colors.transparent,
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
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    surfaceTintColor: Colors.transparent,
                    iconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      title: AnimatedOpacity(
                        opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _safeProfileDisplayName(user),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
                      child: GlassControlSurface(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        borderRadius: BorderRadius.circular(28),
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
                  ),

                  // ─── Tab Bar ───────────────────────────────────
                  SliverPersistentHeader(
                    pinned: false,
                    delegate: _SliverAppBarDelegate(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: GlassControlSurface(
                          padding: const EdgeInsets.all(4),
                          borderRadius: BorderRadius.circular(30),
                          child: TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                            ),
                            labelColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            unselectedLabelColor: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            dividerColor: Colors.transparent,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.22),
                              ),
                            ),
                            tabs: [
                              Tab(text: l10n.about),
                              Tab(text: l10n.posts),
                              Tab(text: l10n.history),
                              Tab(text: l10n.saved),
                              Tab(text: l10n.downloaded),
                            ],
                          ),
                        ),
                      ),
                      height: 78,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _ProfileTabBody(child: UserAboutTab(user: user)),
                  _ProfileTabBody(child: UserPostsTab(userId: user.id)),
                  const _ProfileTabBody(child: UserHistoryTab()),
                  const _ProfileTabBody(child: UserSavedTab()),
                  const _ProfileTabBody(child: UserDownloadedTab()),
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
    final name = _safeProfileDisplayName(user);
    shareUserProfileCard(
      context,
      user: user,
      worksCount: worksCount,
      fallbackText:
          'Follow $name on Wreadom.  Read and listen hundred of stories on Wreadom.\n\n${AppLinkHelper.user(user.id)}',
    );
  }
}

class _ProfileTabBody extends StatelessWidget {
  const _ProfileTabBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(top: 14), child: child);
  }
}

String _safeProfileDisplayName(UserModel user) {
  for (final value in [user.displayName, user.penName, user.username]) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return 'Reader';
}

String _safeProfileInitial(String displayName) {
  final trimmed = displayName.trim();
  return (trimmed.isEmpty ? 'Reader' : trimmed).characters.first.toUpperCase();
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
            deliveryTransform: isCover
                ? 'f_auto,q_auto,w_1600,h_600,c_fill'
                : 'f_auto,q_auto,w_600,h_600,c_fill',
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
    final displayName = _safeProfileDisplayName(user);
    final initial = _safeProfileInitial(displayName);
    final settings = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final collapseProgress = _profileCollapseProgress(settings);
    final expandedOpacity = (1.0 - collapseProgress / 0.66).clamp(0.0, 1.0);
    final coverBlur = 1.2 + (collapseProgress * 16);

    return GlassSurface(
      strong: true,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasCover)
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: coverBlur,
                sigmaY: coverBlur,
              ),
              child: CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.10),
                    theme.colorScheme.secondary.withValues(alpha: 0.08),
                    theme.colorScheme.tertiary.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(
                alpha: hasCover
                    ? 0.36 + collapseProgress * 0.30
                    : 0.08 + collapseProgress * 0.22,
              ),
            ),
          ),
          Opacity(
            opacity: collapseProgress,
            child: const GlassSurface(
              strong: true,
              borderRadius: BorderRadius.zero,
              child: SizedBox.expand(),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 18,
            child: Tooltip(
              message: l10n.changeCoverPicture,
              child: GlassSurface(
                borderRadius: BorderRadius.circular(20),
                onTap: _uploadingCover ? null : _changeCoverPicture,
                semanticButton: true,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: _uploadingCover
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.photo_camera_outlined,
                            color: theme.colorScheme.onSurface,
                          ),
                  ),
                ),
              ),
            ),
          ),
          Opacity(
            opacity: expandedOpacity,
            child: Transform.scale(
              scale: 1 - collapseProgress * 0.08,
              child: SafeArea(
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
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            backgroundImage: user.photoURL != null
                                ? CachedNetworkImageProvider(user.photoURL!)
                                : null,
                            child: user.photoURL == null
                                ? Text(
                                    initial,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          right: -8,
                          bottom: -4,
                          child: Tooltip(
                            message: l10n.changeProfilePicture,
                            child: GlassSurface(
                              borderRadius: BorderRadius.circular(18),
                              onTap: _uploadingAvatar
                                  ? null
                                  : _changeProfilePicture,
                              semanticButton: true,
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: Center(
                                  child: _uploadingAvatar
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          Icons.photo_camera_outlined,
                                          size: 18,
                                          color: theme.colorScheme.primary,
                                        ),
                                ),
                              ),
                            ),
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
    final isAdmin = ref.watch(currentUserAdminClaimProvider).value ?? false;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: GlassSurface(
        strong: true,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(28)),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Wreadom',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _MenuSectionLabel(label: l10n.account),
                    _MenuTile(
                      icon: Icons.manage_accounts_outlined,
                      title: l10n.editProfile,
                      onTap: () => _go(context, AppRoutes.profileSettings),
                    ),
                    if (isAdmin)
                      _MenuTile(
                        icon: Icons.topic_outlined,
                        title: l10n.manageDailyTopics,
                        onTap: () => _go(context, AppRoutes.adminDailyTopics),
                      ),
                    const Divider(),
                    _MenuSectionLabel(label: l10n.preferences),
                    _MenuTile(
                      icon: Icons.language_outlined,
                      title: l10n.language,
                      subtitle: currentLocale.languageCode == 'hi'
                          ? l10n.hindi
                          : l10n.english,
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
                    _GlassSwitchTile(
                      icon: Icons.touch_app_outlined,
                      title: l10n.hapticFeedback,
                      subtitle: l10n.hapticFeedbackSubtitle,
                      value: ref.watch(hapticsEnabledProvider),
                      onChanged: (enabled) => ref
                          .read(hapticsEnabledProvider.notifier)
                          .setEnabled(enabled),
                    ),
                    const Divider(),
                    _MenuSectionLabel(label: l10n.support),
                    const _AppUpdateTile(),
                    _MenuTile(
                      icon: Icons.bug_report_outlined,
                      title: l10n.submitError,
                      onTap: () => _showErrorReportDialog(context, ref),
                    ),
                    _GlassSwitchTile(
                      icon: Icons.vibration_rounded,
                      title: l10n.shakeToReport,
                      subtitle: l10n.shakeToReportSubtitle,
                      value: ref.watch(shakeToReportEnabledProvider),
                      onChanged: (enabled) => ref
                          .read(shakeToReportEnabledProvider.notifier)
                          .setEnabled(enabled),
                    ),
                    _MenuTile(
                      icon: Icons.help_outline_rounded,
                      title: l10n.help,
                      onTap: () => _go(context, AppRoutes.help),
                    ),
                    _MenuTile(
                      icon: Icons.share_rounded,
                      title: 'Share & Review App',
                      onTap: () => ShareAppDialog.show(context),
                    ),
                    const Divider(),
                    _MenuSectionLabel(label: l10n.legal),
                    _MenuTile(
                      icon: Icons.privacy_tip_outlined,
                      title: l10n.privacyPolicy,
                      onTap: () => _openPolicy(context, AppRoutes.privacy),
                    ),
                    _MenuTile(
                      icon: Icons.description_outlined,
                      title: l10n.termsOfUse,
                      onTap: () => _openPolicy(context, AppRoutes.terms),
                    ),
                    const Divider(),
                    const _MenuSectionLabel(label: 'Social'),
                    const SocialLinksMenu(),
                    const _AppVersionTile(),
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
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _openPolicy(BuildContext context, String route) async {
    Navigator.of(context).pop();
    await AppRouter.openExternalPolicy(context, route);
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

class _MenuSectionLabel extends StatelessWidget {
  const _MenuSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _AppVersionTile extends ConsumerStatefulWidget {
  const _AppVersionTile();

  @override
  ConsumerState<_AppVersionTile> createState() => _AppVersionTileState();
}

class _AppVersionTileState extends ConsumerState<_AppVersionTile> {
  late final Future<String> _versionLabel = _loadVersionLabel();
  bool _checking = false;

  Future<String> _loadVersionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return 'Version ${info.version} (${info.buildNumber})';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<String>(
      future: _versionLabel,
      builder: (context, snapshot) {
        return ListTile(
          enabled: !_checking,
          leading: _checking
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.info_outline, size: 20),
          title: Text(
            snapshot.data ?? 'Version',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: _checking ? null : _checkForUpdate,
        );
      },
    );
  }

  Future<void> _checkForUpdate() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() => _checking = true);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.appUpdateChecking)));

    try {
      final availability = await ref.refresh(
        appUpdateAvailabilityProvider.future,
      );
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      if (availability == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.appUpdateNoUpdateFound)),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.appUpdateAvailable),
          action: SnackBarAction(
            label: l10n.updateAction,
            onPressed: () =>
                unawaited(_openAppUpdateLink(context, availability)),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }
}

class _AppUpdateTile extends ConsumerWidget {
  const _AppUpdateTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateAsync = ref.watch(appUpdateAvailabilityProvider);
    return updateAsync.maybeWhen(
      data: (availability) {
        if (availability == null) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        return _MenuTile(
          icon: Icons.system_update_alt_rounded,
          title: l10n.updateApp,
          subtitle: l10n.latestBuild(availability.config.androidBuildNumber),
          showBadge: true,
          onTap: () => _openUpdateLink(context, availability),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Future<void> _openUpdateLink(
    BuildContext context,
    AppUpdateAvailability availability,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    await _openAppUpdateLink(context, availability, messenger, l10n);
  }
}

Future<void> _openAppUpdateLink(
  BuildContext context,
  AppUpdateAvailability availability, [
  ScaffoldMessengerState? messenger,
  AppLocalizations? l10n,
]) async {
  messenger ??= ScaffoldMessenger.of(context);
  l10n ??= AppLocalizations.of(context)!;
  final uri = Uri.tryParse(availability.config.androidDownloadUrl);
  if (uri == null) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.invalidUpdateLink)));
    return;
  }

  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.couldNotOpenUpdateLink)),
    );
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
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassSurface(
        strong: true,
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.submitError,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(labelText: l10n.errorType),
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 10),
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
              ),
            ],
          ),
        ),
      ),
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
    this.showBadge = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        semanticButton: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _MenuTileIcon(icon: icon, showBadge: showBadge),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassSwitchTile extends StatelessWidget {
  const _GlassSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTileIcon extends StatelessWidget {
  const _MenuTileIcon({required this.icon, required this.showBadge});

  final IconData icon;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return Icon(icon, size: 20);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 20),
        const Positioned(top: -1, right: -3, child: _UpdateMenuRedDot()),
      ],
    );
  }
}

class _UpdateMenuRedDot extends StatelessWidget {
  const _UpdateMenuRedDot();

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
      child: const SizedBox.square(dimension: 9),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._child, {required this.height});

  final Widget _child;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return GlassSurface(
      strong: true,
      borderRadius: BorderRadius.zero,
      child: _child,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

double _profileCollapseProgress(FlexibleSpaceBarSettings? settings) {
  if (settings == null) return 0;
  final delta = settings.maxExtent - settings.minExtent;
  if (delta <= 0) return 1;
  return ((settings.maxExtent - settings.currentExtent) / delta).clamp(
    0.0,
    1.0,
  );
}
