import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_providers.g.dart';

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
