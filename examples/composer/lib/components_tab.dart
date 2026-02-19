// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

/// The Components tab shows every component in the standard catalog using
/// the built-in [DebugCatalogView].
class ComponentsTab extends StatelessWidget {
  const ComponentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Catalog catalog = BasicCatalogItems.asCatalog();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text('Components', style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: DebugCatalogView(
            catalog: catalog,
            onSubmit: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'User action: '
                    '${jsonEncode(message.parts.last)}',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
