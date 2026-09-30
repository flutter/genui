// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'test_infra/message_builders.dart';

void main() {
  group('Validation Integration Tests (reproducing issue 2853)', () {
    testWidgets(
      'full form with CheckBox, Slider, ChoicePicker, TextField and Button '
      'validates rules, displays error messages, and updates Button state',
      (WidgetTester tester) async {
        final surfaceController = SurfaceController(
          catalogs: [BasicCatalogItems.asCatalog()],
        );
        addTearDown(surfaceController.dispose);
        const surfaceId = 'validationFormSurface';

        // Initial invalid data model state:
        // /email is empty string
        // /termsAccepted is false
        // /rating is 1.0 (fails minimum of 3.0)
        // /plan is empty string
        surfaceController.handleMessage(
          updateDataModel(
            surfaceId: surfaceId,
            path: DataPath.root,
            value: {
              'email': '',
              'termsAccepted': false,
              'rating': 1.0,
              'plan': '',
            },
          ),
        );

        final List<JsonMap> components = [
          component(
            id: 'root',
            type: 'Column',
            properties: {
              'children': [
                'emailField',
                'termsCheckBox',
                'ratingSlider',
                'planPicker',
                'submitButton',
              ],
            },
          ),
          component(
            id: 'emailField',
            type: 'TextField',
            properties: {
              'label': 'Email Address',
              'value': {'path': '/email'},
              'checks': [
                {
                  'message': 'Email is required.',
                  'condition': {
                    'call': 'required',
                    'args': {
                      'value': {'path': '/email'},
                    },
                  },
                },
              ],
            },
          ),
          component(
            id: 'termsCheckBox',
            type: 'CheckBox',
            properties: {
              'label': 'Accept Terms',
              'value': {'path': '/termsAccepted'},
              'checks': [
                {
                  'message': 'You must accept the terms.',
                  'condition': {'path': '/termsAccepted'},
                },
              ],
            },
          ),
          component(
            id: 'ratingSlider',
            type: 'Slider',
            properties: {
              'label': 'Satisfaction Rating',
              'value': {'path': '/rating'},
              'min': 0.0,
              'max': 5.0,
              'checks': [
                {
                  'message': 'Rating must be at least 3.',
                  'condition': {
                    'call': 'numeric',
                    'args': {
                      'value': {'path': '/rating'},
                      'min': 3.0,
                    },
                  },
                },
              ],
            },
          ),
          component(
            id: 'planPicker',
            type: 'ChoicePicker',
            properties: {
              'label': 'Select Plan',
              'variant': 'mutuallyExclusive',
              'options': [
                {'label': 'Free', 'value': 'free'},
                {'label': 'Pro', 'value': 'pro'},
              ],
              'value': {'path': '/plan'},
              'checks': [
                {
                  'message': 'A plan must be selected.',
                  'condition': {
                    'call': 'required',
                    'args': {
                      'value': {'path': '/plan'},
                    },
                  },
                },
              ],
            },
          ),
          component(
            id: 'submitButton',
            type: 'Button',
            properties: {
              'child': 'submitText',
              'checks': [
                {
                  'message': 'All form requirements must be satisfied.',
                  'condition': {
                    'call': 'and',
                    'args': {
                      'values': [
                        {
                          'call': 'required',
                          'args': {
                            'value': {'path': '/email'},
                          },
                        },
                        {'path': '/termsAccepted'},
                        {
                          'call': 'numeric',
                          'args': {
                            'value': {'path': '/rating'},
                            'min': 3.0,
                          },
                        },
                        {
                          'call': 'required',
                          'args': {
                            'value': {'path': '/plan'},
                          },
                        },
                      ],
                    },
                  },
                },
              ],
              'action': {
                'event': {'name': 'submitForm'},
              },
            },
          ),
          component(
            id: 'submitText',
            type: 'Text',
            properties: {'text': 'Submit Registration'},
          ),
        ];

        surfaceController.handleMessage(
          updateComponents(surfaceId: surfaceId, components: components),
        );
        surfaceController.handleMessage(
          createSurface(surfaceId: surfaceId, catalogId: basicCatalogId),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Surface(
                  surfaceContext: surfaceController.contextFor(surfaceId),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial State: All 4 components fail validation and display
        // their respective authored messages.
        expect(find.text('Email is required.'), findsOneWidget);
        expect(find.text('You must accept the terms.'), findsOneWidget);
        expect(find.text('Rating must be at least 3.'), findsOneWidget);
        expect(find.text('A plan must be selected.'), findsOneWidget);

        // Submit button is disabled because its `and` checks fail.
        final ElevatedButton submitButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Submit Registration'),
        );
        expect(
          submitButton.onPressed,
          isNull,
          reason: 'Button must be disabled when validation checks fail',
        );

        // 2. Fix Email
        surfaceController.handleMessage(
          updateDataModel(
            surfaceId: surfaceId,
            path: DataPath('/email'),
            value: 'user@example.com',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Email is required.'), findsNothing);
        // Button still disabled
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Submit Registration'),
              )
              .onPressed,
          isNull,
        );

        // 3. Fix Terms CheckBox
        surfaceController.handleMessage(
          updateDataModel(
            surfaceId: surfaceId,
            path: DataPath('/termsAccepted'),
            value: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('You must accept the terms.'), findsNothing);

        // 4. Fix Rating Slider
        surfaceController.handleMessage(
          updateDataModel(
            surfaceId: surfaceId,
            path: DataPath('/rating'),
            value: 4.0,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Rating must be at least 3.'), findsNothing);

        // 5. Fix Plan ChoicePicker
        surfaceController.handleMessage(
          updateDataModel(
            surfaceId: surfaceId,
            path: DataPath('/plan'),
            value: 'pro',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('A plan must be selected.'), findsNothing);

        // 6. Now that all checks pass, the Submit button becomes enabled!
        final ElevatedButton enabledButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Submit Registration'),
        );
        expect(
          enabledButton.onPressed,
          isNotNull,
          reason: 'Button must be enabled when all validation checks pass',
        );
      },
    );
  });
}
