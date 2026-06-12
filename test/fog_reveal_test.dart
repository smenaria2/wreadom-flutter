import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/components/generated_book_cover.dart';
import 'package:librebook_flutter/src/presentation/widgets/fog_reveal.dart';

void main() {
  testWidgets('FogReveal shows fog while unrevealed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 120,
            child: FogReveal(
              revealed: false,
              child: ColoredBox(color: Colors.red),
            ),
          ),
        ),
      ),
    );

    final overlay = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('fog-reveal-overlay')),
    );
    expect(overlay.opacity, 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('FogReveal clears fog when revealed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 120,
            child: FogReveal(
              revealed: true,
              child: ColoredBox(color: Colors.red),
            ),
          ),
        ),
      ),
    );

    final overlay = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('fog-reveal-overlay')),
    );
    expect(overlay.opacity, 0);
  });

  testWidgets('FogReveal animates mist by default', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 120,
            child: FogReveal(
              revealed: false,
              child: ColoredBox(color: Colors.red),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('fog-reveal-animated-mist')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'FogReveal suppresses mist animation when animations are disabled',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: SizedBox(
                width: 160,
                height: 120,
                child: FogReveal(
                  revealed: false,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('fog-reveal-animated-mist')),
        findsNothing,
      );
    },
  );

  testWidgets('Generated fallback cover can render with fog cleared', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 180,
            child: FogReveal(
              revealed: true,
              child: GeneratedBookCover(
                title: 'Foggy Tales',
                author: 'Wreadom',
                seed: 'foggy-tales',
                compact: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GeneratedBookCover), findsOneWidget);
    final overlay = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('fog-reveal-overlay')),
    );
    expect(overlay.opacity, 0);
  });
}
