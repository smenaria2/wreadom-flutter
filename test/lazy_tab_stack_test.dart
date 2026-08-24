import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/screens/main_navigation_shell.dart';

void main() {
  testWidgets('tabs mount once on selection and remain alive', (tester) async {
    final mounted = <String>[];
    final disposed = <String>[];

    Widget app(int index) => MaterialApp(
      home: LazyStatePreservingTabStack(
        index: index,
        children: [
          _LifecycleProbe('home', mounted, disposed),
          _LifecycleProbe('feed', mounted, disposed),
          _LifecycleProbe('writer', mounted, disposed),
        ],
      ),
    );

    await tester.pumpWidget(app(0));
    expect(mounted, ['home']);
    expect(disposed, isEmpty);

    await tester.pumpWidget(app(2));
    expect(mounted, ['home', 'writer']);
    expect(disposed, isEmpty);

    await tester.pumpWidget(app(0));
    expect(mounted, ['home', 'writer']);
    expect(disposed, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(disposed, containsAll(['home', 'writer']));
    expect(mounted, isNot(contains('feed')));
  });
}

class _LifecycleProbe extends StatefulWidget {
  const _LifecycleProbe(this.name, this.mounted, this.disposed);

  final String name;
  final List<String> mounted;
  final List<String> disposed;

  @override
  State<_LifecycleProbe> createState() => _LifecycleProbeState();
}

class _LifecycleProbeState extends State<_LifecycleProbe> {
  @override
  void initState() {
    super.initState();
    widget.mounted.add(widget.name);
  }

  @override
  void dispose() {
    widget.disposed.add(widget.name);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(widget.name);
}
