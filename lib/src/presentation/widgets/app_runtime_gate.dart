import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/app_runtime_config.dart';
import '../../localization/generated/app_localizations.dart';
import '../providers/app_runtime_provider.dart';
import '../providers/app_update_provider.dart';

/// Covers every screen, including pushed routes, with a blocking page while
/// `settings/app_runtime` puts the app in maintenance or requires an update.
/// The navigator stays mounted underneath, so nothing is lost when it lifts.
class AppRuntimeGate extends ConsumerStatefulWidget {
  const AppRuntimeGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppRuntimeGate> createState() => _AppRuntimeGateState();
}

class _AppRuntimeGateState extends ConsumerState<AppRuntimeGate>
    with WidgetsBindingObserver {
  bool _working = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(installedBuildNumberProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final block = ref.watch(appRuntimeBlockProvider);
    if (block == AppRuntimeBlock.none) return widget.child;
    final config = ref.watch(appRuntimeConfigProvider).value;
    return Stack(
      children: [
        ExcludeFocus(child: widget.child),
        Positioned.fill(
          child: _BlockingPage(
            block: block,
            message: config?.maintenanceMessage ?? '',
            working: _working,
            onUpdate: _update,
          ),
        ),
      ],
    );
  }

  Future<void> _update() async {
    setState(() => _working = true);
    try {
      if (kIsWeb) {
        await launchUrl(Uri.base, webOnlyWindowName: '_self');
        return;
      }
      final completed = await ref
          .read(playStoreUpdateServiceProvider)
          .performImmediateUpdate();
      if (completed) return;
      final info = await PackageInfo.fromPlatform();
      await launchUrl(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=${info.packageName}',
        ),
        mode: LaunchMode.externalApplication,
      );
    } catch (error) {
      debugPrint('[AppRuntimeGate] update failed: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}

class _BlockingPage extends StatelessWidget {
  const _BlockingPage({
    required this.block,
    required this.message,
    required this.working,
    required this.onUpdate,
  });

  final AppRuntimeBlock block;
  final String message;
  final bool working;
  final Future<void> Function() onUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMaintenance = block == AppRuntimeBlock.maintenance;
    return PopScope(
      canPop: false,
      child: Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMaintenance
                          ? Icons.construction_rounded
                          : Icons.system_update_alt_rounded,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isMaintenance ? l10n.maintenanceTitle : l10n.updateApp,
                      key: const ValueKey('app-runtime-gate-title'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isMaintenance
                          ? (message.isNotEmpty
                                ? message
                                : l10n.maintenanceDefaultMessage)
                          : l10n.updateRequiredMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (!isMaintenance) ...[
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: working
                              ? null
                              : () => unawaited(onUpdate()),
                          icon: Icon(
                            kIsWeb
                                ? Icons.refresh_rounded
                                : Icons.download_rounded,
                          ),
                          label: Text(
                            kIsWeb ? l10n.reloadAction : l10n.updateAction,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
