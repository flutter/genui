// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'entryPointChild': A2uiSchemas.componentReference(
      description: 'The widget that opens the modal.',
    ),
    'contentChild': A2uiSchemas.componentReference(
      description: 'The widget to display in the modal.',
    ),
  },
  required: ['entryPointChild', 'contentChild'],
);

extension type _ModalData.fromMap(JsonMap _json) {
  factory _ModalData({
    required String entryPointChild,
    required String contentChild,
  }) => _ModalData.fromMap({
    'entryPointChild': entryPointChild,
    'contentChild': contentChild,
  });

  String get entryPointChild => _json['entryPointChild'] as String;
  String get contentChild => _json['contentChild'] as String;
}

final modal = CatalogItem(
  name: 'Modal',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required dataContext,
      }) {
        final modalData = _ModalData.fromMap(data as JsonMap);
        return buildChild(modalData.entryPointChild);
      },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Modal": {
              "entryPointChild": "button",
              "contentChild": "text"
            }
          }
        },
        {
          "id": "button",
          "component": {
            "Button": {
              "child": "button_text",
              "action": {
                "name": "showModal",
                "context": [
                  {
                    "key": "modalId",
                    "value": {
                      "literalString": "modal"
                    }
                  }
                ]
              }
            }
          }
        },
        {
          "id": "button_text",
          "component": {
            "Text": {
              "text": {
                "literalString": "Open Modal"
              }
            }
          }
        },
        {
          "id": "text",
          "component": {
            "Text": {
              "text": {
                "literalString": "This is a modal."
              }
            }
          }
        }
      ]
    ''',
  ],
);
