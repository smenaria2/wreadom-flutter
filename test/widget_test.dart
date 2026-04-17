import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/screens/static_info_screen.dart';

void main() {
  testWidgets('static info screen renders title and body', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StaticInfoScreen(
          title: 'Wreadom',
          body: 'Read, write, and share books.',
        ),
      ),
    );

    expect(find.text('Wreadom'), findsOneWidget);
    expect(find.text('Read, write, and share books.'), findsOneWidget);
  });
}
