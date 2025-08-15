// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';

class MockFcpViewController implements FcpViewController {
  LayoutUpdate? lastLayoutUpdate;
  StateUpdate? lastStateUpdate;
  int patchLayoutCallCount = 0;
  int patchStateCallCount = 0;

  @override
  void patchLayout(LayoutUpdate update) {
    patchLayoutCallCount++;
    lastLayoutUpdate = update;
  }

  @override
  void patchState(StateUpdate update) {
    patchStateCallCount++;
    lastStateUpdate = update;
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #onLayoutUpdate) {
      return const Stream<LayoutUpdate>.empty();
    }
    if (invocation.memberName == #onStateUpdate) {
      return const Stream<StateUpdate>.empty();
    }
    super.noSuchMethod(invocation);
  }
}
