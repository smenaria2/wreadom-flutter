import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/components/writer_topic_input.dart';
import 'package:librebook_flutter/src/presentation/providers/topic_tag_providers.dart';

void main() {
  test('topic cleaning removes reserved punctuation and normalizes spaces', () {
    expect(cleanTopicTag(' _#Magic__Realism" '), 'Magic Realism');
    expect(normalizeTopicTag('_#MAGIC__REALISM"'), 'magic realism');
  });
  Widget app(TextEditingController controller) {
    return ProviderScope(
      overrides: [
        popularTopicTagsProvider.overrideWith((ref) async {
          return const ['Love', 'Poetry', 'Life'];
        }),
        topicTagSuggestionsProvider.overrideWith((ref, query) async {
          return query.toLowerCase().startsWith('sur')
              ? const ['Survival', 'Surrealism']
              : const [];
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WriterTopicInput(
            controller: controller,
            label: 'Topics',
            hint: 'Type a topic',
          ),
        ),
      ),
    );
  }

  testWidgets('create action is first and commits a new topic', (tester) async {
    final controller = TextEditingController(text: 'Magic');
    addTearDown(controller.dispose);
    await tester.pumpWidget(app(controller));

    await tester.enterText(
      find.byKey(const ValueKey('writer-topic-input')),
      'Sur',
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('create-writer-topic')), findsOneWidget);
    expect(find.text('Survival'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('create-writer-topic')));
    await tester.pump();

    expect(controller.text, 'Magic, Sur');
    expect(find.byKey(const ValueKey('writer-topic-Sur')), findsOneWidget);
  });

  testWidgets('suggestion reuses canonical name and blocks duplicates', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Magic');
    addTearDown(controller.dispose);
    await tester.pumpWidget(app(controller));

    final input = find.byKey(const ValueKey('writer-topic-input'));
    await tester.enterText(input, 'sur');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.byKey(const ValueKey('suggested-writer-topic-Survival')),
    );
    await tester.pump();

    expect(controller.text, 'Magic, Survival');

    await tester.enterText(input, ' survival ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.text, 'Magic, Survival');
  });

  testWidgets('Hindi create tap commits before focus changes', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(app(controller));

    await tester.enterText(
      find.byKey(const ValueKey('writer-topic-input')),
      'प्रेम',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('create-writer-topic')));
    await tester.pump();

    expect(controller.text, 'प्रेम');
    expect(find.byKey(const ValueKey('writer-topic-प्रेम')), findsOneWidget);
  });

  testWidgets('focus shows most-used topics instead of a static example', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(app(controller));

    await tester.tap(find.byKey(const ValueKey('writer-topic-input')));
    await tester.pump();

    expect(find.text('Popular topics'), findsOneWidget);
    expect(find.text('Love'), findsOneWidget);
    expect(find.text('Poetry'), findsOneWidget);
    expect(find.text('Life'), findsOneWidget);
  });
}
