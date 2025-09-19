// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:gulf_client/gulf_client.dart';

import 'agent_connection_view.dart';
import 'manual_input_view.dart';

void main() {
  initGulfLogger();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('GULF Client Example'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Agent Connection'),
                Tab(text: 'Manual Input'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [AgentConnectionView(), ManualInputView()],
          ),
        ),
      ),
    );
  }
}
