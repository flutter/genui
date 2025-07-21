import 'dart:async';
import 'dart:isolate';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/isolate_channel.dart';

import 'firebase_options.dart';
import 'src/dynamic_ui.dart';
import 'src/ui_server.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic UI Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.autoStartServer = true});

  final bool autoStartServer;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _updateController = StreamController<Map<String, Object?>>.broadcast();
  rpc.Peer? _rpcPeer;
  Map<String, Object?>? _uiDefinition;
  String _connectionStatus = 'Initializing...';
  Key _uiKey = UniqueKey();
  Isolate? _serverIsolate;
  final _promptController = TextEditingController();
  Completer<void>? serverStartedCompleter;

  Future<Isolate> Function(SendPort)? serverSpawnerOverride;

  Future<Isolate> _serverSpawner(SendPort sendPort) async {
    return await Isolate.spawn(
      serverIsolate,
      sendPort,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.autoStartServer) {
      startServer();
    }
  }

  Future<void> startServer() async {
    serverStartedCompleter = Completer<void>();
    unawaited(_startServer());
    return serverStartedCompleter!.future;
  }

  Future<void> _startServer() async {
    setState(() {
      _connectionStatus = 'Starting server...';
      _uiDefinition = null;
    });

    final receivePort = ReceivePort();
    _serverIsolate =
        await (serverSpawnerOverride ?? _serverSpawner)(receivePort.sendPort);

    final channel = IsolateChannel<String>.connectReceive(receivePort);
    _rpcPeer = rpc.Peer(channel);

    _rpcPeer!.registerMethod('ui.set', (rpc.Parameters params) {
      if (!mounted) {
        return;
      }
      setState(() {
        final definition = params.value as Map<String, Object?>;
        _uiDefinition = definition;
        _uiKey = UniqueKey();
      });
    });

    _rpcPeer!.registerMethod('ui.update', (rpc.Parameters params) {
      if (!mounted) {
        return;
      }
      final updates = params.asList;
      for (final update in updates) {
        _updateController.add(update as Map<String, Object?>);
      }
    });

    _rpcPeer!.registerMethod('ui.error', (rpc.Parameters params) {
      if (!mounted) {
        return;
      }
      setState(() {
        _connectionStatus = 'Error: ${params['message'].asString}';
        _uiDefinition = null;
      });
    });

    unawaited(_rpcPeer!.listen());

    await _rpcPeer!.sendRequest('ping');

    setState(() {
      _connectionStatus = 'Server started.';
      serverStartedCompleter?.complete();
    });
  }

  @override
  void dispose() {
    _updateController.close();
    _rpcPeer?.close();
    _serverIsolate?.kill();
    _promptController.dispose();
    super.dispose();
  }

  void _handleUiEvent(Map<String, Object?> event) {
    _rpcPeer?.sendNotification('ui.event', event);
    setState(() {
      _uiDefinition = null;
      _connectionStatus = 'Generating UI...';
    });
  }

  void _sendPrompt() {
    final prompt = _promptController.text;
    if (prompt.isNotEmpty) {
      _rpcPeer?.sendNotification('prompt', {'text': prompt});
      _promptController.clear();
      setState(() {
        _uiDefinition = null;
        _connectionStatus = 'Generating UI...';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Dynamic UI Demo'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        decoration: const InputDecoration(
                          hintText: 'Enter a UI prompt',
                        ),
                        onSubmitted: (_) => _sendPrompt(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendPrompt,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _uiDefinition == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_connectionStatus == 'Generating UI...')
                              const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(_connectionStatus),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DynamicUi(
                          key: _uiKey,
                          definition: _uiDefinition!,
                          updateStream: _updateController.stream,
                          onEvent: _handleUiEvent,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}