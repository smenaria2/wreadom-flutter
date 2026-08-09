import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../localization/generated/app_localizations.dart';
import '../providers/app_update_provider.dart';

class CompulsoryUpdateGate extends ConsumerStatefulWidget {
  const CompulsoryUpdateGate({
    super.key,
    required this.child,
    @visibleForTesting this.isAndroidOverride,
  });

  final Widget child;
  final bool? isAndroidOverride;

  @override
  ConsumerState<CompulsoryUpdateGate> createState() =>
      _CompulsoryUpdateGateState();
}

class _CompulsoryUpdateGateState extends ConsumerState<CompulsoryUpdateGate>
    with WidgetsBindingObserver {
  bool _updating = false;

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
      ref.invalidate(appUpdateAvailabilityProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid =
        widget.isAndroidOverride ??
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
    if (!isAndroid) {
      return widget.child;
    }
    final update = ref.watch(appUpdateAvailabilityProvider);
    return update.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => widget.child,
      data: (availability) {
        if (availability == null || !availability.isCompulsory) {
          return widget.child;
        }
        return _buildCompulsoryUpdateScreen(context, availability);
      },
    );
  }

  Widget _buildCompulsoryUpdateScreen(
    BuildContext context,
    AppUpdateAvailability availability,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.system_update_alt_rounded,
                      size: 72,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.updateApp,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.appUpdateAvailable,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.latestBuild(availability.config.androidBuildNumber),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _updating
                            ? null
                            : () => unawaited(_update(availability)),
                        icon: _updating
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                        label: Text(l10n.updateAction),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _updating
                          ? null
                          : () => ref.invalidate(appUpdateAvailabilityProvider),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _update(AppUpdateAvailability availability) async {
    setState(() => _updating = true);
    try {
      var completed = false;
      if (availability.immediateUpdateAllowed) {
        completed = await ref
            .read(playStoreUpdateServiceProvider)
            .performImmediateUpdate();
      }

      if (!completed) {
        final uri = Uri.tryParse(availability.config.androidDownloadUrl);
        var opened = false;
        if (uri != null) {
          try {
            opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            opened = false;
          }
        }
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                uri == null
                    ? AppLocalizations.of(context)!.invalidUpdateLink
                    : AppLocalizations.of(context)!.couldNotOpenUpdateLink,
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
        ref.invalidate(appUpdateAvailabilityProvider);
      }
    }
  }
}
