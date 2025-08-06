// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class LoadingScrim extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingScrim({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.12),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
