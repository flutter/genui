// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ai_client/ai_client.dart';
import 'package:fcp_client/fcp_client.dart';
import 'package:logging/logging.dart';

/// An AI tool for retrieving the widget catalog.
class GetWidgetCatalogTool {
  /// Creates a new instance of the [GetWidgetCatalogTool].
  ///
  /// The [catalog] is the widget catalog to be returned by the tool.
  GetWidgetCatalogTool(this.catalog);

  /// The widget catalog to be returned by the tool.
  final WidgetCatalog catalog;
  final _log = Logger('GetWidgetCatalogTool');

  /// The AI tool for getting the widget catalog.
  AiTool<Map<String, Object?>> get get => DynamicAiTool(
    name: 'get_widget_catalog',
    description:
        'Returns the complete WidgetCatalog for the client '
        'application. This allows the LLM to know which widgets, '
        'properties, and data types are available for it to use when '
        'constructing a UI.',
    invokeFunction: (args) async {
      _log.info('Invoking "get_widget_catalog".');
      _log.info('Catalog: ${catalog.toJson()}');
      return catalog.toJson();
    },
  );
}
