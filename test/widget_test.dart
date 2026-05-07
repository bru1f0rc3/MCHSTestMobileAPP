import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('MaterialApp builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('MCHS'))),
    );

    expect(find.text('MCHS'), findsOneWidget);
  });
}
