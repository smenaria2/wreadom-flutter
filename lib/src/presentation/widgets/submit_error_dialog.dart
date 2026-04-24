import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../utils/app_log_collector.dart';
import '../providers/auth_providers.dart';
import '../providers/report_providers.dart';

class SubmitErrorDialog extends ConsumerStatefulWidget {
  const SubmitErrorDialog({super.key});

  @override
  ConsumerState<SubmitErrorDialog> createState() => _SubmitErrorDialogState();
}

class _SubmitErrorDialogState extends ConsumerState<SubmitErrorDialog> {
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
    return AlertDialog(
      title: Text(l10n.submitError),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: l10n.errorType,
                border: const OutlineInputBorder(),
              ),
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
                border: const OutlineInputBorder(),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
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
        'currentRoute': routeName ?? 'help',
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
        SnackBar(content: Text(l10n.failedToSubmitIssueReport('$error'))),
      );
      setState(() => _submitting = false);
    }
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
