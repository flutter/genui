// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class FcpContainer extends StatelessWidget {
  const FcpContainer({
    super.key,
    required this.properties,
    required this.children,
  });

  final Map<String, Object?> properties;
  final Map<String, List<Widget>> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (properties['width'] as num?)?.toDouble(),
      height: (properties['height'] as num?)?.toDouble(),
      color: properties['color'] as Color?,
      child: children['child']?.first,
    );
  }
}
