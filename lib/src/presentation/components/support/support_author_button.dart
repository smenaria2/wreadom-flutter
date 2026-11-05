import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../providers/support_providers.dart';
import 'support_author_sheet.dart';

/// "Support author" button. Renders nothing unless the author has enabled
/// UPI support, so it is safe to drop into any author surface.
class SupportAuthorButton extends ConsumerWidget {
  const SupportAuthorButton({
    super.key,
    required this.authorId,
    required this.authorName,
    this.compact = false,
  });

  final String authorId;
  final String authorName;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final support = ref.watch(authorSupportProvider(authorId)).value;
    if (support == null || !support.isActive) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    void open() => showSupportAuthorSheet(
      context,
      authorId: authorId,
      authorName: authorName,
      support: support,
    );

    if (compact) {
      return IconButton(
        tooltip: l10n.supportAuthor,
        icon: const Icon(Icons.favorite_border),
        iconSize: 20,
        color: Theme.of(context).colorScheme.primary,
        onPressed: open,
      );
    }
    return FilledButton.tonalIcon(
      onPressed: open,
      icon: const Icon(Icons.favorite_border),
      label: Text(l10n.supportAuthor),
    );
  }
}
