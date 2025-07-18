import 'dart:async';

import 'package:flutter/material.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'src/dynamic_ui.dart';

void main() {
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
  const MyHomePage({super.key, this.connect});

  final void Function()? connect;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _updateController = StreamController<Map<String, Object?>>.broadcast();
  rpc.Peer? _rpcPeer;
  Map<String, Object?>? _uiDefinition;
  String _connectionStatus = 'Connecting...';
  Key _uiKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    (widget.connect ?? _connect)();
  }

  void _connect() {
    setState(() {
      _connectionStatus = 'Connecting...';
      _uiDefinition = null;
    });

    try {
      final socket =
          WebSocketChannel.connect(Uri.parse('ws://localhost:8765/ws'));
      // A Peer establishes a bidirectional connection.
      _rpcPeer = rpc.Peer(socket.cast<String>());

      // Register methods that the server can call on this client.
      _rpcPeer!.registerMethod('ui.set', (rpc.Parameters params) {
        if (!mounted) return;
        debugPrint('Setting UI to ${params.value}');
        setState(() {
          final definition = params.value as Map<String, Object?>;
          _uiDefinition = definition;
          // Changing the key forces the DynamicUi widget to be replaced
          // and its state to be completely rebuilt from the new definition.
          _uiKey = UniqueKey();
        });
      });

      _rpcPeer!.registerMethod('ui.update', (rpc.Parameters params) {
        if (!mounted) return;
        debugPrint('Updating UI to ${params.value}');
        final updates = params.asList;
        for (final update in updates) {
          _updateController.add(update as Map<String, Object?>);
        }
      });

      // Start listening for incoming messages from the server.
      _rpcPeer!.listen().catchError((Object error) {
        if (error is rpc.RpcException) {
          print('RPC Error: ${error.message} (code ${error.code})');
        } else {
          print('Connection Error: $error');
        }
        if (mounted) {
          setState(() => _connectionStatus = 'Connection Error');
        }
      });

      _rpcPeer!.done.then((_) {
        print('WebSocket connection closed.');
        if (mounted) {
          setState(() {
            _connectionStatus = 'Disconnected. Retrying...';
          });
          // Attempt to reconnect after a delay.
          Future.delayed(const Duration(seconds: 3), _reconnect);
        }
      });
    } catch (e) {
      print('Failed to connect: $e');
      setState(() {
        _connectionStatus = 'Failed to connect. Retrying...';
      });
      Future.delayed(const Duration(seconds: 3), _reconnect);
    }
  }

  void _reconnect() {
    _rpcPeer?.close();
    _rpcPeer = null;
    _connect();
  }

  @override
  void dispose() {
    _updateController.close();
    _rpcPeer?.close();
    super.dispose();
  }

  /// Sends a UI event to the server as a JSON-RPC notification.
  void _handleUiEvent(Map<String, Object?> event) {
    print('Sending UI Event: $event');
    // We send a notification because we don't expect a direct response.
    _rpcPeer?.sendNotification('ui.event', event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Dynamic UI Demo'),
      ),
      body: _uiDefinition == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_connectionStatus),
                ],
              ),
            )
          : ConstrainedBox(
            constraints: const BoxConstraints(maxWidth:1000),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DynamicUi(
                  key: _uiKey,
                  definition: _uiDefinition!,
                  updateStream: _updateController.stream,
                  onEvent: _handleUiEvent,
                ),
              ),
            ),
    );
  }
}
