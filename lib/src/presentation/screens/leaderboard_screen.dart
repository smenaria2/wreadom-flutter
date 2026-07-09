import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../localization/generated/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/auth_required_view.dart';
import '../components/profile/leaderboard_tab.dart';
import '../routing/app_routes.dart';

class LeaderboardScreen extends ConsumerWidget {
  final String initialCategory;

  const LeaderboardScreen({
    super.key,
    this.initialCategory = 'reader',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return GlassScaffold(
      appBar: glassAppBar(
        title: Text(
          l10n.leaderboard,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const AuthRequiredView(icon: Icons.account_circle_outlined);
          }
          return LeaderboardTab(
            currentUser: user,
            initialCategory: initialCategory,
            onUserClick: (userId) {
              Navigator.of(context).pushNamed(
                AppRoutes.publicProfile,
                arguments: userId,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(l10n.failedToLoadTitle(l10n.leaderboard, err.toString())),
        ),
      ),
    );
  }
}
