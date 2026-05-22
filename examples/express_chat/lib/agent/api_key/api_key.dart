// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '_web_api_key.dart' if (dart.library.io) '_io_api_key.dart';

String apiKey() {
  return platformApiKey();
}
