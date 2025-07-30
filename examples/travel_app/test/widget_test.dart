import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/app.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
  });
}
