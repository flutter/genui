// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';
import 'package:fcp_tools/fcp_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GetWidgetCatalogTool', () {
    test('get returns the correct catalog', () async {
      final catalog = WidgetCatalog(items: {}, dataTypes: {});
      final tool = GetWidgetCatalogTool(catalog);
      final result = await tool.get.invoke({});
      expect(result, catalog.toJson());
    });
  });
}
