import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../providers/auth_providers.dart';
import '../../providers/writer_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
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
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          user.penName ?? user.displayName ?? user.username,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: user.photoURL != null
                          ? CachedNetworkImageProvider(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? Icon(
                              Icons.person,
                              size: 32,
                              color: theme.primaryColor,
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
                      color: Colors.white.withValues(alpha: 0.3),
                      indent: 8,
                      endIndent: 8,
                    ),
                    _InfoItem(
                      label: l10n.reads,
                      value: '$reads',
                      icon: Icons.visibility_rounded,
                    ),
                    VerticalDivider(
                      color: Colors.white.withValues(alpha: 0.3),
                      indent: 8,
                      endIndent: 8,
                    ),
                    _InfoItem(
                      label: l10n.followers,
                      value: '${user.followersCount ?? 0}',
                      icon: Icons.people_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 180),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
