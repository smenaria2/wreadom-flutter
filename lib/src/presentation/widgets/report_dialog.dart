import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/report.dart';
import '../providers/report_providers.dart';
import '../providers/auth_providers.dart';

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

  final List<String> _reasons = [
    'Spam',
    'Offensive Content',
    'Inappropriate Language',
    'Harassment',
    'Spoiler without warning',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;

    setState(() => _submitting = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to report content.'),
            ),
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
          const SnackBar(
            content: Text(
              'Thank you for your report. We will review it shortly.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit report: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.targetType}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this content?'),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: _selectedReason,
              onChanged: (val) => setState(() => _selectedReason = val),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._reasons.map(
                    (reason) => RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      selected: reason == _selectedReason,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Additional Details (Optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null || _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}
