import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../domain/models/author_support.dart';
import '../../../utils/upi_launcher.dart';
import '../../../utils/upi_link_builder.dart';
import '../../providers/auth_providers.dart';
import '../../providers/support_providers.dart';

/// Bottom sheet that lets a reader pay an author directly via UPI and then
/// record "I've paid" so they appear in the author's supporters list.
Future<void> showSupportAuthorSheet(
  BuildContext context, {
  required String authorId,
  required String authorName,
  required AuthorSupport support,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => SupportAuthorSheet(
      authorId: authorId,
      authorName: authorName,
      support: support,
    ),
  );
}

class SupportAuthorSheet extends ConsumerStatefulWidget {
  const SupportAuthorSheet({
    super.key,
    required this.authorId,
    required this.authorName,
    required this.support,
  });

  final String authorId;
  final String authorName;
  final AuthorSupport support;

  @override
  ConsumerState<SupportAuthorSheet> createState() => _SupportAuthorSheetState();
}

class _SupportAuthorSheetState extends ConsumerState<SupportAuthorSheet> {
  static const _presetAmounts = [20, 50, 100, 200];

  final _customController = TextEditingController();
  final _utrController = TextEditingController();
  bool _showQr = false;
  bool _submitting = false;

  @override
  void dispose() {
    _customController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  int? get _amount {
    final value = int.tryParse(_customController.text.trim());
    return value != null && value > 0 ? value : null;
  }

  String get _upiLink => UpiLinkBuilder.build(
    vpa: widget.support.upiId,
    payeeName: widget.authorName,
    amountInr: _amount,
  );

  Future<void> _payWithUpiApp() async {
    final l10n = AppLocalizations.of(context)!;
    final launched = await UpiLauncher.pay(_upiLink);
    if (!mounted || launched) return;
    setState(() => _showQr = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.supportNoUpiApp)));
  }

  Future<void> _copyUpiId() async {
    await Clipboard.setData(ClipboardData(text: widget.support.upiId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.supportUpiIdCopied)),
    );
  }

  Future<void> _submitClaim() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.pleaseSignIn)));
      return;
    }
    final utrInput = _utrController.text.trim();
    final utr = UpiLinkBuilder.normalizeUtr(utrInput);
    if (utrInput.isNotEmpty && utr == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.supportInvalidUtr)));
      return;
    }
    final displayName = (user.displayName ?? '').trim();
    final name = displayName.isNotEmpty ? displayName : user.username;

    setState(() => _submitting = true);
    try {
      await ref
          .read(supportRepositoryProvider)
          .submitClaim(
            authorId: widget.authorId,
            supporterId: user.id,
            supporterName: name,
            supporterPhotoURL: user.photoURL,
            utr: utr,
            amount: _amount,
          );
      ref.invalidate(supportClaimsProvider(widget.authorId));
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.supportClaimSent)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.supportClaimFailed)));
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.supportAuthorTitle(widget.authorName),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(l10n.supportDirectNote, style: theme.textTheme.bodySmall),
          if ((widget.support.message ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.support.message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.supportChooseAmount, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in _presetAmounts)
                ChoiceChip(
                  label: Text('₹$amount'),
                  selected: _amount == amount,
                  onSelected: (_) => setState(() {
                    _customController.value = TextEditingValue(
                      text: '$amount',
                      selection: TextSelection.collapsed(
                        offset: '$amount'.length,
                      ),
                    );
                  }),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              labelText: l10n.supportCustomAmount,
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _payWithUpiApp,
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: Text(l10n.supportPayWithUpi),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showQr = !_showQr),
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(l10n.supportShowQr),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyUpiId,
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(l10n.supportCopyUpiId),
                ),
              ),
            ],
          ),
          if (_showQr) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: _upiLink,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.supportQrHint}\n${widget.support.upiId}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const Divider(height: 32),
          Text(l10n.supportIPaidHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          TextField(
            controller: _utrController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            decoration: InputDecoration(
              labelText: l10n.supportUtrLabel,
              helperText: l10n.supportUtrHelper,
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _submitting ? null : _submitClaim,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(l10n.supportIPaid),
          ),
        ],
      ),
    );
  }
}
