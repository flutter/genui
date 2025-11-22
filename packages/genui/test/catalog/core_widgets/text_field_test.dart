// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('TextField renders and handles changes/submissions', (
    WidgetTester tester,
  ) async {
    ChatMessage? message;
    final manager = GenUiManager(
      catalog: Catalog([CoreCatalogItems.textField]),
      configuration: const GenUiConfiguration(),
    );
    manager.onSubmit.listen((event) => message = event);
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        props: {
          'component': 'TextField',
          'text': {'path': '/myValue'},
          'label': {'literalString': 'My Label'},
          'onSubmittedAction': {'name': 'submit'},
        },
      ),
    ];
    manager.handleMessage(
      SurfaceUpdate(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(const CreateSurface(surfaceId: surfaceId));
    manager
        .dataModelForSurface(surfaceId)
        .update(DataPath('/myValue'), 'initial');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder textFieldFinder = find.byType(TextField);
    expect(find.widgetWithText(TextField, 'initial'), findsOneWidget);
    final TextField textField = tester.widget<TextField>(textFieldFinder);
    expect(textField.decoration?.labelText, 'My Label');

    // Test onChanged
    await tester.enterText(textFieldFinder, 'new value');
    expect(
      manager
          .dataModelForSurface(surfaceId)
          .getValue<String>(DataPath('/myValue')),
      'new value',
    );

    // Test onSubmitted
    expect(message, null);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(message, isNotNull);
  });
}
