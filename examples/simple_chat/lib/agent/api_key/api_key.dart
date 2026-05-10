// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'io_api_key.dart' if (dart.library.html) 'web_api_key.dart';

String apiKey() {
  return platformApiKey();
}
