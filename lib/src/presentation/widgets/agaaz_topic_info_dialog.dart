import 'package:flutter/material.dart';
import '../../localization/generated/app_localizations.dart';

Future<void> showAgaazTopicInfoDialog({
  required BuildContext context,
  required bool optOutComplementary,
  required ValueChanged<bool> onOptOutChanged,
}) async {
  showDialog(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final l10n = AppLocalizations.of(context)!;
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/agaaz_logo.jpg',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.agaazTopicInfoTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.agaazTopicInfoBody,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.enableRecreateTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      l10n.enableRecreateSubtitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    value: !optOutComplementary,
                    onChanged: (val) {
                      setState(() {
                        optOutComplementary = !val;
                      });
                      onOptOutChanged(!val);
                    },
                  ),
                ],
              ),
            );
          },
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
