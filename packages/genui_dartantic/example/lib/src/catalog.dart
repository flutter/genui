// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'tic_tac_toe_board.dart';

final Catalog ticTacToeCatalog = Catalog([
  CatalogItem(
    name: 'TicTacToeBoard',
    dataSchema: S.object(
      properties: {
        'cells': S.list(
          description:
              'A list of 9 strings representing the board. Use "X" for user, "O" for AI, and empty string for free cells.',
          items: S.string(),
          minItems: 9,
          maxItems: 9,
        ),
      },
      required: ['cells'],
    ),
    widgetBuilder: (context) {
      final data = context.data as JsonMap;
      final cells = (data['cells'] as List).cast<String>();
      return TicTacToeBoard(
        cells: cells,
        onCellTap: (index) {
          context.dispatchEvent(
            UserActionEvent(
              name: 'cellTap',
              sourceComponentId: 'TicTacToeBoard',
              context: {'cellIndex': index},
            ),
          );
        },
      );
    },
    exampleData: [],
  ),
], catalogId: 'a2ui.org:standard_catalog_0_8_0');
