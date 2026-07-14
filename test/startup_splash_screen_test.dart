import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/screens/startup_splash_screen.dart';

void main() {
  testWidgets('startup splash finishes exactly once', (tester) async {
    var finishCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          child: StartupSplashScreen(onFinished: () => finishCount += 1),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(finishCount, 1);

    await tester.pump(const Duration(seconds: 5));

    expect(finishCount, 1);
  });
}
