// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fcp_client/fcp_client.dart';

import 'src/fcp_registry.dart';

void main() {
  runApp(const JsonFcpViewerApp());
}

class JsonFcpViewerApp extends StatelessWidget {
  const JsonFcpViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCP JSON Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const FcpViewerHomePage(),
    );
  }
}

class FcpViewerHomePage extends StatefulWidget {
  const FcpViewerHomePage({super.key});

  @override
  State<FcpViewerHomePage> createState() => _FcpViewerHomePageState();
}

class _FcpViewerHomePageState extends State<FcpViewerHomePage> {
  final _stateUpdateController = TextEditingController();
  final _layoutUpdateController = TextEditingController();
  final _fcpViewController = FcpViewController();

  late final DynamicUIPacket _initialPacket;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialPacket = DynamicUIPacket(
      formatVersion: '0.1.0',
      layout: Layout(
        root: 'root',
        nodes: [LayoutNode(id: 'root', type: 'Column')],
      ),
      state: {},
    );
  }

  @override
  void dispose() {
    _stateUpdateController.dispose();
    _layoutUpdateController.dispose();
    _fcpViewController.dispose();
    super.dispose();
  }

  void _applyStateUpdate() {
    setState(() => _error = null);
    try {
      final jsonText = _stateUpdateController.text;
      if (jsonText.isEmpty) {
        setState(() => _error = 'State replace JSON cannot be empty.');
        return;
      }
      final jsonMap = json.decode(jsonText) as Map<String, Object?>;
      final replace = StateUpdate.fromMap(jsonMap);
      _fcpViewController.patchState(replace);
    } catch (e) {
      setState(() => _error = 'Error parsing state replace JSON: $e');
    }
  }

  void _applyLayoutUpdate() {
    setState(() => _error = null);
    try {
      final jsonText = _layoutUpdateController.text;
      if (jsonText.isEmpty) {
        setState(() => _error = 'Layout replace JSON cannot be empty.');
        return;
      }
      final jsonMap = json.decode(jsonText) as Map<String, Object?>;
      final replace = LayoutUpdate.fromMap(jsonMap);
      _fcpViewController.patchLayout(replace);
    } catch (e) {
      setState(() => _error = 'Error parsing layout replace JSON: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final registry = createRegistry();
    return Scaffold(
      appBar: AppBar(title: const Text('FCP JSON Viewer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _stateUpdateController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Paste StateUpdate JSON here',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _applyStateUpdate,
              child: const Text('Apply State Update'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _layoutUpdateController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Paste LayoutUpdate JSON here',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _applyLayoutUpdate,
              child: const Text('Apply Layout Update'),
            ),
            const SizedBox(height: 16.0),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            Expanded(
              child: FcpView(
                packet: _initialPacket,
                catalog: registry.buildCatalog(),
                registry: registry,
                controller: _fcpViewController,
                onEvent: (payload) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Event: ${payload.eventName} from ${payload.sourceNodeId}',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
