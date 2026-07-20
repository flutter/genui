// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart' as core;

/// An interface for a message sink that accepts [core.A2uiMessage]s.
abstract interface class A2uiMessageSink {
  /// Handles a message from the client.
  void handleMessage(core.A2uiMessage message);
}
