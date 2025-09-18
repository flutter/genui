// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';

class FcpElevatedButton extends StatelessWidget {
  const FcpElevatedButton({
    super.key,
    required this.node,
    required this.properties,
    this.child,
  });

  final LayoutNode node;
  final Map<String, Object?> properties;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final onEvent = FcpProvider.of(context)?.onEvent;
    return ElevatedButton(
      onPressed: () {
        onEvent?.call(
          EventPayload(sourceNodeId: node.id, eventName: 'onPressed'),
        );
      },
      child: child,
    );
  }
}
