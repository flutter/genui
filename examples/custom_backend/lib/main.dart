// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'backend.dart';

void main() {
  runApp(const MyApp());
}

const _title = 'Custom Backend Demo';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const requestText = 'Show me options how you can help me, using radio buttons.';

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(_title),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: const _IntegrationTester(),
      ),
    );
  }
}

class _IntegrationTester extends StatefulWidget {
  const _IntegrationTester();

  @override
  State<_IntegrationTester> createState() => _IntegrationTesterState();
}

final Catalog _catalog = CoreCatalogItems.asCatalog();
const _toolName = 'uiGenerationTool';
final uiSchema = UiSchemaDefinition(
  prompt: genUiTechPrompt([_toolName]),
  tools: [
    catalogToFunctionDeclaration(
      _catalog,
      _toolName,
      'Generates Flutter UI based on user requests.',
    ),
  ],
);

class _IntegrationTesterState extends State<_IntegrationTester> {
  final _controller = TextEditingController(text: requestText);

  final _protocol = Backend(uiSchema);
  late final A2uiMessageProcessor _a2uiMessageProcessor = A2uiMessageProcessor(
    catalogs: [_catalog],
  );
  String? _selectedResponse;
  bool _isLoading = false;
  String? _errorMessage;
  String? _surfaceId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _controller),
        const SizedBox(height: 20.0),
        _ResponseSelector((selected) => _selectedResponse = selected),
        const SizedBox(height: 20.0),
        IconButton(
          onPressed: () async {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            try {
              print(
                'Sending request for _selectedResponse = '
                '$_selectedResponse ...',
              );
              final ParsedToolCall? parsedToolCall = await _protocol
                  .sendRequest(
                    _controller.text,
                    savedResponse: _selectedResponse,
                  );
              if (parsedToolCall == null) {
                print('No UI received.');
                setState(() {
                  _isLoading = false;
                });
                return;
              }
              _surfaceId = parsedToolCall.surfaceId;
              for (final A2uiMessage message in parsedToolCall.messages) {
                _a2uiMessageProcessor.handleMessage(message);
              }
              print('UI received for surfaceId=${parsedToolCall.surfaceId}');
              setState(() => _isLoading = false);
            } catch (e, callStack) {
              print('Error connecting to backend: $e\n$callStack');
              setState(() {
                _isLoading = false;
                _errorMessage = e.toString();
              });
            }
          },
          icon: const Icon(Icons.send),
        ),
        const SizedBox(height: 20.0),
        Card(
          elevation: 2.0,
          child: Container(
            height: 350,
            width: 350,
            alignment: Alignment.center,
            child: _buildGeneratedUi(),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedUi() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    if (_errorMessage != null) {
      return Text('$_errorMessage');
    }
    final String? surfaceId = _surfaceId;
    if (surfaceId == null) {
      return const Text('_surfaceId == null');
    }
    return GenUiSurface(
      surfaceId: surfaceId,
      host: _a2uiMessageProcessor,
      defaultBuilder: (_) => const Text('Fallback to defaultBuilder'),
    );
  }
}

class _ResponseSelector extends StatefulWidget {
  _ResponseSelector(this.onChanged);

  final ValueChanged<String?> onChanged;

  @override
  State<_ResponseSelector> createState() => _ResponseSelectorState();
}

class _ResponseSelectorState extends State<_ResponseSelector> {
  String? _selection;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String?>(
      value: _selection,

      onChanged: (String? newValue) => setState(() {
        _selection = newValue;
        widget.onChanged(newValue);
      }),

      items: savedResponseAssets.map((String? location) {
        return DropdownMenuItem<String?>(
          value: location,
          child: Text(location ?? 'Request Gemini'),
        );
      }).toList(),
    );
  }
}

const _numberOfSavedResponses = 3;
final Iterable<String?> savedResponseAssets = List.generate(
  _numberOfSavedResponses + 1,
  (index) => index == 0 ? null : 'assets/data/saved-response-$index.json',
);
