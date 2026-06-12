import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../domain/models/report.dart';
import '../providers/report_providers.dart';
import '../providers/auth_providers.dart';
import 'glass_surface.dart';

class ReportDialog extends ConsumerStatefulWidget {
  final String targetId;
  final String targetType;

  const ReportDialog({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  String? _selectedReason;
  final _detailsController = TextEditingController();
  bool _submitting = false;

  final List<String> _reasons = const [
    'spam',
    'offensive_content',
    'inappropriate_language',
    'harassment',
    'spoiler',
    'other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;

    setState(() => _submitting = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.mustBeLoggedInToReportContent)),
          );
        }
        return;
      }

      await ref
          .read(reportRepositoryProvider)
          .submitReport(
            Report(
              reporterId: user.id,
              targetId: widget.targetId,
              targetType: widget.targetType,
              reason: _selectedReason!,
              details: _detailsController.text.trim().isEmpty
                  ? null
                  : _detailsController.text.trim(),
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reportSubmittedThanks),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToSubmitReport(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                l10n.reportTarget(widget.targetType),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.whyReportContent,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: SingleChildScrollView(
                  child: RadioGroup<String>(
                    groupValue: _selectedReason,
                    onChanged: (val) => setState(() => _selectedReason = val),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ..._reasons.map(
                          (reason) => RadioListTile<String>(
                            title: Text(_reasonLabel(l10n, reason)),
                            value: reason,
                            selected: reason == _selectedReason,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _detailsController,
                decoration: InputDecoration(
                  labelText: l10n.additionalDetailsOptional,
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 18),
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
                    onPressed: _selectedReason == null || _submitting
                        ? null
                        : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.submitReport),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _reasonLabel(AppLocalizations l10n, String reason) {
    return switch (reason) {
      'spam' => l10n.reasonSpam,
      'offensive_content' => l10n.reasonOffensiveContent,
      'inappropriate_language' => l10n.reasonInappropriateLanguage,
      'harassment' => l10n.reasonHarassment,
      'spoiler' => l10n.reasonSpoiler,
      _ => l10n.reasonOther,
    };
  }
}
