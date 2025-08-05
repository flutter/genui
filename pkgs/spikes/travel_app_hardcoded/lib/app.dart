// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'sdk_stubs/agent/agent.dart';
import 'sdk_stubs/model/controller.dart';
import 'sdk_stubs/model/image_catalog.dart';
import 'sdk_stubs/model/input.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const _appTitle = 'GenUI Example';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const _MyHomePage(),
    );
  }
}

final _myImageCatalog = ImageCatalog();

class _MyHomePage extends StatefulWidget {
  const _MyHomePage();

  @override
  State<_MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage> {
  final _scrollController = ScrollController();

  late final GenUiAgent _agent = GenUiAgent(
    GenUiController(
      _scrollController,
      imageCatalog: _myImageCatalog,
      agentIconAsset: 'assets/agent_icon.png',
    ),
  )..run();

  @override
  void initState() {
    super.initState();

    _agent.controller.state.input.complete(
      InitialInput('Show invitations to create a vacation travel itinerary.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Row(
          children: <Widget>[
            Icon(Icons.chat_bubble_outline),
            SizedBox(width: 8.0), // Add spacing between icon and text
            Text('Chat'),
          ],
        ),
        actions: [const Icon(Icons.person_outline), const SizedBox(width: 8.0)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: GenUiWidget(_agent.controller),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _agent.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
