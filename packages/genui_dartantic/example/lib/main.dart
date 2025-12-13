// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'src/provider_selection_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen(
    (record) => debugPrint(
      '[${record.level.name}] ${record.loggerName}: ${record.message}',
    ),
  );

  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GenUI Tic Tac Toe',
    debugShowCheckedModeBanner: false,
    home: const ProviderSelectionPage(),
  );
}
