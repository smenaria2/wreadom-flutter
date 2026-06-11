import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../providers/auth_providers.dart';
import '../../providers/follow_providers.dart';
import '../../providers/writer_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_surface.dart';

class WriterDashboardHeader extends ConsumerWidget {
  const WriterDashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final books = ref.watch(myBooksProvider).asData?.value ?? const [];
        final published = books
            .where((book) => book.status == 'published')
            .length;
        final reads = books.fold<int>(
          0,
          (sum, book) => sum + (book.viewCount ?? 0),
        );
        final followersCount = ref
            .watch(userFollowersListProvider(user.id))
            .maybeWhen(
              data: (followers) => followers.length,
              orElse: () => user.followersCount ?? 0,
            );
        final colorScheme = theme.colorScheme;
        final glass = theme.extension<GlassTokens>() ?? GlassTokens.light;

        return GlassSurface(
          strong: true,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.16),
                  colorScheme.secondary.withValues(alpha: 0.10),
                  colorScheme.tertiary.withValues(alpha: 0.12),
                ],
                stops: const [0, 0.62, 1],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.welcomeBackComma,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            user.penName ?? user.displayName ?? user.username,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.62),
                        shape: BoxShape.circle,
                        border: Border.all(color: glass.borderColor),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: colorScheme.surface,
                        backgroundImage: user.photoURL != null
                            ? CachedNetworkImageProvider(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? Icon(
                                Icons.person,
                                size: 32,
                                color: colorScheme.primary,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      _InfoItem(
                        label: l10n.published,
                        value: '$published',
                        icon: Icons.library_books_rounded,
                      ),
                      VerticalDivider(
                        color: glass.borderColor,
                        indent: 8,
                        endIndent: 8,
                      ),
                      _InfoItem(
                        label: l10n.reads,
                        value: '$reads',
                        icon: Icons.visibility_rounded,
                      ),
                      VerticalDivider(
                        color: glass.borderColor,
                        indent: 8,
                        endIndent: 8,
                      ),
                      _InfoItem(
                        label: l10n.followers,
                        value: '$followersCount',
                        icon: Icons.people_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 180),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
