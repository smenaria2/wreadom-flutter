import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/components/reader/reader_page_gestures.dart';

void main() {
  late ScrollController controller;
  late SharedPreferences prefs;
  late StateSetter rebuild;
  var enabled = true, blocked = false, ready = true, reducedMotion = false;
  var selected = false, dark = false;
  var contentHeight = 3000.0, height = 600.0, textScale = 1.0;
  var actions = 0, progressEvents = 0, toggles = 0;
  var chromeVisible = true;
  var locale = const Locale('en');

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      readerPageGestureGuideSeenKey: true,
    });
    prefs = await SharedPreferences.getInstance();
    controller = ScrollController()..addListener(() => progressEvents++);
    enabled = ready = true;
    blocked = reducedMotion = selected = dark = false;
    contentHeight = 3000;
    height = 600;
    textScale = 1;
    actions = progressEvents = toggles = 0;
    chromeVisible = true;
    locale = const Locale('en');
  });
  tearDown(() => controller.dispose());

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: reducedMotion,
                  textScaler: TextScaler.linear(textScale),
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 400,
                    height: height,
                    child: ReaderPageGestures(
                      onToggleChrome: () => rebuild(() {
                        toggles++;
                        chromeVisible = !chromeVisible;
                      }),
                      controller: controller,
                      preferences: prefs,
                      enabled: enabled,
                      ready: ready,
                      blocked: blocked || selected,
                      obscuredInsets: const EdgeInsets.only(
                        top: 50,
                        bottom: 50,
                      ),
                      selectionWrapper: (content) => SelectionArea(
                        onSelectionChanged: (value) => rebuild(
                          () => selected =
                              value != null && value.plainText.isNotEmpty,
                        ),
                        child: content,
                      ),
                      child: SingleChildScrollView(
                        controller: controller,
                        child: SizedBox(
                          height: contentHeight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 80),
                              TextButton(
                                onPressed: () => actions++,
                                child: const Text('Link / control'),
                              ),
                              const Text(
                                'Selectable reader text across the page',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(
    WidgetTester tester, [
    Offset point = const Offset(380, 300),
  ]) async {
    await tester.tapAt(point);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'edge taps move 90% of clear viewport and clamp to chapter bounds',
    (tester) async {
      await mount(tester);
      await tap(tester);
      expect(controller.offset, 450);
      expect(progressEvents, greaterThan(0));
      await tap(tester, const Offset(200, 300));
      expect(controller.offset, 450);
      await tap(tester, const Offset(20, 300));
      expect(controller.offset, 0);
      await tap(tester, const Offset(20, 300));
      expect(controller.offset, 0);
      controller.jumpTo(controller.position.maxScrollExtent - 10);
      await tap(tester);
      expect(controller.offset, controller.position.maxScrollExtent);
    },
  );
  testWidgets('edge drags scroll and controls win taps', (tester) async {
    await mount(tester);
    await tap(tester, const Offset(380, 100));
    expect(actions, 1);
    expect(controller.offset, 0);
    await tester.dragFrom(const Offset(20, 400), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    expect(controller.offset, lessThan(200));
    expect(toggles, 0);
  });
  testWidgets('disabled unready blocked and toolbar taps do not turn pages', (
    tester,
  ) async {
    await mount(tester);
    for (final change in <VoidCallback>[
      () => enabled = false,
      () {
        enabled = true;
        ready = false;
      },
      () {
        ready = true;
        blocked = true;
      },
    ]) {
      rebuild(change);
      await tester.pump();
      await tap(tester);
      expect(controller.offset, 0);
    }
    rebuild(() => blocked = false);
    await tester.pump();
    await tap(tester, const Offset(380, 20));
    expect(controller.offset, 0);
    await tap(tester);
    expect(controller.offset, 450);
  });
  testWidgets('guide consumes dismissal and stays dismissed across remounts', (
    tester,
  ) async {
    await prefs.remove(readerPageGestureGuideSeenKey);
    await mount(tester);
    expect(find.byKey(const Key('reader-gesture-guide')), findsOneWidget);
    await tap(tester);
    expect(controller.offset, 0);
    expect(prefs.getBool(readerPageGestureGuideSeenKey), isTrue);
    await tester.pumpWidget(const SizedBox());
    await mount(tester);
    expect(find.byKey(const Key('reader-gesture-guide')), findsNothing);
    expect(toggles, 0);
  });
  testWidgets('disabled guide returns on enable unless dismissed', (
    tester,
  ) async {
    await prefs.remove(readerPageGestureGuideSeenKey);
    await mount(tester);
    rebuild(() => enabled = false);
    await tester.pump();
    expect(find.byKey(const Key('reader-gesture-guide')), findsNothing);
    expect(prefs.getBool(readerPageGestureGuideSeenKey), isNull);
    rebuild(() => enabled = true);
    await tester.pump();
    expect(find.byKey(const Key('reader-gesture-guide')), findsOneWidget);
  });
  testWidgets('repeat taps ignored and disabling stops active animation', (
    tester,
  ) async {
    await mount(tester);
    await tester.tapAt(const Offset(380, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tap(tester);
    expect(controller.offset, 450);
    await tester.tapAt(const Offset(380, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    rebuild(() => enabled = false);
    await tester.pump();
    final stopped = controller.offset;
    await tester.pumpAndSettle();
    expect(controller.offset, stopped);
    expect(stopped, lessThan(900));
  });
  testWidgets('resizing reduced motion and short content', (tester) async {
    reducedMotion = true;
    height = 400;
    await mount(tester);
    await tester.tapAt(const Offset(380, 250));
    expect(controller.offset, 270);
    rebuild(() => height = 500);
    await tester.pump();
    await tester.tapAt(const Offset(380, 250));
    expect(controller.offset, 630);
    rebuild(() => contentHeight = 200);
    await tester.pumpAndSettle();
    await tap(tester, const Offset(380, 250));
    expect(controller.offset, 0);
  });
  testWidgets('modal routes suppress guide and page taps', (tester) async {
    await prefs.remove(readerPageGestureGuideSeenKey);
    await mount(tester);
    showDialog<void>(
      context: tester.element(find.byType(ReaderPageGestures)),
      builder: (_) => const AlertDialog(content: Text('Modal')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reader-gesture-guide')), findsNothing);
    await tap(tester);
    expect(controller.offset, 0);
    expect(toggles, 0);
  });
  testWidgets('long press selects text and selected text blocks taps', (
    tester,
  ) async {
    await mount(tester);
    await tester.longPressAt(
      tester.getTopLeft(find.text('Selectable reader text across the page')) +
          const Offset(25, 8),
    );
    await tester.pumpAndSettle();
    expect(selected, isTrue);
    expect(controller.offset, 0);
    await tap(tester);
    expect(controller.offset, 0);
    expect(toggles, 0);
  });
  testWidgets('single edge taps on selectable paragraphs turn pages', (
    tester,
  ) async {
    await mount(tester);
    final point = tester.getTopLeft(
      find.text('Selectable reader text across the page'),
    );
    await tap(tester, point + const Offset(25, 8));
    expect(selected, isFalse);
    expect(controller.offset, 0);
    await tap(tester, Offset(380, point.dy + 8));
    expect(controller.offset, 450);
  });
  testWidgets('wheel and drag interruption do not add page turns', (
    tester,
  ) async {
    await mount(tester);
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(380, 300),
        scrollDelta: Offset(0, 100),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.offset, 100);
    await tester.tapAt(const Offset(380, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.dragFrom(const Offset(20, 300), const Offset(0, 80));
    await tester.pumpAndSettle();
    expect(controller.offset, lessThan(550));
    expect(toggles, 0);
  });
  testWidgets('Hindi dark guide supports large text on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await prefs.remove(readerPageGestureGuideSeenKey);
    textScale = 2;
    dark = true;
    locale = const Locale('hi');
    await mount(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('reader-gesture-guide')), findsOneWidget);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ReaderPageGestures)),
    )!;
    expect(find.text(l10n.readerSwipeToScroll), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp(RegExp.escape(l10n.readerGestureDismiss))),
      findsOneWidget,
    );
    semantics.dispose();
  });
  testWidgets(
    'center text taps toggle bars without moving or saving progress',
    (tester) async {
      await mount(tester);
      final textTop = tester
          .getTopLeft(find.text('Selectable reader text across the page'))
          .dy;
      await tap(tester, Offset(200, textTop + 8));
      expect(chromeVisible, isFalse);
      expect(toggles, 1);
      expect(controller.offset, 0);
      expect(progressEvents, 0);
      await tap(tester, const Offset(200, 300));
      expect(chromeVisible, isTrue);
      expect(toggles, 2);
      expect(controller.offset, 0);
      expect(progressEvents, 0);
    },
  );

  testWidgets('edge page taps never toggle bars including boundaries', (
    tester,
  ) async {
    await mount(tester);
    for (final visible in [true, false]) {
      rebuild(() => chromeVisible = visible);
      await tester.pump();
      await tap(tester, const Offset(20, 300));
      expect(chromeVisible, visible);
      await tap(tester);
      expect(chromeVisible, visible);
      await tap(tester, const Offset(20, 300));
      expect(controller.offset, 0);
      expect(chromeVisible, visible);
      controller.jumpTo(controller.position.maxScrollExtent);
      await tap(tester);
      expect(chromeVisible, visible);
      controller.jumpTo(0);
    }
    expect(toggles, 0);
  });

  testWidgets('disabled page setting allows both edges to toggle bars', (
    tester,
  ) async {
    enabled = false;
    await mount(tester);
    await tap(tester);
    expect(chromeVisible, isFalse);
    await tap(tester, const Offset(20, 300));
    expect(chromeVisible, isTrue);
    expect(toggles, 2);
    expect(controller.offset, 0);
  });

  testWidgets('blocked unready and selected content cannot toggle bars', (
    tester,
  ) async {
    await mount(tester);
    for (final change in <VoidCallback>[
      () => ready = false,
      () {
        ready = true;
        blocked = true;
      },
      () {
        blocked = false;
        selected = true;
      },
    ]) {
      rebuild(change);
      await tester.pump();
      await tap(tester, const Offset(200, 300));
      expect(toggles, 0);
    }
  });
}
