// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Test-only builders for `a2ui_core` messages and component wire JSON.
//
// `package:genui` consumes the core message types directly; these helpers keep
// test setup terse and mirror the named-argument shape the tests already use.

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:genui/src/model/data_path.dart';
import 'package:genui/src/primitives/simple_items.dart';

/// Builds a component's wire JSON: `{'id': ..., 'component': ..., ...props}`.
JsonMap component({
  required String id,
  required String type,
  JsonMap properties = const {},
}) => {'id': id, 'component': type, ...properties};

core.CreateSurfaceMessage createSurface({
  String version = 'v1.0',
  required String surfaceId,
  required String catalogId,
  JsonMap? surfaceProperties,
  bool sendDataModel = false,
  List<JsonMap>? components,
  JsonMap? dataModel,
}) => core.CreateSurfaceMessage(
  version: version,
  surfaceId: surfaceId,
  catalogId: catalogId,
  surfaceProperties: surfaceProperties,
  sendDataModel: sendDataModel,
  components: components,
  dataModel: dataModel,
);

core.UpdateComponentsMessage updateComponents({
  String version = 'v1.0',
  required String surfaceId,
  required List<JsonMap> components,
}) => core.UpdateComponentsMessage(
  version: version,
  surfaceId: surfaceId,
  components: components,
);

core.UpdateDataModelMessage updateDataModel({
  String version = 'v1.0',
  required String surfaceId,
  DataPath path = DataPath.root,
  Object? value,
}) => core.UpdateDataModelMessage(
  version: version,
  surfaceId: surfaceId,
  path: path.toString(),
  value: value,
);

core.DeleteSurfaceMessage deleteSurface({
  String version = 'v1.0',
  required String surfaceId,
}) => core.DeleteSurfaceMessage(version: version, surfaceId: surfaceId);
