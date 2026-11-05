import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/components/reader/reader_line_snapper.dart';

void main() {
  testWidgets('forward snap lands on a line top; backward returns before it',
      (tester) async {
    final controller = ScrollController();
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            key: key,
            height: 405, // not a multiple of line height -> half-cut line
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  for (var i = 0; i < 100; i++)
                    SizedBox(
                      height: 30,
                      child: Text('line $i', style: const TextStyle(height: 1.0, fontSize: 20)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final fwd = snapTurnTarget(
      scrollContext: key.currentContext!,
      position: controller.position,
      forward: true,
      insets: EdgeInsets.zero,
    );
    expect(fwd, isNotNull);
    expect(fwd! % 30, closeTo(0, 8)); // aligned to a row, not 405*.9
    expect(fwd, lessThanOrEqualTo(405));
    controller.jumpTo(fwd);
    await tester.pump();
    final back = snapTurnTarget(
      scrollContext: key.currentContext!,
      position: controller.position,
      forward: false,
      insets: EdgeInsets.zero,
    );
    expect(back, isNotNull);
    expect(back!, lessThan(fwd));
  });
}
