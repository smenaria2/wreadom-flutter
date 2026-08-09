import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_providers.g.dart';

final appFullyLoadedProvider = NotifierProvider<AppFullyLoadedNotifier, bool>(
  AppFullyLoadedNotifier.new,
);

class AppFullyLoadedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoaded(bool loaded) => state = loaded;
}

@riverpod
class SelectedTab extends _$SelectedTab {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

@riverpod
class ProfileTabIndex extends _$ProfileTabIndex {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}
