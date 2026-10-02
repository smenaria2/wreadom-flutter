import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/models/app_runtime_config.dart';
import 'book_providers.dart';

/// Live `settings/app_runtime`. Any failure means "no restrictions", so a
/// missing document or a read error never locks users out.
final appRuntimeConfigProvider = StreamProvider<AppRuntimeConfig>((ref) {
  return FirebaseFirestore.instance
      .collection('settings')
      .doc('app_runtime')
      .snapshots()
      .map((doc) => AppRuntimeConfig.fromMap(doc.data()))
      .handleError((Object error) {
        debugPrint('[appRuntimeConfigProvider] $error');
      });
});

final installedBuildNumberProvider = FutureProvider<int>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return int.tryParse(info.buildNumber) ?? 0;
});

final appRuntimeBlockProvider = Provider<AppRuntimeBlock>((ref) {
  final config = ref.watch(appRuntimeConfigProvider).value;
  if (config == null) return AppRuntimeBlock.none;
  return appRuntimeBlockFor(
    config: config,
    installedBuild: ref.watch(installedBuildNumberProvider).value ?? 0,
    isAndroid: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
    isWeb: kIsWeb,
    isAdmin: ref.watch(currentUserAdminClaimProvider).value ?? false,
  );
});
