import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/catalog/core_widgets/choice_picker.dart';

void main() {
  // Test case based on jobApplication.1.sample
  testWidgets(
    'ChoicePicker mutuallyExclusive handles single String value in DataModel',
    (WidgetTester tester) async {
      final catalog = Catalog([choicePicker], catalogId: 'test');

      // Create a controller with a catalog that has ChoicePicker
      final controller = GenUiController(catalogs: [catalog]);

      // Initial message to create surface and components
      final createSurface = const CreateSurface(
        surfaceId: 'test',
        catalogId: 'test',
      );

      final updateData = const UpdateDataModel(
        surfaceId: 'test',
        value: {
          'experience': '2-5', // Single string value, not a list
        },
        path: DataPath.root,
      );

      final updateComponents = const UpdateComponents(
        surfaceId: 'test',
        components: [
          Component(
            id: 'root',
            type: 'ChoicePicker',
            properties: {
              'label': 'Years of Experience',
              'variant': 'mutuallyExclusive',
              'options': [
                {'label': '0-1', 'value': '0-1'},
                {'label': '2-5', 'value': '2-5'},
                {'label': '5+', 'value': '5+'},
              ],
              'value': {'path': '/experience'},
            },
          ),
        ],
      );

      controller.handleMessage(createSurface);
      controller.handleMessage(updateData);
      controller.handleMessage(updateComponents);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenUiSurface(genUiContext: controller.contextFor('test')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify it rendered
      expect(find.text('Years of Experience'), findsOneWidget);
      expect(find.text('0-1'), findsOneWidget);
      expect(find.text('2-5'), findsOneWidget);

      // Verify selection (RadioListTile)
      // We check if the radio button corresponding to '2-5' is selected.
      // In Flutter RadioListTile, we can find the Radio widget.

      final Iterable<Radio<String>> radios = tester.widgetList<Radio<String>>(
        find.byType(Radio<String>),
      );
      expect(radios.length, 3);

      // The second radio should be selected
      final Radio<String> selectedRadio = radios.elementAt(1);
      expect(selectedRadio.value, '2-5');
      expect(
        // ignore: deprecated_member_use
        selectedRadio.groupValue,
        '2-5',
        reason: 'Group value should match the selected choice',
      );

      // Update data model to another single string
      controller.handleMessage(
        UpdateDataModel(
          surfaceId: 'test',
          path: DataPath('/experience'),
          value: '5+',
        ),
      );
      await tester.pumpAndSettle();

      final Iterable<Radio<String>> radiosAfter = tester
          .widgetList<Radio<String>>(find.byType(Radio<String>));
      // ignore: deprecated_member_use
      expect(radiosAfter.elementAt(2).groupValue, '5+');
    },
  );

  testWidgets('ChoicePicker multipleSelection handles List value', (
    WidgetTester tester,
  ) async {
    final catalog = Catalog([choicePicker], catalogId: 'std');

    final controller = GenUiController(catalogs: [catalog]);

    final createSurface = const CreateSurface(
      surfaceId: 'test2',
      catalogId: 'std',
    );
    final updateData = const UpdateDataModel(
      surfaceId: 'test2',
      value: {
        'selections': ['A', 'B'],
      },
      path: DataPath.root,
    );
    final updateComponents = const UpdateComponents(
      surfaceId: 'test2',
      components: [
        Component(
          id: 'root',
          type: 'ChoicePicker',
          properties: {
            'label': 'Multi',
            'variant': 'multipleSelection',
            'options': [
              {'label': 'A', 'value': 'A'},
              {'label': 'B', 'value': 'B'},
              {'label': 'C', 'value': 'C'},
            ],
            'value': {'path': '/selections'},
          },
        ),
      ],
    );

    controller.handleMessage(createSurface);
    controller.handleMessage(updateData);
    controller.handleMessage(updateComponents);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(genUiContext: controller.contextFor('test2')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Multi'), findsOneWidget);

    // Verify Checkboxes
    final Iterable<Checkbox> checkboxes = tester.widgetList<Checkbox>(
      find.byType(Checkbox),
    );
    expect(checkboxes.length, 3);

    expect(checkboxes.elementAt(0).value, true); // A
    expect(checkboxes.elementAt(1).value, true); // B
    expect(checkboxes.elementAt(2).value, false); // C
  });
}
