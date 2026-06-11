import 'package:flutter/material.dart';

import 'app_background.dart';
import 'glass_surface.dart';

class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          Positioned.fill(child: body),
        ],
      ),
    );
  }
}

AppBar glassAppBar({
  required Widget title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
  Widget? leading,
  bool automaticallyImplyLeading = true,
  bool centerTitle = false,
}) {
  return AppBar(
    title: title,
    actions: actions,
    bottom: bottom,
    leading: leading,
    automaticallyImplyLeading: automaticallyImplyLeading,
    centerTitle: centerTitle,
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    flexibleSpace: const GlassSurface(
      strong: true,
      borderRadius: BorderRadius.zero,
      child: SizedBox.expand(),
    ),
  );
}

SliverAppBar glassSliverAppBar({
  required Widget title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
  bool floating = false,
  bool snap = false,
  bool pinned = false,
  double? expandedHeight,
  FlexibleSpaceBar? flexibleSpaceBar,
}) {
  return SliverAppBar(
    title: title,
    actions: actions,
    bottom: bottom,
    floating: floating,
    snap: snap,
    pinned: pinned,
    expandedHeight: expandedHeight,
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    flexibleSpace:
        flexibleSpaceBar ??
        const GlassSurface(
          strong: true,
          borderRadius: BorderRadius.zero,
          child: SizedBox.expand(),
        ),
  );
}
