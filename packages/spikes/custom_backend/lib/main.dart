import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'protocol.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  final _controller = TextEditingController(
    text: 'Show me options how you can help me, using radio buttons.',
  );
  final _protocol = Protocol();
  late final GenUiManager _genUi = GenUiManager(catalog: _protocol.catalog);
  bool _isLoading = false;
  String? _surfaceId;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(_title),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _controller),
            const SizedBox(height: 20.0),
            IconButton(
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  // ignore: omit_local_variable_types
                  final SurfaceUpdate? ui = await _protocol.sendRequest(
                    _controller.text,
                  );
                  if (ui == null) {
                    _surfaceId = null;
                    setState(() {
                      _isLoading = false;
                      _errorMessage = null;
                    });
                    return;
                  }
                  _genUi.handleMessage(ui);
                  _surfaceId = ui.surfaceId;
                  setState(() => _isLoading = false);
                } catch (e, callStack) {
                  _surfaceId = null;
                  print('!!! Error: $e\n$callStack');
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
        ),
      ),
    );
  }

  Widget _buildGeneratedUi() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    if (_errorMessage != null) {
      return Text('$_errorMessage');
    }
    if (_surfaceId == null) {
      return const Text('No UI 🤷‍♀️');
    }
    return GenUiSurface(surfaceId: _surfaceId!, host: _genUi);
  }
}
