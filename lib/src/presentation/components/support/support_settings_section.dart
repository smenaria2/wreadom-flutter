import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../utils/upi_link_builder.dart';
import '../../providers/support_providers.dart';
import '../../widgets/glass_surface.dart';

/// Profile-settings card where an author turns on UPI support. It saves on
/// its own so it does not interfere with the main profile save.
class SupportSettingsSection extends ConsumerStatefulWidget {
  const SupportSettingsSection({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<SupportSettingsSection> createState() =>
      _SupportSettingsSectionState();
}

class _SupportSettingsSectionState
    extends ConsumerState<SupportSettingsSection> {
  final _upiController = TextEditingController();
  final _messageController = TextEditingController();
  bool _enabled = false;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _upiController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final support = await ref
          .read(supportRepositoryProvider)
          .getAuthorSupport(widget.userId);
      if (!mounted) return;
      setState(() {
        _upiController.text = support?.upiId ?? '';
        _messageController.text = support?.message ?? '';
        _enabled = support?.enabled ?? false;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(supportRepositoryProvider);
    final input = _upiController.text.trim();
    final vpa = UpiLinkBuilder.normalizeVpa(input);

    if (input.isNotEmpty && vpa == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.supportInvalidUpiId)));
      return;
    }
    if (_enabled && vpa == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.supportInvalidUpiId)));
      return;
    }

    setState(() => _saving = true);
    try {
      if (vpa == null) {
        await repository.clearAuthorSupport(widget.userId);
      } else {
        await repository.saveAuthorSupport(
          authorId: widget.userId,
          upiId: vpa,
          enabled: _enabled,
          message: _messageController.text,
        );
      }
      ref.invalidate(authorSupportProvider(widget.userId));
      messenger.showSnackBar(SnackBar(content: Text(l10n.supportSaved)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.supportClaimFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return GlassSurface(
      strong: true,
      padding: const EdgeInsets.all(16),
      child: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.supportSettingsTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.supportSettingsEnable),
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                ),
                if (_enabled) ...[
                  TextField(
                    controller: _upiController,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.supportUpiIdLabel,
                      helperText: l10n.supportUpiIdHelper,
                      helperMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    maxLength: 140,
                    decoration: InputDecoration(
                      labelText: l10n.supportMessageLabel,
                    ),
                  ),
                  Text(
                    l10n.supportBusinessNote,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.supportSave),
                  ),
                ),
              ],
            ),
    );
  }
}
