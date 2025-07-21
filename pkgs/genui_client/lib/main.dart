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
  final firebaseApp = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(GenUIApp(
    firebaseApp: firebaseApp,
  ));
}

class GenUIApp extends StatelessWidget {
  const GenUIApp({
    super.key,
    required this.firebaseApp,
  });

  final FirebaseApp firebaseApp;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic UI Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: GenUIHomePage(
        firebaseApp: firebaseApp,
      ),
    );
  }
}

ServerConnection createIsolateServerConnection({
  required FirebaseApp firebaseApp,
  required SetUiCallback onSetUi,
  required UpdateUiCallback onUpdateUi,
  required ErrorCallback onError,
  required StatusUpdateCallback onStatusUpdate,
  ServerSpawner? serverSpawnerOverride,
}) {
  return IsolateServerConnection(
    firebaseApp: firebaseApp,
    onSetUi: onSetUi,
    onUpdateUi: onUpdateUi,
    onError: onError,
    onStatusUpdate: onStatusUpdate,
    serverSpawnerOverride: serverSpawnerOverride,
  );
}

class GenUIHomePage extends StatefulWidget {
  const GenUIHomePage({
    super.key,
    this.autoStartServer = true,
    required this.firebaseApp,
    this.serverSpawnerOverride,
    this.connectionFactory = createIsolateServerConnection,
  });

  final bool autoStartServer;
  final FirebaseApp firebaseApp;
  final ServerSpawner? serverSpawnerOverride;
  final ServerConnectionFactory connectionFactory;

  @override
  State<GenUIHomePage> createState() => _GenUIHomePageState();
}

class _GenUIHomePageState extends State<GenUIHomePage> {
  final _updateController = StreamController<Map<String, Object?>>.broadcast();
  Map<String, Object?>? _uiDefinition;
  String _connectionStatus = 'Initializing...';
  Key _uiKey = UniqueKey();
  final _promptController = TextEditingController();
  late final ServerConnection _serverConnection;

  @override
  void initState() {
    super.initState();
    _serverConnection = widget.connectionFactory(
      firebaseApp: widget.firebaseApp,
      serverSpawnerOverride: widget.serverSpawnerOverride,
      onSetUi: (definition) {
        if (!mounted) return;
        setState(() {
          _uiDefinition = definition;
          _uiKey = UniqueKey();
        });
      },
      onUpdateUi: (updates) {
        if (!mounted) return;
        for (final update in updates) {
          _updateController.add(update);
        }
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _connectionStatus = 'Error: $message';
          _uiDefinition = null;
        });
      },
      onStatusUpdate: (status) {
        if (!mounted) return;
        setState(() {
          _connectionStatus = status;
          if (status != 'Server started.') {
            _uiDefinition = null;
          }
        });
      },
    );

    if (widget.autoStartServer) {
      _serverConnection.start();
    }
  }

  @override
  void dispose() {
    _updateController.close();
    _serverConnection.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _handleUiEvent(Map<String, Object?> event) {
    _serverConnection.sendUiEvent(event);
  }

  void _sendPrompt() {
    final prompt = _promptController.text;
    _serverConnection.sendPrompt(prompt);
    if (prompt.isNotEmpty) {
      _promptController.clear();
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

@visibleForTesting
typedef SetUiCallback = void Function(Map<String, Object?> definition);
@visibleForTesting
typedef UpdateUiCallback = void Function(List<Map<String, Object?>> updates);
@visibleForTesting
typedef ErrorCallback = void Function(String message);
@visibleForTesting
typedef StatusUpdateCallback = void Function(String status);
@visibleForTesting
typedef ServerSpawner = Future<Isolate> Function(SendPort, FirebaseApp);

@visibleForTesting
abstract class ServerConnection {
  Future<void> start();
  void sendPrompt(String text);
  void sendUiEvent(Map<String, Object?> event);
  void dispose();
}

@visibleForTesting
class IsolateServerConnection implements ServerConnection {
  IsolateServerConnection({
    required this.firebaseApp,
    required this.onSetUi,
    required this.onUpdateUi,
    required this.onError,
    required this.onStatusUpdate,
    this.serverSpawnerOverride,
  });

  final FirebaseApp firebaseApp;
  final SetUiCallback onSetUi;
  final UpdateUiCallback onUpdateUi;
  final ErrorCallback onError;
  final StatusUpdateCallback onStatusUpdate;
  final ServerSpawner? serverSpawnerOverride;

  rpc.Peer? _rpcPeer;
  Isolate? _serverIsolate;
  Completer<void>? _serverStartedCompleter;

  Future<Isolate> _serverSpawner(
      SendPort sendPort, FirebaseApp firebaseApp) async {
    return await Isolate.spawn(
      serverIsolate,
      [sendPort, firebaseApp],
    );
  }

  @override
  Future<void> start() {
    _serverStartedCompleter = Completer<void>();
    unawaited(_startServer());
    return _serverStartedCompleter!.future;
  }

  Future<void> _startServer() async {
    onStatusUpdate('Starting server...');

    final receivePort = ReceivePort();
    _serverIsolate = await (serverSpawnerOverride ?? _serverSpawner)(
        receivePort.sendPort, firebaseApp);

    final channel = IsolateChannel<String>.connectReceive(receivePort);
    _rpcPeer = rpc.Peer(channel);

    _rpcPeer!.registerMethod('ui.set', (rpc.Parameters params) {
      final definition = params.value as Map<String, Object?>;
      onSetUi(definition);
    });

    _rpcPeer!.registerMethod('ui.update', (rpc.Parameters params) {
      final updates = params.asList.cast<Map<String, Object?>>();
      onUpdateUi(updates);
    });

    _rpcPeer!.registerMethod('ui.error', (rpc.Parameters params) {
      onError(params['message'].asString);
    });

    _rpcPeer!.registerMethod('logging.log', (rpc.Parameters params) {
      final severity = params['severity'].asString;
      final message = params['message'].asString;
      debugPrint('[$severity] $message');
    });

    unawaited(_rpcPeer!.listen());

    await _rpcPeer!.sendRequest('ping');

    onStatusUpdate('Server started.');
    _serverStartedCompleter?.complete();
  }

  @override
  void sendPrompt(String text) {
    if (text.isNotEmpty) {
      _rpcPeer?.sendNotification('prompt', {'text': text});
      onStatusUpdate('Generating UI...');
    }
  }

  @override
  void sendUiEvent(Map<String, Object?> event) {
    _rpcPeer?.sendNotification('ui.event', event);
    onStatusUpdate('Generating UI...');
  }

  @override
  void dispose() {
    _rpcPeer?.close();
    _serverIsolate?.kill();
  }
}

@visibleForTesting
typedef ServerConnectionFactory = ServerConnection Function({
  required FirebaseApp firebaseApp,
  required SetUiCallback onSetUi,
  required UpdateUiCallback onUpdateUi,
  required ErrorCallback onError,
  required StatusUpdateCallback onStatusUpdate,
  ServerSpawner? serverSpawnerOverride,
});
