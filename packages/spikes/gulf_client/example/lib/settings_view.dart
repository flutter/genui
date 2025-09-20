// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'agent_state.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final agentState = context.watch<AgentState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: agentState.urlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter agent URL',
                labelText: 'Agent URL',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: agentState.fetchCard,
              child: const Text('Fetch Agent Card'),
            ),
            if (agentState.agentCard != null)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name: ${agentState.agentCard!.name}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Description: ${agentState.agentCard!.description}'),
                      Text('Version: ${agentState.agentCard!.version}'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
