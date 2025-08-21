// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../model/catalog.dart';

abstract class SurfaceManagerInterface {
  void addOrUpdateSurface(String id, Map<String, dynamic> definition);
  void removeSurface(String id);

  Catalog get catalog;
}
