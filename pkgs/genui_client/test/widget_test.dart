import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/main.dart';

void main() {
  testWidgets('MyHomePage shows connecting status initially',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MyHomePage(connect: () {})));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Connecting...'), findsOneWidget);
  });
}
