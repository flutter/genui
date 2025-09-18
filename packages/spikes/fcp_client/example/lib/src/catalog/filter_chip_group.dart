// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';

class FilterChipGroup extends StatelessWidget {
  const FilterChipGroup({
    super.key,
    required this.submitLabel,
    required this.children,
  });

  final String submitLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(runSpacing: 16.0, spacing: 8.0, children: children),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => FcpProvider.of(context)?.onEvent?.call(
                EventPayload(
                  sourceNodeId: 'filter_chip_group',
                  eventName: 'submit',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}
